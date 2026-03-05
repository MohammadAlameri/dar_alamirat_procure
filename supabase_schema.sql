-- 1. Create Profiles Table (Extensions for auth.users)
CREATE TABLE profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  email text,
  job_title text,
  department text,
  role text DEFAULT 'employee' CHECK (role IN ('employee', 'manager', 'it_procurement', 'finance', 'admin')),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 2. Create Purchase Requests Table
CREATE TABLE purchase_requests (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  subject text NOT NULL,
  justification text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'manager_approved', 'it_approved', 'finance_approved', 'purchased', 'received_by_staff', 'rejected_by_staff', 'completed', 'rejected_by_manager', 'rejected_by_it', 'rejected_by_finance', 'rejected_by_it_purchase', 'rejected')),
  
  -- Financial Fields (managed by Finance/Accountant)
  budget_status boolean,
  budget_line_item text,
  commitment_number text,
  total_amount decimal(12, 2) DEFAULT 0,
  amount_in_words text,
  
  -- Audit Fields
  created_by uuid REFERENCES profiles(id),
  updated_by uuid REFERENCES profiles(id),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  is_deleted boolean DEFAULT false
);

-- 3. Create Request Items Table
CREATE TABLE request_items (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  request_id uuid REFERENCES purchase_requests(id) ON DELETE CASCADE,
  product_name text NOT NULL,
  specifications text,
  unit text,
  quantity integer NOT NULL,
  unit_price decimal(12, 2),
  total_price decimal(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  country_of_origin text,
  warranty_period text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 4. Create Approvals Log Table
CREATE TABLE approvals_log (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  request_id uuid REFERENCES purchase_requests(id),
  user_id uuid REFERENCES profiles(id),
  action text,
  comments text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 5. Automate updated_at update
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_profiles BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER set_updated_at_requests BEFORE UPDATE ON purchase_requests FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

-- 6. SPECIAL SECURITY TRIGGER: Prevent Accountant from changing Staff's description
CREATE OR REPLACE FUNCTION protect_staff_description()
RETURNS TRIGGER AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role INTO user_role FROM profiles WHERE id = auth.uid();
    
    -- If user is Finance/Accountant, they cannot change subject or justification
    IF user_role = 'finance' THEN
        IF (NEW.subject <> OLD.subject OR NEW.justification <> OLD.justification) THEN
            RAISE EXCEPTION 'Accountants are not allowed to modify the staff original request description or justification.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_description_protection
BEFORE UPDATE ON purchase_requests
FOR EACH ROW
EXECUTE FUNCTION protect_staff_description();

-- 7. Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE approvals_log ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies for Purchase Requests

-- View Policy: Staff sees own, others see all relevant to their role
CREATE POLICY "Users can view relevant requests" 
ON purchase_requests FOR SELECT 
USING (
  auth.uid() = created_by OR 
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'it_procurement', 'finance', 'admin'))
);

-- Insert Policy: Staff can create
CREATE POLICY "Staff can create requests" 
ON purchase_requests FOR INSERT 
WITH CHECK (auth.uid() = created_by);

-- 1. Staff can update if not completed (to edit)
-- 2. Other roles can update based on their review stage
CREATE POLICY "Authorized roles can update requests" 
ON purchase_requests FOR UPDATE 
USING (
  (auth.uid() = created_by AND status != 'completed') OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'it_procurement', 'finance', 'admin'))
);

-- 9. RLS Policies for Items
CREATE POLICY "Users can view items of accessible requests" 
ON request_items FOR SELECT 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id)
);

CREATE POLICY "Staff can manage items for own requests" 
ON request_items FOR ALL 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id AND pr.created_by = auth.uid() AND pr.status != 'completed')
);

-- 10. Profile Policies
-- Users can view their own profile always
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);

-- Admins can view and manage all profiles
CREATE POLICY "Admins can manage all profiles" 
ON profiles FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'admin'
  )
);

-- Allow other roles to view staff names for the request details
CREATE POLICY "Everyone can view profiles" ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Allow new signups to insert their own profile
-- 11. Approvals Log Policies
CREATE POLICY "Users can view all logs" ON approvals_log FOR SELECT USING (true);
CREATE POLICY "Users can insert logs for reachable requests" ON approvals_log FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);

CREATE POLICY "Staff can delete logs for own requests" 
ON approvals_log FOR DELETE 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id AND pr.created_by = auth.uid())
);

-- 12. New columns for print template support
ALTER TABLE purchase_requests ADD COLUMN IF NOT EXISTS requested_by_name text;
ALTER TABLE purchase_requests ADD COLUMN IF NOT EXISTS requested_by_title text;
ALTER TABLE purchase_requests ADD COLUMN IF NOT EXISTS suggested_suppliers text;
ALTER TABLE request_items ADD COLUMN IF NOT EXISTS brand_model text;
