-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

-- TABLES --
CREATE TABLE public.approvals_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id uuid,
  user_id uuid,
  action text,
  comments text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT approvals_log_pkey PRIMARY KEY (id),
  CONSTRAINT approvals_log_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.purchase_requests(id),
  CONSTRAINT approvals_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.audit_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action text NOT NULL CHECK (action = ANY (ARRAY['INSERT'::text, 'UPDATE'::text, 'DELETE'::text])),
  old_data jsonb,
  new_data jsonb,
  changed_by uuid,
  branch_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT audit_log_pkey PRIMARY KEY (id),
  CONSTRAINT audit_log_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.profiles(id),
  CONSTRAINT audit_log_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id)
);
CREATE TABLE public.branches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_ar text,
  code text UNIQUE,
  address text,
  phone text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT branches_pkey PRIMARY KEY (id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.configurations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  android_version text,
  ios_version text,
  android_store_url text,
  ios_store_url text,
  force_update boolean NOT NULL DEFAULT false,
  maintenance_mode boolean NOT NULL DEFAULT false,
  maintenance_message_ar text,
  maintenance_message_en text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT configurations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.expense_approvals_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id uuid,
  user_id uuid,
  action text,
  comments text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT expense_approvals_log_pkey PRIMARY KEY (id),
  CONSTRAINT expense_approvals_log_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.expense_requests(id),
  CONSTRAINT expense_approvals_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.expense_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subject text NOT NULL,
  amount numeric NOT NULL,
  highest_approval_level text NOT NULL CHECK (highest_approval_level = ANY (ARRAY['manager'::text, 'finance'::text, 'general_manager'::text])),
  statement text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'manager_approved'::text, 'finance_approved'::text, 'gm_approved'::text, 'paid'::text, 'completed'::text, 'rejected_by_manager'::text, 'rejected_by_finance'::text, 'rejected_by_gm'::text])),
  employee_id uuid,
  employee_name text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  branch_id uuid,
  CONSTRAINT expense_requests_pkey PRIMARY KEY (id),
  CONSTRAINT expense_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.profiles(id),
  CONSTRAINT expense_requests_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  category_id uuid,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  product_details text,
  CONSTRAINT products_pkey PRIMARY KEY (id),
  CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name_en text,
  full_name_ar text,
  date_of_birth date,
  gender text,
  phone_number text,
  nationality text,
  current_address text,
  marital_status text,
  qualification text,
  id_number text,
  id_expiry_date date,
  passport_number text,
  passport_expiry_date date,
  work_permit_number text,
  work_permit_date date,
  sponsorship_number text,
  sponsorship_expiry_date date,
  job_title text,
  department text,
  role text DEFAULT 'employee'::text CHECK (role = ANY (ARRAY['employee'::text, 'manager'::text, 'it_procurement'::text, 'finance'::text, 'accountant'::text, 'general_manager'::text, 'admin'::text])),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  email text,
  manager_id uuid,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.purchase_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subject text NOT NULL,
  justification text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'manager_approved'::text, 'it_approved'::text, 'finance_approved'::text, 'purchased'::text, 'received_by_staff'::text, 'rejected_by_staff'::text, 'completed'::text, 'rejected_by_manager'::text, 'rejected_by_it'::text, 'rejected_by_finance'::text, 'rejected_by_it_purchase'::text, 'rejected'::text])),
  budget_status boolean,
  budget_line_item text,
  commitment_number text,
  total_amount numeric DEFAULT 0,
  amount_in_words text,
  created_by uuid,
  updated_by uuid,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  is_deleted boolean DEFAULT false,
  requested_by_name text,
  requested_by_title text,
  suggested_suppliers text,
  staff_acceptance_status text,
  staff_rejection_reason text,
  staff_receiving_date timestamp with time zone,
  branch_id uuid,
  CONSTRAINT purchase_requests_pkey PRIMARY KEY (id),
  CONSTRAINT purchase_requests_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id),
  CONSTRAINT purchase_requests_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id),
  CONSTRAINT purchase_requests_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id)
);
CREATE TABLE public.request_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id uuid,
  product_name text NOT NULL,
  specifications text,
  unit text,
  quantity integer NOT NULL,
  unit_price numeric,
  total_price numeric DEFAULT ((quantity)::numeric * unit_price),
  country_of_origin text,
  warranty_period text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  brand_model text,
  category_id uuid,
  product_id uuid,
  CONSTRAINT request_items_pkey PRIMARY KEY (id),
  CONSTRAINT request_items_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.purchase_requests(id),
  CONSTRAINT request_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
  CONSTRAINT request_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);


