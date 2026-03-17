-- ============================================================
-- MIGRATION: Multi-Branch Support for Dar Alamirat Procurement
-- ============================================================

-- 1. Branches Table
CREATE TABLE branches (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  name_ar text,
  code text UNIQUE,           -- e.g. 'HQ', 'BR1', 'BR2'
  address text,
  phone text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. User-Branch Access (many-to-many with access level)
CREATE TABLE user_branches (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE NOT NULL,
  access_level text DEFAULT 'view' CHECK (access_level IN ('full', 'view')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, branch_id)
);

-- 3. Add branch_id to purchase_requests
ALTER TABLE purchase_requests ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id);

-- 4. Add branch_id to expense_requests
ALTER TABLE expense_requests ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id);

-- 5. Add manager_id to profiles (if not already present)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES profiles(id);

-- 6. Update role CHECK to include new roles
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('employee', 'manager', 'it_procurement', 'finance', 'accountant', 'general_manager', 'admin'));

-- 7. Audit Log Table (comprehensive change tracking)
CREATE TABLE audit_log (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_data jsonb,
  new_data jsonb,
  changed_by uuid REFERENCES profiles(id),
  branch_id uuid REFERENCES branches(id),
  created_at timestamptz DEFAULT now()
);

-- 8. Enable RLS on new tables
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies for branches
CREATE POLICY "Everyone can view branches" ON branches FOR SELECT USING (true);
CREATE POLICY "Only admins can manage branches" ON branches FOR ALL 
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 10. RLS Policies for user_branches
CREATE POLICY "Users can view own branch assignments" ON user_branches FOR SELECT 
  USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can manage branch assignments" ON user_branches FOR ALL 
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 11. RLS Policies for audit_log
CREATE POLICY "Admins can view audit log" ON audit_log FOR SELECT 
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'finance', 'general_manager')));
CREATE POLICY "System can insert audit log" ON audit_log FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 12. Trigger for updated_at on branches
CREATE TRIGGER set_updated_at_branches BEFORE UPDATE ON branches FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

-- 13. Audit trigger function
CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, record_id, action, new_data, changed_by, branch_id)
    VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), auth.uid(), NEW.branch_id);
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by, branch_id)
    VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid(), NEW.branch_id);
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, changed_by)
    VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Attach audit triggers
CREATE TRIGGER audit_purchase_requests 
  AFTER INSERT OR UPDATE OR DELETE ON purchase_requests 
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER audit_expense_requests 
  AFTER INSERT OR UPDATE OR DELETE ON expense_requests 
  FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

-- 15. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_purchase_requests_branch ON purchase_requests(branch_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_status ON purchase_requests(status);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_created_by ON purchase_requests(created_by);
CREATE INDEX IF NOT EXISTS idx_expense_requests_branch ON expense_requests(branch_id);
CREATE INDEX IF NOT EXISTS idx_user_branches_user ON user_branches(user_id);
CREATE INDEX IF NOT EXISTS idx_user_branches_branch ON user_branches(branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- 16. Insert a default branch (HQ)
INSERT INTO branches (name, name_ar, code) VALUES ('Headquarters', 'المقر الرئيسي', 'HQ');
