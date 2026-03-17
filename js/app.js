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

        // 2a. Load branch permissions
        await permissions.load(currentUser.id);
        ui.renderBranchSelector(permissions.getUserBranches(), permissions.getCurrentBranchId());

        // 2b. Initialize Dashboard Data
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
            if (viewId === 'branch-management' && currentUser?.profile?.role !== 'admin') {
                ui.showView('overview');
                return;
            }
            if (viewId === 'reports' && !['admin', 'it_procurement', 'finance', 'general_manager', 'manager', 'accountant'].includes(currentUser?.profile?.role)) {
                ui.showView('overview');
                return;
            }
            
            // Reset all form states when switching views to prevent "ghost" edits
            ui.resetPurchaseRequestForm();
            ui.resetExpenseRequestForm();
            const title = document.getElementById('currentViewTitle');
            if (title) title.innerText = i18nManager.get('dashboardOverview');

            ui.showView(viewId);

            // Special data loading for admin views
            if (viewId === 'branch-management') {
                loadBranchManagement();
            } else if (viewId === 'reports') {
                loadReportsView();
            }
            
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
                branch_id: permissions.getCurrentBranchId(),
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
                employee_name: currentUser.profile.full_name,
                branch_id: permissions.getCurrentBranchId()
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
