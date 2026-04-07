// Branch-aware permissions system
// Rule: User role is GLOBAL (e.g. "manager" everywhere)
// But access_level per branch is either "full" (can approve/edit) or "view" (read-only)

window.permissions = {
    _userBranches: [],  // Cached [{branch_id, access_level}]
    _currentBranchId: null,

    // Load branch assignments for current user
    async load(userId) {
        const { data, error } = await supabaseClient
            .from('user_branches')
            .select('branch_id, access_level, branches(id, name, name_ar, code)')
            .eq('user_id', userId);

        if (error) {
            console.error('Error loading user branches:', error);
            this._userBranches = [];
            return;
        }
        this._userBranches = data || [];
        
        // Try to restore from localStorage, otherwise auto-select first "full" branch, or first branch
        const savedBranchId = localStorage.getItem(`selectedBranch_${userId}`);
        const branchExists = savedBranchId && this._userBranches.some(b => b.branch_id === savedBranchId);

        if (branchExists) {
            this._currentBranchId = savedBranchId;
        } else {
            const fullBranch = this._userBranches.find(b => b.access_level === 'full');
            this._currentBranchId = fullBranch ? fullBranch.branch_id : (this._userBranches[0]?.branch_id || null);
            
            // Save the default selection if it exists
            if (this._currentBranchId && userId) {
                localStorage.setItem(`selectedBranch_${userId}`, this._currentBranchId);
            }
        }
    },

    // Get all branches the user has access to
    getUserBranches() {
        return this._userBranches;
    },

    // Get current active branch
    getCurrentBranchId() {
        return this._currentBranchId;
    },

    // Set current branch (e.g. from branch selector dropdown)
    setCurrentBranch(branchId) {
        this._currentBranchId = branchId;
        if (currentUser && currentUser.id) {
            localStorage.setItem(`selectedBranch_${currentUser.id}`, branchId);
        }
    },

    // Get access level for a specific branch
    getAccessLevel(branchId) {
        const entry = this._userBranches.find(b => b.branch_id === branchId);
        return entry ? entry.access_level : null; // null = no access
    },

    // Can the user perform write operations in a specific branch?
    canEdit(branchId) {
        // Admin can always edit
        if (currentUser?.profile?.role === 'admin') return true;
        return this.getAccessLevel(branchId) === 'full';
    },

    // Can the user view data in a specific branch?
    canView(branchId) {
        if (currentUser?.profile?.role === 'admin') return true;
        const level = this.getAccessLevel(branchId);
        return level === 'full' || level === 'view';
    },

    // Can the user approve requests in a specific branch?
    canApprove(branchId) {
        const role = currentUser?.profile?.role;
        if (role === 'admin') return true;
        if (!['manager', 'it_procurement', 'finance', 'general_manager', 'accountant'].includes(role)) return false;
        return this.getAccessLevel(branchId) === 'full';
    },

    // Check if user has any branch with full access
    hasAnyFullAccess() {
        if (currentUser?.profile?.role === 'admin') return true;
        return this._userBranches.some(b => b.access_level === 'full');
    },

    // Get branches where user has full access
    getFullAccessBranches() {
        if (currentUser?.profile?.role === 'admin') {
            return this._userBranches;
        }
        return this._userBranches.filter(b => b.access_level === 'full');
    }
};
