// Dashboard functions
async function loadDashboardData() {
    const role = currentUser.profile.role;
    let requests = [];
    const filters = {};

    // Apply branch filter
    const currentBranchId = permissions.getCurrentBranchId();
    if (currentBranchId) {
        filters.branchId = currentBranchId;
    }

    if (role === 'employee') {
        filters.userId = currentUser.id;
    }
    // For managers and other roles, we rely on RLS to return the correct set of records.

    requests = await db.getRequests(filters);
    console.log("DEBUG: Fetched requests:", requests.length);

    // --- Expense Data Loading ---
    let expenses = await db.getExpenseRequests(filters);
    console.log("DEBUG: Fetched expenses:", expenses.length);
    expenses = expenses.map(e => ({ ...e, type: 'expense' }));
    requests = requests.map(r => ({ ...r, type: 'procure' }));

    // Combined recent for dashboard
    const combinedRecent = [...requests, ...expenses]
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    // Update stats - include both? User just asked to "differentiate between them"
    // Let's keep stats for procure but maybe show unified recents.
    const statTotal = requests.length + expenses.length;
    const statPendingProcure = requests.filter(r => ['pending', 'manager_approved', 'it_approved', 'finance_approved', 'purchased'].includes(r.status)).length;
    const statPendingExpense = expenses.filter(e => !['completed', 'paid', 'received'].includes(e.status) && !e.status.includes('rejected')).length;
    const statApproved = requests.filter(r => r.status === 'completed').length + expenses.filter(e => e.status === 'completed').length;
    const statRejected = [...requests, ...expenses].filter(r => r.status && r.status.toLowerCase().includes('rejected')).length;

    document.getElementById('stat-total').innerText = statTotal;
    document.getElementById('stat-pending').innerText = statPendingProcure + statPendingExpense;
    document.getElementById('stat-approved').innerText = statApproved;
    document.getElementById('stat-rejected').innerText = statRejected;

    // Render tables
    ui.renderRequestsTable('recentRequestsTable', combinedRecent.slice(0, 10), role);
    // For managers, 'requests' already contains their own + their staff's (due to RLS or previous db calls).
    // We want to show all of those in "My Requests" (or "Staff & My Requests").
    // For employees, we stay restricted.
    const myRequests = (role === 'manager' || role === 'admin' || role === 'it_procurement' || role === 'finance') 
        ? requests 
        : requests.filter(r => r.created_by === currentUser.id);
        
    const myExpenses = (role === 'manager' || role === 'admin' || role === 'finance' || role === 'accountant') 
        ? expenses 
        : expenses.filter(e => e.employee_id === currentUser.id);

    console.log(`DEBUG: [${role}] myRequests count:`, myRequests.length);
    console.log(`DEBUG: [${role}] myExpenses count:`, myExpenses.length);

    ui.renderRequestsTable('myRequestsTable', myRequests, role);
    ui.renderExpensesTable('expenseRequestsTable', myExpenses, role);
    
    // Unified Pending Approvals
    let pendingProcure = [];
    if (role === 'manager') {
        pendingProcure = requests.filter(r => r.status === 'pending' || r.status === 'rejected_by_manager');
    } else if (role === 'it_procurement') {
        pendingProcure = requests.filter(r => r.status === 'manager_approved' || r.status === 'finance_approved' || r.status === 'received_by_staff' || r.status === 'rejected_by_it' || r.status === 'rejected_by_it_purchase');
    } else if (role === 'finance') {
        pendingProcure = requests.filter(r => r.status === 'it_approved' || r.status === 'rejected_by_finance');
    } else if (role === 'employee') {
        // Staff sees requests that they need to receipt or have rejected
        pendingProcure = requests.filter(r => r.created_by === currentUser.id && (r.status === 'purchased' || r.status === 'rejected_by_staff'));
    }

    let pendingExpenses = [];
    if (role === 'manager') {
        pendingExpenses = expenses.filter(e => e.status === 'pending' || e.status === 'rejected_by_manager');
    } else if (role === 'finance') {
        pendingExpenses = expenses.filter(e => (e.highest_approval_level === 'finance' || e.highest_approval_level === 'general_manager') && (e.status === 'manager_approved' || e.status === 'rejected_by_finance'));
    } else if (role === 'general_manager') {
        pendingExpenses = expenses.filter(e => e.highest_approval_level === 'general_manager' && (e.status === 'finance_approved' || e.status === 'rejected_by_gm'));
    } else if (role === 'accountant') {
        pendingExpenses = expenses.filter(e => {
            if (e.status === 'paid' || e.status === 'completed' || e.status === 'received') return false;
            if (e.highest_approval_level === 'manager' && e.status === 'manager_approved') return true;
            if (e.highest_approval_level === 'finance' && e.status === 'finance_approved') return true;
            if (e.highest_approval_level === 'general_manager' && e.status === 'gm_approved') return true;
            return false;
        });
    }

    const unifiedPending = [...pendingProcure, ...pendingExpenses]
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    ui.renderRequestsTable('pendingApprovalsTable', unifiedPending, role);

    // Unified All Requests with Filtering
    globalAllRequests = [...requests, ...expenses].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    renderFilteredAllRequests();
    // --- End Unified Data Loading ---

    if (role === 'admin') {
        try {
            console.log("Fetching all profiles as admin...");
            const profiles = await db.getAllProfiles();
            const filteredProfiles = profiles.filter(p => p.role !== 'admin');
            
            console.log("Profiles found (excluding admins):", filteredProfiles.length);
            ui.renderProfilesTable(filteredProfiles);

            // Fetch and populate manager dropdown for the form
            const allManagers = profiles.filter(p => p.role === 'manager');
            ui.populateManagerDropdown(allManagers);
        } catch (error) {
            console.error('Error loading profiles:', error);
        }
    }

    // Load Categories & Products (Global)
    try {
        const { data: cats } = await supabaseClient.from('categories').select('*').order('name');
        globalCategories = cats || [];
        ui.populateCategorySelects(globalCategories);
        
        if (role === 'admin') {
            ui.renderCategoriesTable(globalCategories);
            const { data: prods } = await supabaseClient.from('products').select('*, categories(name)').order('name');
            globalProducts = prods || [];
            ui.renderProductsTable(globalProducts);
        }
    } catch (err) {
        console.error("Error loading categories/products:", err);
    }
}
let globalAllRequests = [];

function renderFilteredAllRequests() {
    const filterType = document.getElementById('allRequestsFilterType')?.value || 'all';
    let filtered = globalAllRequests;
    
    if (filterType !== 'all') {
        filtered = globalAllRequests.filter(r => r.type === filterType);
    }
    
    const role = currentUser?.profile?.role;
    ui.renderRequestsTable('allRequestsTable', filtered, role);
}
