-- ============================================================
-- MIGRATION 003: Fix RLS for Request Items
-- ============================================================

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Staff can manage items for own requests" ON request_items;

-- Create a new policy that allows managers and authorized personnel to update items
-- This policy uses the same logic as "Authorized roles can update branch requests"
CREATE POLICY "Authorized users can manage items" 
ON request_items FOR ALL 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM purchase_requests pr
    WHERE pr.id = request_items.request_id
      AND (
        -- 1. Original requester
        pr.created_by = auth.uid() OR
        -- 2. User with FULL access to the branch (Manager, IT, etc.)
        EXISTS (
          SELECT 1 FROM user_branches ub 
          WHERE ub.user_id = auth.uid() 
            AND ub.branch_id = pr.branch_id 
            AND ub.access_level = 'full'
        ) OR
        -- 3. Admin
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
      )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM purchase_requests pr
    WHERE pr.id = request_items.request_id
      AND (
        -- 1. Original requester (if not completed)
        (pr.created_by = auth.uid() AND pr.status NOT IN ('completed', 'rejected')) OR
        -- 2. User with FULL access to the branch
        EXISTS (
          SELECT 1 FROM user_branches ub 
          WHERE ub.user_id = auth.uid() 
            AND ub.branch_id = pr.branch_id 
            AND ub.access_level = 'full'
        ) OR
        -- 3. Admin
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
      )
  )
);
