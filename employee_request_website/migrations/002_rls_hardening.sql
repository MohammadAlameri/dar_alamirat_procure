-- ============================================================
-- MIGRATION 002: RLS Hardening & Audit Trail Security
-- ============================================================

-- ============================================================
-- 1. HARDENING PURCHASE_REQUESTS RLS
-- ============================================================

-- Drop existing generic policies if they exist
DROP POLICY IF EXISTS "Users can view relevant requests" ON purchase_requests;
DROP POLICY IF EXISTS "Authorized roles can update requests" ON purchase_requests;

-- CREATE NEW SELECT POLICY: Users can view their own requests, OR requests from branches they have access to, OR if admin
CREATE POLICY "Users can view relevant branch requests" 
ON purchase_requests FOR SELECT 
USING (
  auth.uid() = created_by OR 
  EXISTS (
    SELECT 1 FROM user_branches ub 
    WHERE ub.user_id = auth.uid() 
      AND ub.branch_id = purchase_requests.branch_id
  ) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- CREATE NEW UPDATE POLICY: Users can update their own pending requests, OR if they have 'full' access to the branch, OR if admin
CREATE POLICY "Authorized roles can update branch requests" 
ON purchase_requests FOR UPDATE 
USING (
  (auth.uid() = created_by AND status NOT IN ('completed', 'rejected')) OR
  EXISTS (
    SELECT 1 FROM user_branches ub 
    WHERE ub.user_id = auth.uid() 
      AND ub.branch_id = purchase_requests.branch_id 
      AND ub.access_level = 'full'
  ) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);


-- ============================================================
-- 2. HARDENING EXPENSE_REQUESTS RLS
-- ============================================================

-- Assuming similar generic policies exist, we drop them first
DROP POLICY IF EXISTS "Users can view relevant requests" ON expense_requests;
DROP POLICY IF EXISTS "Authorized roles can update requests" ON expense_requests;

-- Same logic for expense_requests
CREATE POLICY "Users can view relevant branch expense requests" 
ON expense_requests FOR SELECT 
USING (
  auth.uid() = employee_id OR 
  EXISTS (
    SELECT 1 FROM user_branches ub 
    WHERE ub.user_id = auth.uid() 
      AND ub.branch_id = expense_requests.branch_id
  ) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Authorized roles can update branch expense requests" 
ON expense_requests FOR UPDATE 
USING (
  (auth.uid() = employee_id AND status NOT IN ('completed', 'rejected')) OR
  EXISTS (
    SELECT 1 FROM user_branches ub 
    WHERE ub.user_id = auth.uid() 
      AND ub.branch_id = expense_requests.branch_id 
      AND ub.access_level = 'full'
  ) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);


-- ============================================================
-- 3. AUDIT TRAIL IMMUTABILITY (APPROVALS LOGS)
-- ============================================================

-- Ensure RLS is enabled on the logs
ALTER TABLE approvals_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS expense_approvals_log ENABLE ROW LEVEL SECURITY;

-- Remove any existing UPDATE or DELETE policies
DROP POLICY IF EXISTS "Users can update logs" ON approvals_log;
DROP POLICY IF EXISTS "Users can delete logs" ON approvals_log;
DROP POLICY IF EXISTS "Staff can delete logs for own requests" ON approvals_log; -- From initial schema
-- Do the same for expense logs if they exist
DROP POLICY IF EXISTS "Staff can delete logs for own requests" ON expense_approvals_log;

-- Users can only SELECT and INSERT logs
CREATE POLICY "Users can insert approvals" ON approvals_log FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Check if expense_approvals_log exists before running this (most PostgreSQL deployments handle this fine if table exists)
CREATE POLICY "Users can insert expense approvals" ON expense_approvals_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create a generic function to block UPDATE/DELETE on audit tables entirely
CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit logs are immutable. Updates and Deletions are strictly prohibited for security reasons.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to approvals_log
DROP TRIGGER IF EXISTS trg_prevent_approvals_log_mod ON approvals_log;
CREATE TRIGGER trg_prevent_approvals_log_mod
BEFORE UPDATE OR DELETE ON approvals_log
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();

-- Attach trigger to expense_approvals_log (using a DO block to check if table exists first)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expense_approvals_log') THEN
        DROP TRIGGER IF EXISTS trg_prevent_expense_approvals_log_mod ON expense_approvals_log;
        CREATE TRIGGER trg_prevent_expense_approvals_log_mod
        BEFORE UPDATE OR DELETE ON expense_approvals_log
        FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();
    END IF;
END
$$;


-- ============================================================
-- 4. HARDENING THE MAIN AUDIT_LOG TABLE (from 001_multi_branch)
-- ============================================================

-- The audit_log table should also be immutable
DROP TRIGGER IF EXISTS trg_prevent_main_audit_log_mod ON audit_log;
CREATE TRIGGER trg_prevent_main_audit_log_mod
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();
