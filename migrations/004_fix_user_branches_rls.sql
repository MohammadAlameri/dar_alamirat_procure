-- ============================================================
-- MIGRATION 004: Fix user_branches RLS
-- ============================================================

-- 1. Drop old restrictive policies
DROP POLICY IF EXISTS "Users can view own branch assignments" ON user_branches;
DROP POLICY IF EXISTS "Admins can manage branch assignments" ON user_branches;

-- 2. Re-create View Policy
-- Rule: Users see their own assignments. Admin, GM, IT, and Finance can see ALL assignments.
CREATE POLICY "Authorized users can view branch assignments" 
ON user_branches FOR SELECT 
TO authenticated
USING (
  user_id = auth.uid() OR 
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'general_manager', 'it_procurement', 'finance')
  )
);

-- 3. Re-create Management Policy (Insert/Update/Delete)
-- Rule: Only Admins and General Managers can assign or remove users from branches.
CREATE POLICY "Admins can manage branch assignments" 
ON user_branches FOR ALL 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'general_manager')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'general_manager')
  )
);
