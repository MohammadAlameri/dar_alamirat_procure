// Main App Controller
let currentUser = null;
var globalCategories = [];
var globalProducts = [];

document.addEventListener('DOMContentLoaded', async () => {
    // 1. Check Auth 
    ui.setLoading(true);
    try {
        const { data: { session } } = await supabaseClient.auth.getSession();
        if (!session) {
            globalThis.location.href = 'auth.html';
            return;
        }

        const userWithProfile = await auth.getCurrentUser();
        if (!userWithProfile) {
            ui.showNotification(i18nManager.get('errorProfileNotFound'), 'error');
            await auth.signOut();
            return;
        }
        currentUser = userWithProfile;
        ui.updateUserUI(currentUser);

        // 2. Initialize Dashboard Data
        await loadDashboardData();

    } catch (error) {
        console.error('Initial load error:', error);
    } finally {
        ui.setLoading(false);
    }

    // 3. Event Listeners
    setupEventListeners();

    // 4. Handle Persisted Sidebar State (Desktop)
    if (globalThis.innerWidth > 992) {
        const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
        if (isCollapsed) {
            document.getElementById('sidebar')?.classList.add('collapsed');
            document.getElementById('main-content')?.classList.add('sidebar-collapsed');
            const icon = document.getElementById('collapseIcon');
            if (icon) {
                icon.setAttribute('data-lucide', 'chevron-right');
                lucide.createIcons();
            }
        }
    }
});