-- FUNCTIONS AND TRIGGERS --
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER set_updated_at_requests BEFORE UPDATE ON public.purchase_requests FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER set_updated_at_configurations BEFORE UPDATE ON public.configurations FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

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
BEFORE UPDATE ON public.purchase_requests
FOR EACH ROW
EXECUTE FUNCTION protect_staff_description();

-- ENABLE RLS --
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approvals_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_approvals_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES --

-- Purchase Requests Policies
CREATE POLICY "Users can view relevant requests" 
ON public.purchase_requests FOR SELECT 
USING (
  auth.uid() = created_by OR 
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'it_procurement', 'finance', 'admin'))
);

CREATE POLICY "Staff can create requests" 
ON public.purchase_requests FOR INSERT 
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Authorized roles can update requests" 
ON public.purchase_requests FOR UPDATE 
USING (
  (auth.uid() = created_by AND status != 'completed') OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'it_procurement', 'finance', 'admin'))
);

-- Items Policies
CREATE POLICY "Users can view items of accessible requests" 
ON public.request_items FOR SELECT 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id)
);

CREATE POLICY "Staff can manage items for own requests" 
ON public.request_items FOR ALL 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id AND pr.created_by = auth.uid() AND pr.status != 'completed')
);

-- Profile Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can manage all profiles" 
ON public.profiles FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Everyone can view profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Approvals Log Policies
CREATE POLICY "Users can view all logs" ON public.approvals_log FOR SELECT USING (true);
CREATE POLICY "Users can insert logs for reachable requests" ON public.approvals_log FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);
CREATE POLICY "Staff can delete logs for own requests" 
ON public.approvals_log FOR DELETE 
USING (
  EXISTS (SELECT 1 FROM purchase_requests pr WHERE pr.id = request_id AND pr.created_by = auth.uid())
);

-- Category Policies
CREATE POLICY "Everyone can view categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Only admins can manage categories" ON public.categories FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Product Policies
CREATE POLICY "Everyone can view products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Only admins can manage products" ON public.products FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Configuration Policies
CREATE POLICY "Allow public read access" 
ON public.configurations FOR SELECT 
USING (true);

CREATE POLICY "Allow admins to manage configurations" 
ON public.configurations FOR ALL 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'admin'
  )
);

-- DATA INSERTION --
INSERT INTO public.configurations (
  android_version, 
  ios_version, 
  force_update, 
  maintenance_mode
) VALUES (
  '1.0.0', 
  '1.0.0', 
  false, 
  false
);

