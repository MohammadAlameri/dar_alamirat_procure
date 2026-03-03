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
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'it_approved', 'finance_approved', 'rejected', 'completed')),
  
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

-- Update Policy: 
-- 1. Staff can update if still pending
-- 2. Finance can update financial status
-- 3. IT can update status
CREATE POLICY "Authorized roles can update requests" 
ON purchase_requests FOR UPDATE 
USING (
  (auth.uid() = created_by AND status = 'pending') OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('it_procurement', 'finance', 'admin'))
);

-- 9. RLS Policies for Items
CREATE POLICY "Users can view items of accessible requests" 
ON request_items FOR SELECT 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id)
);

CREATE POLICY "Staff can manage items for pending requests" 
ON request_items FOR ALL 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id AND pr.created_by = auth.uid() AND pr.status = 'pending')
);

-- 10. Profile Policies
-- Users can view all profiles except admins (unless they are admin)
-- Actually, let's allow users to see their own, and admins to see non-admins.
CREATE POLICY "Users can view relevant profiles" ON profiles FOR SELECT USING (
  auth.uid() = id OR 
  ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin' AND role != 'admin')
);

CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Admins can update/delete non-admin profiles
CREATE POLICY "Admins can manage non-admin profiles" 
ON profiles FOR ALL 
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin' AND role != 'admin'
);

-- Allow new signups to insert their own profile
-- 11. Approvals Log Policies
CREATE POLICY "Users can view all logs" ON approvals_log FOR SELECT USING (true);
CREATE POLICY "Authorized roles can insert logs" ON approvals_log FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'it_procurement', 'finance', 'admin'))
);