async function loadDashboardData() {
    const role = currentUser.profile.role;
    let requests = [];
    const filters = {};

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

function setupEventListeners() {
    // Sidebar navigation
    document.querySelectorAll('#sidebar .nav-link:not(#logoutBtn)').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const viewId = link.dataset.view;
            
            // Check permissions before showing view
            if (viewId === 'user-management' && currentUser?.profile?.role !== 'admin') {
                ui.showView('overview');
                return;
            }
            
            // Reset all form states when switching views to prevent "ghost" edits
            ui.resetPurchaseRequestForm();
            ui.resetExpenseRequestForm();
            const title = document.getElementById('currentViewTitle');
            if (title) title.innerText = i18nManager.get('dashboardOverview');

            ui.showView(viewId);
            
            // Auto-hide sidebar on mobile after selection
            if (globalThis.innerWidth <= 992) {
                document.getElementById('sidebar').classList.remove('show');
            }
        });
    });

    // Sidebar Toggle (Mobile & Desktop)
    document.getElementById('sidebarToggle')?.addEventListener('click', () => {
        const sidebar = document.getElementById('sidebar');
        const mainContent = document.getElementById('main-content');
        
        if (globalThis.innerWidth <= 992) {
            // Mobile: Toggle slide-in
            sidebar.classList.toggle('show');
        } else {
            // Desktop: Toggle collapse (expand if it was collapsed)
            sidebar.classList.toggle('collapsed');
            mainContent.classList.toggle('sidebar-collapsed');
            
            const isCollapsed = sidebar.classList.contains('collapsed');
            localStorage.setItem('sidebarCollapsed', isCollapsed);
            
            // Sync the chevron icon in the sidebar
            const icon = document.getElementById('collapseIcon');
            if (icon) {
                icon.setAttribute('data-lucide', isCollapsed ? 'chevron-right' : 'chevron-left');
                lucide.createIcons();
            }
        }
    });

    // Dedicated Collapse Button (Inside Sidebar)
    document.getElementById('collapseSidebar')?.addEventListener('click', () => {
        const sidebar = document.getElementById('sidebar');
        const mainContent = document.getElementById('main-content');
        
        if (globalThis.innerWidth <= 992) {
            // Mobile: Click hide button inside should close the drawer
            sidebar.classList.remove('show');
        } else {
            // Desktop: Toggle collapse
            sidebar.classList.toggle('collapsed');
            mainContent.classList.toggle('sidebar-collapsed');
            
            const isCollapsed = sidebar.classList.contains('collapsed');
            localStorage.setItem('sidebarCollapsed', isCollapsed);
            
            // Update icon
            const icon = document.getElementById('collapseIcon');
            if (icon) {
                icon.setAttribute('data-lucide', isCollapsed ? 'chevron-right' : 'chevron-left');
                lucide.createIcons();
            }
        }
    });

    // Language Switcher
    const langToggle = document.getElementById('langSwitchBtn');
    const langText = document.getElementById('langText');
    if (langToggle) {
        if (i18nManager.currentLang === 'ar') {
            langText.innerText = 'English';
        } else {
            langText.innerText = 'العربية';
        }
        langToggle.addEventListener('click', () => {
            const newLang = i18nManager.currentLang === 'en' ? 'ar' : 'en';
            i18nManager.setLanguage(newLang);
        });
    }

    // Product & Category Listeners
    document.getElementById('addCategoryBtn')?.addEventListener('click', () => {
        ui.toggleCategoryForm(true);
    });

    document.getElementById('addProductBtn')?.addEventListener('click', () => {
        ui.toggleProductForm(true);
        const filterVal = document.getElementById('filterCategoryDropdown').value;
        if (filterVal !== 'all') {
            document.getElementById('pm_product_category').value = filterVal;
        }
    });

    document.querySelectorAll('.cancel-pm-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            ui.toggleCategoryForm(false);
            ui.toggleProductForm(false);
        });
    });

    // Category Form Submit
    document.getElementById('categoryForm')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('category_id').value;
        const name = document.getElementById('category_name_input').value;
        
        ui.setLoading(true);
        try {
            if (id) {
                await supabaseClient.from('categories').update({ name }).eq('id', id);
            } else {
                await supabaseClient.from('categories').insert([{ name }]);
            }
            ui.showNotification(i18nManager.get('savedSuccessfully'), 'success');
            ui.toggleCategoryForm(false);
            await loadDashboardData();
        } catch (err) {
            ui.showNotification(err.message, 'error');
        } finally {
            ui.setLoading(false);
        }
    });

    // Product Form Submit
    document.getElementById('productForm')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('pm_product_id').value;
        const name = document.getElementById('pm_product_name').value;
        const category_id = document.getElementById('pm_product_category').value;
        
        ui.setLoading(true);
        try {
            if (id) {
                await supabaseClient.from('products').update({ name, category_id }).eq('id', id);
            } else {
                await supabaseClient.from('products').insert([{ name, category_id }]);
            }
            ui.showNotification(i18nManager.get('savedSuccessfully'), 'success');
            ui.toggleProductForm(false);
            await loadDashboardData();
        } catch (err) {
            ui.showNotification(err.message, 'error');
        } finally {
            ui.setLoading(false);
        }
    });

    document.getElementById('view-product-management')?.addEventListener('click', async (e) => {
        const editCat = e.target.closest('.edit-category-btn');
        const deleteCat = e.target.closest('.delete-category-btn');
        const editProd = e.target.closest('.edit-product-btn');
        const deleteProd = e.target.closest('.delete-product-btn');

        if (editCat) {
            const { id, name } = editCat.dataset;
            ui.toggleCategoryForm(true);
            document.getElementById('category_id').value = id;
            document.getElementById('category_name_input').value = name;
            document.getElementById('categoryFormTitle').innerText = i18nManager.get('editCategory');
            document.getElementById('categoryFormTitle').removeAttribute('data-i18n');
        }
        if (deleteCat) {
            if (confirm(i18nManager.get('confirmDeleteCategory'))) {
                ui.setLoading(true);
                await supabaseClient.from('categories').delete().eq('id', deleteCat.dataset.id);
                await loadDashboardData();
                ui.setLoading(false);
            }
        }
        if (editProd) {
            const { id, name, catid } = editProd.dataset;
            ui.toggleProductForm(true);
            document.getElementById('pm_product_id').value = id;
            document.getElementById('pm_product_name').value = name;
            document.getElementById('pm_product_category').value = catid;
            document.getElementById('productFormTitle').innerText = i18nManager.get('editProduct');
            document.getElementById('productFormTitle').removeAttribute('data-i18n');
        }
        if (deleteProd) {
            if (confirm(i18nManager.get('confirmDeleteProduct'))) {
                ui.setLoading(true);
                await supabaseClient.from('products').delete().eq('id', deleteProd.dataset.id);
                await loadDashboardData();
                ui.setLoading(false);
            }
        }
    });

    document.getElementById('filterCategoryDropdown')?.addEventListener('change', async (e) => {
        const catId = e.target.value;
        let query = supabaseClient.from('products').select('*, categories(name)').order('name');
        if (catId !== 'all') query = query.eq('category_id', catId);
        const { data } = await query;
        ui.renderProductsTable(data);
    });

    // Product Search Logic
    document.getElementById('itemsTable')?.addEventListener('input', async (e) => {
        if (e.target.classList.contains('product-search')) {
            const searchInput = e.target;
            const queryText = searchInput.value.trim();
            const row = searchInput.closest('tr');
            const catSelect = row.querySelector('.category-select');
            const catId = catSelect.value;
            const resultsDiv = row.querySelector('.product-results');

            if (!catId) {
                ui.showNotification(i18nManager.get('selectCategory'), 'warning');
                return;
            }

            if (queryText.length < 2) {
                resultsDiv.innerHTML = '';
                resultsDiv.classList.remove('show');
                return;
            }

            const { data } = await supabaseClient
                .from('products')
                .select('*')
                .eq('category_id', catId)
                .ilike('name', `%${queryText}%`)
                .limit(5);

            resultsDiv.innerHTML = '';
            if (data && data.length > 0) {
                data.forEach(p => {
                    const item = document.createElement('a');
                    item.className = 'dropdown-item';
                    item.href = '#';
                    item.innerText = p.name;
                    item.addEventListener('click', (ev) => {
                        ev.preventDefault();
                        searchInput.value = p.name;
                        row.querySelector('.product-id-input').value = p.id;
                        resultsDiv.innerHTML = '';
                        resultsDiv.classList.remove('show');
                    });
                    resultsDiv.appendChild(item);
                });
                resultsDiv.classList.add('show');
            } else {
                resultsDiv.innerHTML = `<span class="dropdown-item disabled">${i18nManager.get('newProduct')}</span>`;
                resultsDiv.classList.add('show');
            }
        }
    });

    // Hide search results when clicking outside
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.position-relative')) {
            document.querySelectorAll('.product-results').forEach(el => {
                el.innerHTML = '';
                el.classList.remove('show');
            });
        }
    });

    // Buttons
    document.getElementById('createNewBtn').addEventListener('click', () => {
        ui.resetPurchaseRequestForm();
        const title = document.getElementById('currentViewTitle');
        if (title) title.innerText = i18nManager.get('newRequest');
        ui.showView('create-request');
    });

    document.getElementById('createNewExpenseBtn')?.addEventListener('click', () => {
        ui.resetExpenseRequestForm();
        const title = document.getElementById('currentViewTitle');
        if (title) title.innerText = i18nManager.get('newExpenseRequest');
        ui.showView('create-expense');
    });

    document.getElementById('dashCreateExpenseBtn')?.addEventListener('click', () => {
        ui.resetExpenseRequestForm();
        const title = document.getElementById('currentViewTitle');
        if (title) title.innerText = i18nManager.get('newExpenseRequest');
        ui.showView('create-expense');
    });

    document.getElementById('myRequestsCreateBtn')?.addEventListener('click', () => {
        ui.resetPurchaseRequestForm();
        const title = document.getElementById('currentViewTitle');
        if (title) title.innerText = i18nManager.get('newRequest');
        ui.showView('create-request');
    });

    document.getElementById('allRequestsFilterType')?.addEventListener('change', () => {
        const role = currentUser?.profile?.role;
        if (role === 'it_procurement' || role === 'finance' || role === 'admin' || role === 'general_manager') {
            renderFilteredAllRequests();
        }
    });

    document.getElementById('showCreateProfileBtn')?.addEventListener('click', () => ui.toggleProfileForm(true));

    // Modal Reset Logic (listen for Bootstrap hidden event)
    document.getElementById('profileModal')?.addEventListener('hidden.bs.modal', () => ui.toggleProfileForm(false));
    document.getElementById('categoryModal')?.addEventListener('hidden.bs.modal', () => ui.toggleCategoryForm(false));
    document.getElementById('productModal')?.addEventListener('hidden.bs.modal', () => ui.toggleProductForm(false));

    // Password Toggle
    document.getElementById('togglePasswordBtn')?.addEventListener('click', () => {
        const passwordInput = document.getElementById('password');
        const icon = document.querySelector('#togglePasswordBtn i');
        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            icon.dataset.lucide = 'eye-off';
        } else {
            passwordInput.type = 'password';
            icon.dataset.lucide = 'eye';
        }
        lucide.createIcons();
    });

    // Handle role change to toggle manager field visibility
    document.getElementById('role')?.addEventListener('change', () => {
        ui.updateManagerFieldVisibility();
    });

    // Profile Management: Edit/Delete (Event delegation)
    const profilesTableBody = document.getElementById('profilesTableBody');
    profilesTableBody?.addEventListener('click', (e) => {
        const editBtn = e.target.closest('.edit-profile-btn');
        const deleteBtn = e.target.closest('.delete-profile-btn');

        if (editBtn) {
            const data = editBtn.dataset;
            ui.toggleProfileForm(true);
            document.getElementById('profile_id').value = data.id;
            document.getElementById('full_name').value = data.name;
            document.getElementById('email').value = data.email;
            document.getElementById('role').value = data.role;
            document.getElementById('job_title').value = data.title;
            document.getElementById('department').value = data.dept;
            document.getElementById('manager_id').value = data.manager || '';
            document.getElementById('passwordHint').classList.remove('d-none');
            document.getElementById('password').required = false;
            document.getElementById('profileFormTitle').innerText = i18nManager.get('editProfile');
            ui.updateManagerFieldVisibility();
        }

        if (deleteBtn) {
            const { id, name } = deleteBtn.dataset;
            if (confirm(`${i18nManager.get('confirmDeleteProfile')} ${name}?`)) {
                handleProfileDelete(id);
            }
        }
    });

    // Create/Edit Profile Form Submission
    const createUserForm = document.getElementById('createUserForm');
    if (createUserForm) {
        createUserForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            ui.setLoading(true);
            const alertEl = document.getElementById('createUserAlert');
            const alertDiv = alertEl ? alertEl.querySelector('.alert') : null;
            if (alertEl) alertEl.classList.add('d-none');

            try {
                const formData = new FormData(e.target);
                const profileId = formData.get('profile_id');
                const fullName = formData.get('full_name');
                const email = formData.get('email');
                const password = formData.get('password');
                const role = formData.get('role');
                const jobTitle = formData.get('job_title');
                const department = formData.get('department');
                const managerId = formData.get('manager_id') || null;

                if (profileId) {
                    // Update
                    await db.updateProfile(profileId, { 
                        full_name: fullName, 
                        role, 
                        job_title: jobTitle, 
                        department,
                        manager_id: managerId 
                    });
                } else {
                    // Create
                    const { data: authData, error: authError } = await supabaseClient.auth.signUp({
                        email,
                        password,
                        options: { data: { role: role, full_name: fullName } }
                    });
                    if (authError) throw authError;

                    if (authData.user) {
                        await db.createProfile({
                            id: authData.user.id,
                            full_name: fullName,
                            email,
                            role,
                            job_title: jobTitle,
                            department,
                            manager_id: managerId
                        });
                    }
                }

                if (alertDiv) {
                    alertDiv.className = 'alert alert-success';
                    alertDiv.innerText = i18nManager.get('savedSuccessfully');
                }
                if (alertEl) alertEl.classList.remove('d-none');
                
                setTimeout(() => {
                    ui.toggleProfileForm(false);
                    loadDashboardData();
                }, 1500);

            } catch (error) {
                console.error('Profile action error:', error);
                if (alertDiv) {
                    alertDiv.className = 'alert alert-danger';
                    alertDiv.innerText = i18nManager.get('error') + error.message;
                }
                if (alertEl) alertEl.classList.remove('d-none');
            } finally {
                ui.setLoading(false);
            }
        });
    }

    // Logout
    document.getElementById('logoutBtn').addEventListener('click', async (e) => {
        e.preventDefault();
        await auth.signOut();
    });

    // Form logic: Add row
    document.getElementById('addRowBtn').addEventListener('click', () => {
        ui.addRowToItemsTable();
    });

    // Form logic: Calculate totals on input
    document.getElementById('itemsTable').addEventListener('input', (e) => {
        if (e.target.classList.contains('qty-input') || e.target.classList.contains('price-input')) {
            ui.calculateTotals();
        }
    });

    // Form logic: Remove row
    document.getElementById('itemsTable').addEventListener('click', (e) => {
        if (e.target.closest('.remove-row')) {
            const row = e.target.closest('tr');
            if (document.querySelectorAll('#itemsBody tr').length > 1) {
                row.remove();
                ui.calculateTotals();
            }
        }
    });

    // Purchase Request Form Submission
    document.getElementById('purchaseRequestForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        ui.setLoading(true);

        try {
            const formData = new FormData(e.target);
            const requestData = {
                subject: formData.get('subject'),
                justification: formData.get('justification'),
                requested_by_name: formData.get('requested_by_name'),
                requested_by_title: formData.get('requested_by_title'),
                status: 'pending',
                created_by: currentUser.id,
                total_amount: Number.parseFloat(document.getElementById('grandTotal').value)
            };

            const items = [];
            const productNames = formData.getAll('product_name[]');
            const productIds = formData.getAll('product_id[]');
            const categoryIds = formData.getAll('category_id[]');
            const specs = formData.getAll('specifications[]');
            const units = formData.getAll('unit[]');
            const qties = formData.getAll('quantity[]');
            const prices = formData.getAll('unit_price[]');
            const countries = formData.getAll('country_of_origin[]');
            const warranties = formData.getAll('warranty_period[]');
            const brands = formData.getAll('brand_model[]');

            for (let i = 0; i < productNames.length; i++) {
                items.push({
                    product_id: productIds[i] || null,
                    category_id: categoryIds[i] || null,
                    product_name: productNames[i],
                    specifications: specs[i],
                    unit: units[i],
                    quantity: Number.parseInt(qties[i]),
                    unit_price: Number.parseFloat(prices[i]),
                    country_of_origin: countries[i] || null,
                    warranty_period: warranties[i] || null,
                    brand_model: brands[i] || null
                });
            }

            const editId = formData.get('edit_request_id');
            if (editId) {
                // If staff changes something, reset status and delete previous approvals
                const { data: previousReq } = await supabaseClient.from('purchase_requests').select('status, created_by').eq('id', editId).single();
                
                if (previousReq.created_by === currentUser.id) {
                    requestData.status = 'pending'; // Reset to pending
                    // Delete old approvals log for this request to restart workflow
                    await supabaseClient.from('approvals_log').delete().eq('request_id', editId);
                }

                await db.updateRequestFull(editId, requestData, items);
                ui.showNotification(i18nManager.get('requestUpdated'), 'success');
            } else {
                await db.createRequest(requestData, items);
                ui.showNotification(i18nManager.get('requestSubmitted'), 'success');
            }
            ui.resetPurchaseRequestForm();
            ui.showView('overview');
            await loadDashboardData();

        } catch (error) {
            console.error('Submit error:', error);
            ui.showNotification(i18nManager.get('errorSubmit') + error.message, 'error');
        } finally {
            ui.setLoading(false);
        }
    });

    // View Details (Event delegation)
    document.addEventListener('click', async (e) => {
        if (e.target.classList.contains('view-details-btn')) {
            const requestId = e.target.dataset.id;
            await showRequestDetails(requestId);
        }
        if (e.target.classList.contains('view-expense-details-btn')) {
            const expenseId = e.target.dataset.id;
            await showExpenseDetails(expenseId);
        }
    });

    // Expense Request Form Submission
    document.getElementById('expenseRequestForm')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        ui.setLoading(true);

        try {
            const formData = new FormData(e.target);
            const editId = formData.get('edit_expense_id');
            const expenseData = {
                subject: formData.get('subject'),
                amount: Number.parseFloat(formData.get('amount')),
                highest_approval_level: formData.get('highest_approval_level'),
                statement: formData.get('statement'),
                status: 'pending',
                employee_id: currentUser.id,
                employee_name: currentUser.profile.full_name
            };

            if (editId) {
                await db.updateExpenseFull(editId, expenseData);
                ui.showNotification(i18nManager.get('requestUpdated'), 'success');
            } else {
                await db.createExpenseRequest(expenseData);
                ui.showNotification(i18nManager.get('requestSubmitted'), 'success');
            }
            ui.resetExpenseRequestForm();
            ui.showView('expense-requests');
            await loadDashboardData();

        } catch (error) {
            console.error('Expense submit error:', error);
            ui.showNotification(i18nManager.get('errorSubmit') + error.message, 'error');
        } finally {
            ui.setLoading(false);
        }
    });
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