-- FCM TOKENS TABLE --
CREATE TABLE public.fcm_tokens (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  token text NOT NULL,
  device_type text DEFAULT 'android' CHECK (device_type = ANY (ARRAY['android'::text, 'ios'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fcm_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT fcm_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT fcm_tokens_user_token_unique UNIQUE (user_id, token)
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tokens" ON public.fcm_tokens FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tokens" ON public.fcm_tokens FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tokens" ON public.fcm_tokens FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own tokens" ON public.fcm_tokens FOR DELETE USING (auth.uid() = user_id);
-- Service role can read all tokens (for Edge Function)
CREATE POLICY "Service role can read all tokens" ON public.fcm_tokens FOR SELECT USING (true);


-- 1. Resolve duplicate name field by renaming existing 'full_name' to 'full_name_en'
-- This preserves any existing data while aligning with the new Arabic/English requirements.
DO $$ 
BEGIN 
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'full_name') AND 
     NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'full_name_en') THEN
    ALTER TABLE public.profiles RENAME COLUMN full_name TO full_name_en;
  END IF;
END $$;

-- 2. Add all missing personal detail fields
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS full_name_ar text,
  ADD COLUMN IF NOT EXISTS date_of_birth date,
  ADD COLUMN IF NOT EXISTS gender text, 
  ADD COLUMN IF NOT EXISTS phone_number text,
  ADD COLUMN IF NOT EXISTS nationality text,
  ADD COLUMN IF NOT EXISTS current_address text,
  ADD COLUMN IF NOT EXISTS marital_status text,
  ADD COLUMN IF NOT EXISTS qualification text,
  ADD COLUMN IF NOT EXISTS id_number text,
  ADD COLUMN IF NOT EXISTS id_expiry_date date,
  ADD COLUMN IF NOT EXISTS passport_number text,
  ADD COLUMN IF NOT EXISTS passport_expiry_date date,
  ADD COLUMN IF NOT EXISTS work_permit_number text,
  ADD COLUMN IF NOT EXISTS work_permit_date date,
  ADD COLUMN IF NOT EXISTS sponsorship_number text,
  ADD COLUMN IF NOT EXISTS sponsorship_expiry_date date;

-- 3. Add Check Constraints for data integrity
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_gender_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_gender_check CHECK (gender = ANY (ARRAY['ذكر'::text, 'أنثى'::text]));

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_marital_status_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_marital_status_check CHECK (marital_status = ANY (ARRAY['متزوج'::text, 'اعزب'::text, 'ارمل'::text, 'مطلق'::text]));

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_qualification_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_qualification_check CHECK (qualification = ANY (ARRAY['دكتوراه'::text, 'بكالريوس'::text, 'ماجستير'::text, 'دبلوم'::text, 'ثانوية عامة'::text, 'غير ذلك'::text]));

-- 4. Company Structure (Departments -> Branches -> Divisions -> Units)

-- DEPARTMENTS (إدارات)
CREATE TABLE public.departments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_ar text,
  description text,
  phone text,
  manager_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT departments_pkey PRIMARY KEY (id),
  CONSTRAINT departments_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.profiles(id)
);

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view departments" ON public.departments FOR SELECT USING (true);
CREATE POLICY "Admins can manage departments" ON public.departments FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Update existing BRANCHES table (فروع)
ALTER TABLE public.branches 
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS manager_id uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS department_id uuid REFERENCES public.departments(id);

-- DIVISIONS (أقسام)
CREATE TABLE public.divisions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_ar text,
  description text,
  phone text,
  manager_id uuid,
  branch_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT divisions_pkey PRIMARY KEY (id),
  CONSTRAINT divisions_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.profiles(id),
  CONSTRAINT divisions_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id)
);

ALTER TABLE public.divisions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view divisions" ON public.divisions FOR SELECT USING (true);
CREATE POLICY "Admins can manage divisions" ON public.divisions FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- UNITS (وحدات)
CREATE TABLE public.units (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_ar text,
  description text,
  phone text,
  manager_id uuid,
  division_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT units_pkey PRIMARY KEY (id),
  CONSTRAINT units_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.profiles(id),
  CONSTRAINT units_division_id_fkey FOREIGN KEY (division_id) REFERENCES public.divisions(id)
);

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can view units" ON public.units FOR SELECT USING (true);
CREATE POLICY "Admins can manage units" ON public.units FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Triggers for updated_at
CREATE TRIGGER set_updated_at_departments BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER set_updated_at_divisions BEFORE UPDATE ON public.divisions FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER set_updated_at_units BEFORE UPDATE ON public.units FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

-- USER STRUCTURE ASSIGNMENTS (Replaces user_branches)
CREATE TABLE public.user_structure_assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  department_id uuid,
  branch_id uuid,
  division_id uuid,
  unit_id uuid,
  access_level text DEFAULT 'view'::text CHECK (access_level = ANY (ARRAY['full'::text, 'view'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_structure_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT user_structure_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT user_structure_assignments_dept_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE CASCADE,
  CONSTRAINT user_structure_assignments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE,
  CONSTRAINT user_structure_assignments_div_id_fkey FOREIGN KEY (division_id) REFERENCES public.divisions(id) ON DELETE CASCADE,
  CONSTRAINT user_structure_assignments_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE,
  CONSTRAINT single_assignment_check CHECK (
    (department_id IS NOT NULL)::integer + 
    (branch_id IS NOT NULL)::integer + 
    (division_id IS NOT NULL)::integer + 
    (unit_id IS NOT NULL)::integer = 1
  )
);

ALTER TABLE public.user_structure_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own structure assignments" 
ON public.user_structure_assignments FOR SELECT 
USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')));

CREATE POLICY "Admins can manage structure assignments" 
ON public.user_structure_assignments FOR ALL 
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