async function showRequestDetails(requestId) {
    ui.setLoading(true);
    try {
        // Fetch full request details
        const { data: req, error } = await supabaseClient
            .from('purchase_requests')
            .select(`
                *,
                profiles:created_by (full_name, role, job_title, department),
                request_items (*)
            `)
            .eq('id', requestId)
            .single();

        if (error) throw error;

        // Fetch approvals log with profile data
        const { data: approvals } = await supabaseClient
            .from('approvals_log')
            .select('*, profiles:user_id (full_name, role, job_title)')
            .eq('request_id', requestId)
            .order('created_at', { ascending: true });

        const container = document.getElementById('detailsContent');
        const role = currentUser.profile.role;
        const statusClass = `badge-${req.status}`;
        
        let actionsHtml = '';
        
        // 1. Manager Step: pending -> manager_approved
        if (role === 'manager' && (req.status === 'pending' || req.status === 'rejected_by_manager')) {
            actionsHtml = `
                <div class="card mt-4 border-primary">
                    <div class="card-header bg-primary text-white">${i18nManager.get('managerApproval')}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-success action-btn" data-action="manager_approved">${i18nManager.get('approve')}</button>
                        <button class="btn btn-danger action-btn" data-action="rejected_by_manager">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        } 
        // 2. IT/Procurement Step: manager_approved -> it_approved
        else if (role === 'it_procurement' && (req.status === 'manager_approved' || req.status === 'rejected_by_it')) {
            actionsHtml = `
                <div class="card mt-4 border-info">
                    <div class="card-header bg-info text-white">${i18nManager.get('itProcurementReview')}</div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label fw-bold">${i18nManager.get('suggestedSuppliers')}</label>
                            <textarea id="suggestedSuppliers" class="form-control" rows="3" placeholder="${i18nManager.get('suppliersPlaceholder')}">${req.suggested_suppliers || ''}</textarea>
                        </div>
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-success action-btn" data-action="it_approved">${i18nManager.get('approveToFinance')}</button>
                        <button class="btn btn-danger action-btn" data-action="rejected_by_it">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        } 
        // 3. Finance Step: it_approved -> finance_approved
        else if (role === 'finance' && (req.status === 'it_approved' || req.status === 'rejected_by_finance')) {
            actionsHtml = `
                <div class="card mt-4 border-success">
                    <div class="card-header bg-success text-white">${i18nManager.get('financeApproval')}</div>
                    <div class="card-body">
                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label class="form-label">${i18nManager.get('budgetLine')}</label>
                                <input type="text" id="budget_line" class="form-control" value="${req.budget_line_item || ''}">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">${i18nManager.get('commitmentNo')}</label>
                                <input type="text" id="commitment_no" class="form-control" value="${req.commitment_number || ''}">
                            </div>
                        </div>
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('amountInWords')}"></textarea>
                        <button class="btn btn-primary action-btn" data-action="finance_approved">${i18nManager.get('approveAndFund')}</button>
                        <button class="btn btn-danger action-btn" data-action="rejected_by_finance">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        } 
        // 4. Final IT/Procurement Step: finance_approved -> completed
        else if ((role === 'it_procurement' || role === 'admin') && (req.status === 'finance_approved' || req.status === 'rejected_by_it_purchase')) {
            actionsHtml = `
                <div class="card mt-4 border-primary">
                    <div class="card-header bg-primary text-white">${i18nManager.get('markAsPurchased')}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-primary action-btn" data-action="purchased">${i18nManager.get('markAsPurchased')}</button>
                        <button class="btn btn-danger action-btn" data-action="rejected_by_it_purchase">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        }
        // 5. Staff Receipt Step: purchased -> received_by_staff
        else if ((req.status === 'purchased' || req.status === 'rejected_by_staff') && currentUser.id === req.created_by) {
            actionsHtml = `
                <div class="card mt-4 border-warning">
                    <div class="card-header bg-warning text-dark fw-bold">${i18nManager.get('staffReceipt')}</div>
                    <div class="card-body">
                        <div class="row g-3 mb-3">
                            <div class="col-md-6 text-muted small">
                                <strong>${i18nManager.get('requester')}:</strong> ${currentUser.profile.full_name}<br>
                                <strong>${i18nManager.get('jobTitle')}:</strong> ${currentUser.profile.job_title || '-'}<br>
                                <strong>${i18nManager.get('department')}:</strong> ${currentUser.profile.department || '-'}
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">${i18nManager.get('rejectionReasons')}</label>
                            <textarea id="staffRejectionReason" class="form-control" rows="2"></textarea>
                        </div>
                        <div class="d-flex gap-2">
                            <button class="btn btn-success receipt-action-btn" data-action="accepted">
                                <i data-lucide="check-circle" style="width:18px;"></i> ${i18nManager.get('acceptReceipt')}
                            </button>
                            <button class="btn btn-outline-danger receipt-action-btn" data-action="rejected">
                                <i data-lucide="x-circle" style="width:18px;"></i> ${i18nManager.get('rejectReceipt')}
                            </button>
                        </div>
                    </div>
                </div>
            `;
        }
        // 6. IT Final Completion: received_by_staff OR rejected_by_staff -> completed
        else if ((role === 'it_procurement' || role === 'admin') && (req.status === 'received_by_staff' || req.status === 'rejected_by_staff')) {
            const isRejectedByStaff = req.status === 'rejected_by_staff';
            const acceptanceStatus = i18nManager.get(req.staff_acceptance_status === 'accepted' ? 'staffAccepted' : 'staffRejected');
            const acceptanceClass = req.staff_acceptance_status === 'accepted' ? 'text-success' : 'text-danger';
            
            actionsHtml = `
                <div class="card mt-4 border-dark">
                    <div class="card-header bg-dark text-white">${i18nManager.get('completeRequest')}</div>
                    <div class="card-body">
                        <div class="mb-3">
                            <h6 class="fw-bold ${acceptanceClass}">${acceptanceStatus}</h6>
                            ${req.staff_rejection_reason ? `<p class="border p-2 bg-light small"><strong>${i18nManager.get('rejectionReasons')}:</strong> ${req.staff_rejection_reason}</p>` : ''}
                        </div>
                        ${isRejectedByStaff ? `
                            <div class="alert alert-warning small">
                                ${i18nManager.get('cannotCompleteStaffRejected')}
                            </div>
                        ` : `
                            <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                            <button class="btn btn-dark action-btn" data-action="completed">${i18nManager.get('completeRequest')}</button>
                        `}
                    </div>
                </div>
            `;
        }

        container.innerHTML = `
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">${i18nManager.get('requestDetails')} #${req.id.substring(0, 8)}</h5>
                    <div class="d-flex gap-2">
                        ${currentUser.id === req.created_by && req.status !== 'completed' ? `
                            <button class="btn btn-sm btn-outline-primary" id="editRequestBtn">
                                <i data-lucide="edit" style="width:14px;"></i> ${i18nManager.get('editRequest')}
                            </button>
                        ` : ''}
                        <button class="btn btn-sm btn-outline-info" id="printRequestBtn">
                            <i data-lucide="printer" style="width:14px;"></i> ${i18nManager.get('printRequest')}
                        </button>
                        ${['purchased', 'received_by_staff', 'rejected_by_staff', 'completed'].includes(req.status) ? `
                            <button class="btn btn-sm btn-outline-success" id="printReceiptBtn">
                                <i data-lucide="printer" style="width:14px;"></i> ${i18nManager.get('printReceipt')}
                            </button>
                        ` : ''}
                        <button class="btn btn-sm btn-outline-secondary" onclick="ui.showView('overview')">${i18nManager.get('closing')}</button>
                    </div>
                </div>
                <div class="card-body">
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('subject').toUpperCase()}</h6>
                            <p class="h5 fw-bold">${req.subject}</p>
                            <h6 class="text-muted small fw-bold mt-3">${i18nManager.get('justification').split('(')[0].trim().toUpperCase()}</h6>
                            <p>${req.justification || i18nManager.get('noJustification')}</p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('requester').toUpperCase()}</h6>
                            <p>${(req.profiles && req.profiles.full_name) ? req.profiles.full_name : (req.requested_by_name || i18nManager.get('staff'))}<br>
                               <small class="text-muted">${req.profiles ? i18nManager.get(req.profiles.role) : ''} | ${req.profiles ? req.profiles.department : ''}</small></p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('status').toUpperCase()}</h6>
                            <span class="badge ${statusClass}">${i18nManager.get(req.status).toUpperCase()}</span>
                            <h6 class="text-muted small fw-bold mt-2">${i18nManager.get('totalPrice').toUpperCase()}</h6>
                            <p class="h5 fw-bold text-primary">${(req.total_amount || 0).toFixed(2)} AED</p>
                        </div>
                    </div>
                    
                    <!-- NEW: Receipt Info Section (if processed) -->
                    ${['received_by_staff', 'rejected_by_staff', 'completed'].includes(req.status) ? `
                    <div class="mb-4 p-3 border rounded bg-light">
                         <h6 class="text-muted small fw-bold mb-2">${i18nManager.get('staffReceipt').toUpperCase()}</h6>
                         <div class="row">
                             <div class="col-md-6">
                                 <span class="badge ${req.staff_acceptance_status === 'accepted' ? 'bg-success' : 'bg-danger'} mb-2">
                                     ${i18nManager.get(req.staff_acceptance_status === 'accepted' ? 'staffAccepted' : 'staffRejected')}
                                 </span>
                                 ${req.staff_rejection_reason ? `<div class="mt-1 small"><strong>${i18nManager.get('rejectionReasons')}:</strong> ${req.staff_rejection_reason}</div>` : ''}
                             </div>
                             <div class="col-md-6 text-end">
                                 <small class="text-muted">${req.staff_receiving_date ? new Date(req.staff_receiving_date).toLocaleString() : ''}</small>
                             </div>
                         </div>
                    </div>
                    ` : ''}

                    <!-- Audit Trail / Previous Notes -->
                    <div class="mb-4">
                        <h6 class="text-muted small fw-bold">${i18nManager.get('approvalLog').toUpperCase()}</h6>
                        <div class="list-group list-group-flush border rounded">
                            ${approvals && approvals.length > 0 ? approvals.map(app => `
                                <div class="list-group-item">
                                    <div class="d-flex justify-content-between">
                                        <span class="fw-bold text-dark">${app.profiles?.full_name || 'System'}</span>
                                        <small class="text-muted">${new Date(app.created_at).toLocaleString(i18nManager.currentLang === 'ar' ? 'ar-SA' : 'en-US')}</small>
                                    </div>
                                    <div class="small">
                                        <span class="badge ${app.action.includes('rejected') ? 'bg-danger' : 'bg-success'} me-2">
                                            ${i18nManager.get(app.action) || app.action}
                                        </span>
                                        <span class="text-secondary italic">${app.comments || i18nManager.get('noComments')}</span>
                                    </div>
                                </div>
                            `).join('') : `<div class="list-group-item text-muted small">${i18nManager.get('noLogEntries')}</div>`}
                        </div>
                    </div>

                    <table class="table table-sm table-bordered">
                        <thead class="bg-light">
                            <tr>
                                <th>${i18nManager.get('category')}</th>
                                <th>${i18nManager.get('itemDescription')}</th>
                                <th>${i18nManager.get('specs')}</th>
                                <th>${i18nManager.get('unit')}</th>
                                <th>${i18nManager.get('qty')}</th>
                                <th>${i18nManager.get('price')}</th>
                                <th>${i18nManager.get('total')}</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${req.request_items.map(item => {
                                const isApprover = (role === 'manager' || role === 'it_procurement' || role === 'admin');
                                const canEditProduct = isApprover && req.status !== 'completed' && req.status !== 'purchased';
                                
                                return `
                                    <tr data-item-id="${item.id}">
                                        <td>
                                            ${canEditProduct ? `
                                                <select class="form-select form-select-sm detail-category-select">
                                                    <option value="">--</option>
                                                    ${globalCategories.map(c => `<option value="${c.id}" ${item.category_id === c.id ? 'selected' : ''}>${c.name}</option>`).join('')}
                                                </select>
                                            ` : (globalCategories.find(c => c.id === item.category_id)?.name || '-')}
                                        </td>
                                        <td>
                                            ${canEditProduct ? `
                                                <div class="position-relative">
                                                    <input type="text" class="form-control form-control-sm detail-product-search" value="${item.product_name}" autocomplete="off">
                                                    <input type="hidden" class="detail-product-id" value="${item.product_id || ''}">
                                                    <div class="product-results dropdown-menu w-100"></div>
                                                </div>
                                            ` : item.product_name}
                                        </td>
                                        <td>${item.specifications || '-'}</td>
                                        <td>${item.unit}</td>
                                        <td>${item.quantity}</td>
                                        <td>${item.unit_price.toFixed(2)}</td>
                                        <td>${(item.quantity * item.unit_price).toFixed(2)}</td>
                                    </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>

                    ${actionsHtml}
                </div>
            </div>
        `;
        ui.showView('request-details');

        // Handle Print Buttons
        document.getElementById('printRequestBtn')?.addEventListener('click', () => {
            ui.printRequest(req, approvals || []);
        });

        document.getElementById('printReceiptBtn')?.addEventListener('click', () => {
            ui.printReceipt(req, approvals || []);
        });

        document.getElementById('editRequestBtn')?.addEventListener('click', () => {
            ui.loadRequestForEdit(req);
        });

        // Handle action buttons
        container.querySelectorAll('.action-btn').forEach(btn => {
            btn.addEventListener('click', async () => {
                const action = btn.dataset.action;
                const comments = document.getElementById('actionComments').value;
                const updates = {};
                
                if (action === 'it_approved') {
                    const suggestedSuppliers = document.getElementById('suggestedSuppliers')?.value || '';
                    if (suggestedSuppliers) {
                        updates.suggested_suppliers = suggestedSuppliers;
                    }
                }

                if (action === 'finance_approved') {
                    updates.budget_line_item = document.getElementById('budget_line').value;
                    updates.commitment_number = document.getElementById('commitment_no').value;
                    updates.amount_in_words = comments;
                }

                ui.setLoading(true);
                try {
                    await db.updateRequestStatus(requestId, action, updates);
                    await db.logApproval(requestId, currentUser.id, action, comments);
                    ui.showNotification(i18nManager.get('requestProcessed'), 'success');
                    ui.showView('overview');
                    await loadDashboardData();
                } catch (e) {
                    ui.showNotification(i18nManager.get('error') + e.message, 'error');
                } finally {
                    ui.setLoading(false);
                }
            });
        });

        // Handle Receipt Specific branch (Staff)
        container.querySelectorAll('.receipt-action-btn').forEach(btn => {
            btn.addEventListener('click', async () => {
                const acceptanceStatus = btn.dataset.action; // 'accepted' or 'rejected'
                const reason = document.getElementById('staffRejectionReason').value;
                
                if (acceptanceStatus === 'rejected' && !reason) {
                    ui.showNotification(i18nManager.get('errorRejectionReason'), 'warning');
                    return;
                }

                ui.setLoading(true);
                try {
                    const updates = {
                        staff_acceptance_status: acceptanceStatus,
                        staff_rejection_reason: reason,
                        staff_receiving_date: new Date()
                    };
                    const targetStatus = acceptanceStatus === 'accepted' ? 'received_by_staff' : 'rejected_by_staff';
                    const actionLog = acceptanceStatus === 'accepted' ? 'staff_accepted' : 'staff_rejected';
                    
                    await db.updateRequestStatus(requestId, targetStatus, updates);
                    await db.logApproval(requestId, currentUser.id, actionLog, reason);
                    
                    ui.showNotification(i18nManager.get('requestSubmitted'), 'success');
                    ui.showView('overview');
                    await loadDashboardData();
                } catch (e) {
                    ui.showNotification(i18nManager.get('error') + e.message, 'error');
                } finally {
                    ui.setLoading(false);
                }
            });
        });

        // Handle Inline Product/Category Changes in Details
        container.querySelectorAll('.detail-category-select, .detail-product-search').forEach(el => {
            el.addEventListener('change', async (e) => {
                const tr = e.target.closest('tr');
                const itemId = tr.dataset.itemId;
                const catId = tr.querySelector('.detail-category-select')?.value;
                const prodId = tr.querySelector('.detail-product-id')?.value;
                const prodName = tr.querySelector('.detail-product-search')?.value;

                try {
                    const { error } = await supabaseClient.from('request_items').update({
                        category_id: catId || null,
                        product_id: prodId || null,
                        product_name: prodName
                    }).eq('id', itemId);
                    
                    if (error) throw error;

                    // Log the change
                    await db.logApproval(requestId, currentUser.id, 'item_updated', `Item updated: ${prodName} (ID: ${prodId || 'New'})`);
                    ui.showNotification(i18nManager.get('requestUpdated') || 'Item updated', 'success');
                } catch (err) {
                    console.error("Update item error:", err);
                    ui.showNotification('Update failed: ' + err.message, 'error');
                }
            });
        });

        // Also add search behavior for detail-product-search
        container.querySelectorAll('.detail-product-search').forEach(searchInput => {
            searchInput.addEventListener('input', async (e) => {
                const queryText = searchInput.value.trim();
                const tr = searchInput.closest('tr');
                const catIdSelect = tr.querySelector('.detail-category-select');
                if (!catIdSelect) return;
                const catId = catIdSelect.value;
                const resultsDiv = tr.querySelector('.product-results');

                if (!catId || !resultsDiv) return;
                if (queryText.length < 2) { resultsDiv.classList.remove('show'); return; }

                const { data } = await supabaseClient.from('products')
                    .select('*')
                    .eq('category_id', catId)
                    .ilike('name', `%${queryText}%`)
                    .limit(5);

                resultsDiv.innerHTML = '';
                if (data && data.length > 0) {
                    data.forEach(p => {
                        const item = document.createElement('a');
                        item.className = 'dropdown-item';
                        item.href = '#';
                        item.innerText = p.name;
                        item.addEventListener('click', (ev) => {
                            ev.preventDefault();
                            searchInput.value = p.name;
                            tr.querySelector('.detail-product-id').value = p.id;
                            resultsDiv.classList.remove('show');
                            // Trigger change manually
                            searchInput.dispatchEvent(new Event('change'));
                        });
                        resultsDiv.appendChild(item);
                    });
                    resultsDiv.classList.add('show');
                }
            });
        });

    } catch (e) {
        console.error(e);
        ui.showNotification(i18nManager.get('errorLoadingDetails'), 'error');
    } finally {
        ui.setLoading(false);
    }
}

async function handleProfileDelete(id) {
    ui.setLoading(true);
    try {
        await db.deleteProfile(id);
        await loadDashboardData();
    } catch (error) {
        ui.showNotification(i18nManager.get('errorDeleteProfile') + error.message, 'error');
    } finally {
        ui.setLoading(false);
    }
}

async function showExpenseDetails(expenseId) {
    ui.setLoading(true);
    try {
        const { data: exp, error } = await supabaseClient
            .from('expense_requests')
            .select('*, profiles:employee_id (full_name, role, job_title, department)')
            .eq('id', expenseId)
            .single();

        if (error) throw error;

        const { data: approvals } = await supabaseClient
            .from('expense_approvals_log')
            .select('*, profiles:user_id (full_name, role)')
            .eq('request_id', expenseId)
            .order('created_at', { ascending: true });

        const container = document.getElementById('detailsContent');
        const role = currentUser.profile.role;
        const statusClass = `badge-${exp.status}`;
        
        let actionsHtml = '';
        const level = exp.highest_approval_level;

        // 1. Manager Approval
        if (role === 'manager' && (exp.status === 'pending' || exp.status === 'rejected_by_manager')) {
            actionsHtml = `
                <div class="card mt-4 border-primary">
                    <div class="card-header bg-primary text-white">${i18nManager.get('managerApproval')}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-success expense-action-btn" data-action="manager_approved">${i18nManager.get('approve')}</button>
                        <button class="btn btn-danger expense-action-btn" data-action="rejected_by_manager">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        }
        // 2. Finance Approval
        else if (role === 'finance' && (exp.status === 'manager_approved' || exp.status === 'rejected_by_finance') && (level === 'finance' || level === 'general_manager')) {
            actionsHtml = `
                <div class="card mt-4 border-success">
                    <div class="card-header bg-success text-white">${i18nManager.get('financeApproval')}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-primary expense-action-btn" data-action="finance_approved">${i18nManager.get('approve')}</button>
                        <button class="btn btn-danger expense-action-btn" data-action="rejected_by_finance">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        }
        // 3. GM Approval
        else if (role === 'general_manager' && (exp.status === 'finance_approved' || exp.status === 'rejected_by_gm') && level === 'general_manager') {
            actionsHtml = `
                <div class="card mt-4 border-dark">
                    <div class="card-header bg-dark text-white">${i18nManager.get('gmApproval')}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-dark expense-action-btn" data-action="gm_approved">${i18nManager.get('approve')}</button>
                        <button class="btn btn-danger expense-action-btn" data-action="rejected_by_gm">${i18nManager.get('rejected')}</button>
                    </div>
                </div>
            `;
        }
        // 4. Accountant Payment
        else if (role === 'accountant' && exp.status !== 'paid' && exp.status !== 'received' && exp.status !== 'completed') {
            const isReady = (level === 'manager' && exp.status === 'manager_approved') ||
                            (level === 'finance' && exp.status === 'finance_approved') ||
                            (level === 'general_manager' && exp.status === 'gm_approved');
            
            if (isReady) {
                actionsHtml = `
                    <div class="card mt-4 border-warning">
                        <div class="card-header bg-warning text-dark fw-bold">${i18nManager.get('payAmount')}</div>
                        <div class="card-body">
                            <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                            <button class="btn btn-warning expense-action-btn" data-action="paid">${i18nManager.get('payAmount')}</button>
                        </div>
                    </div>
                `;
            }
        }
        // 5. Staff Receipt
        else if (exp.status === 'paid' && currentUser.id === exp.employee_id) {
            actionsHtml = `
                <div class="card mt-4 border-success">
                    <div class="card-header bg-success text-white fw-bold">${i18nManager.get('receiveAmount')}</div>
                    <div class="card-body">
                        <p>${i18nManager.get('staffReceiptMsg')}</p>
                        <button class="btn btn-success expense-action-btn" data-action="received">${i18nManager.get('receiveAmount')}</button>
                    </div>
                </div>
            `;
        }

        container.innerHTML = `
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">${i18nManager.get('expenseRequests')} #${exp.id.substring(0, 8)}</h5>
                    <div class="d-flex gap-2">
                        ${currentUser.id === exp.employee_id && !['completed', 'paid'].includes(exp.status) ? `
                            <button class="btn btn-sm btn-outline-primary" id="editExpenseBtn">
                                <i data-lucide="edit" style="width:14px;"></i> ${i18nManager.get('editRequest')}
                            </button>
                        ` : ''}
                        <button class="btn btn-sm btn-outline-info" id="printExpenseRequestBtn">
                            <i data-lucide="printer" style="width:14px;"></i> ${i18nManager.get('printRequest')}
                        </button>
                        ${['paid', 'completed', 'received'].includes(exp.status) ? `
                            <button class="btn btn-sm btn-outline-success" id="printExpenseReceiptBtn">
                                <i data-lucide="printer" style="width:14px;"></i> ${i18nManager.get('printExpenseReceipt')}
                            </button>
                        ` : ''}
                        <button class="btn btn-sm btn-outline-secondary" onclick="resetAndBackToExpenses()">${i18nManager.get('closing')}</button>
                    </div>
                </div>
                <div class="card-body">
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('subject').toUpperCase()}</h6>
                            <p class="h5 fw-bold">${exp.subject}</p>
                            <h6 class="text-muted small fw-bold mt-3">${i18nManager.get('statement').toUpperCase()}</h6>
                            <p>${exp.statement}</p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('requester').toUpperCase()}</h6>
                            <p>${exp.employee_name}<br><small class="text-muted">${exp.profiles?.job_title || ''}</small></p>
                            <h6 class="text-muted small fw-bold mt-2">${i18nManager.get('approvalLevel').toUpperCase()}</h6>
                            <span class="badge bg-info">${i18nManager.get(exp.highest_approval_level).toUpperCase()}</span>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('status').toUpperCase()}</h6>
                            <span class="badge ${statusClass}">${i18nManager.get(exp.status).toUpperCase()}</span>
                            <h6 class="text-muted small fw-bold mt-2">${i18nManager.get('amount').toUpperCase()}</h6>
                            <p class="h5 fw-bold text-primary">${Number(exp.amount).toFixed(2)} AED</p>
                        </div>
                    </div>

                    <!-- Audit Log -->
                    <div class="mb-4">
                        <h6 class="text-muted small fw-bold">${i18nManager.get('approvalLog').toUpperCase()}</h6>
                        <div class="list-group list-group-flush border rounded">
                            ${approvals && approvals.length > 0 ? approvals.map(app => `
                                <div class="list-group-item">
                                    <div class="d-flex justify-content-between">
                                        <span class="fw-bold text-dark">${app.profiles?.full_name || 'System'}</span>
                                        <small class="text-muted">${new Date(app.created_at).toLocaleString()}</small>
                                    </div>
                                    <div class="small">
                                        <span class="badge ${app.action.includes('rejected') ? 'bg-danger' : 'bg-success'} me-2">
                                            ${i18nManager.get(app.action)}
                                        </span>
                                        <span class="text-secondary italic">${app.comments || ''}</span>
                                    </div>
                                </div>
                            `).join('') : `<div class="list-group-item text-muted small">${i18nManager.get('noApprovalsYet')}</div>`}
                        </div>
                    </div>

                    ${actionsHtml}
                </div>
            </div>
        `;
        ui.showView('request-details');

        // Handle Print Buttons for Expense
        document.getElementById('printExpenseRequestBtn')?.addEventListener('click', () => {
            ui.printExpenseRequest(exp, approvals || []);
        });

        document.getElementById('printExpenseReceiptBtn')?.addEventListener('click', () => {
            ui.printExpenseReceipt(exp, approvals || []);
        });

        document.getElementById('editExpenseBtn')?.addEventListener('click', () => {
            ui.loadExpenseForEdit(exp);
        });

        // Handle expense action buttons
        container.querySelectorAll('.expense-action-btn').forEach(btn => {
            btn.addEventListener('click', async () => {
                const action = btn.dataset.action;
                const comments = document.getElementById('actionComments')?.value || '';
                
                ui.setLoading(true);
                try {
                    let nextStatus = action;
                    if (action === 'received') nextStatus = 'completed';
                    
                    await db.updateExpenseStatus(expenseId, nextStatus);
                    await db.logExpenseApproval(expenseId, currentUser.id, action, comments);
                    
                    ui.showNotification(i18nManager.get('requestProcessed'), 'success');
                    ui.showView('expense-requests');
                    await loadDashboardData();
                } catch (e) {
                    ui.showNotification(i18nManager.get('error') + e.message, 'error');
                } finally {
                    ui.setLoading(false);
                }
            });
        });

    } catch (e) {
        console.error(e);
        ui.showNotification(i18nManager.get('errorLoadingDetails'), 'error');
    } finally {
        ui.setLoading(false);
    }
}

// Global helpers to reset and go back
function resetAndBackToExpenses() {
    ui.resetExpenseRequestForm();
    ui.showView('expense-requests');
}

function resetAndBackToPurchase() {
    ui.resetPurchaseRequestForm();
    ui.showView('overview');
}
