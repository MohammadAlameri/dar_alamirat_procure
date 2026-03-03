// Main App Controller
let currentUser = null;

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
            alert('User profile not found. Please contact admin.');
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
});

async function loadDashboardData() {
    const role = currentUser.profile.role;
    let requests = [];

    if (role === 'employee') {
        requests = await db.getRequests({ userId: currentUser.id });
    } else {
        requests = await db.getRequests();
    }

    // Update stats
    document.getElementById('stat-total').innerText = requests.length;
    document.getElementById('stat-pending').innerText = requests.filter(r => r.status === 'pending').length;
    document.getElementById('stat-approved').innerText = requests.filter(r => r.status === 'finance_approved').length;
    document.getElementById('stat-rejected').innerText = requests.filter(r => r.status === 'rejected').length;

    // Render tables
    ui.renderRequestsTable('recentRequestsTable', requests.slice(0, 5), role);
    ui.renderRequestsTable('myRequestsTable', requests.filter(r => r.created_by === currentUser.id), role);
    
    if (role === 'it_procurement') {
        ui.renderRequestsTable('pendingApprovalsTable', requests.filter(r => r.status === 'pending'), role);
    } else if (role === 'finance') {
        ui.renderRequestsTable('pendingApprovalsTable', requests.filter(r => r.status === 'it_approved'), role);
    }

    // New: Render All Requests Table
    if (role === 'it_procurement' || role === 'finance' || role === 'admin') {
        ui.renderRequestsTable('allRequestsTable', requests, role);
    }

    // New: Handle Profiles Table for Admin
    if (role === 'admin') {
        try {
            const profiles = await db.getAllProfiles();
            // Filter out any admin role profiles just in case
            ui.renderProfilesTable(profiles.filter(p => p.role !== 'admin'));
        } catch (error) {
            console.error('Error loading profiles:', error);
        }
    }
}

function setupEventListeners() {
    // Sidebar navigation
    document.querySelectorAll('#sidebar .nav-link:not(#logoutBtn)').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const viewId = link.dataset.view;
            ui.showView(viewId);
        });
    });

    // Sidebar Toggle
    document.getElementById('sidebarToggle')?.addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('show');
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

    // Buttons
    document.getElementById('createNewBtn').addEventListener('click', () => ui.showView('create-request'));
    document.getElementById('showCreateProfileBtn')?.addEventListener('click', () => ui.toggleProfileForm(true));
    document.getElementById('cancelProfileBtn')?.addEventListener('click', () => ui.toggleProfileForm(false));

    // Password Toggle
    document.getElementById('togglePassword')?.addEventListener('click', () => {
        const passwordInput = document.getElementById('password');
        const icon = document.querySelector('#togglePassword i');
        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            icon.dataset.lucide = 'eye-off';
        } else {
            passwordInput.type = 'password';
            icon.dataset.lucide = 'eye';
        }
        lucide.createIcons();
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
            document.getElementById('passwordHint').classList.remove('d-none');
            document.getElementById('password').required = false;
            document.getElementById('profileFormTitle').innerText = 'Edit Profile';
        }

        if (deleteBtn) {
            const { id, name } = deleteBtn.dataset;
            if (confirm(`Are you sure you want to delete profile for ${name}?`)) {
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

                if (profileId) {
                    // Update
                    await db.updateProfile(profileId, { full_name: fullName, role, job_title: jobTitle, department });
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
                            department
                        });
                    }
                }

                if (alertDiv) {
                    alertDiv.className = 'alert alert-success';
                    alertDiv.innerText = i18nManager.get('profileCreated') || 'Action completed successfully!';
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
                    alertDiv.innerText = 'Error: ' + error.message;
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
                status: 'pending',
                created_by: currentUser.id,
                total_amount: Number.parseFloat(document.getElementById('grandTotal').value)
            };

            const items = [];
            const productNames = formData.getAll('product_name[]');
            const specs = formData.getAll('specifications[]');
            const units = formData.getAll('unit[]');
            const qties = formData.getAll('quantity[]');
            const prices = formData.getAll('unit_price[]');

            for (let i = 0; i < productNames.length; i++) {
                items.push({
                    product_name: productNames[i],
                    specifications: specs[i],
                    unit: units[i],
                    quantity: Number.parseInt(qties[i]),
                    unit_price: Number.parseFloat(prices[i])
                });
            }

            await db.createRequest(requestData, items);
            alert(i18nManager.get('requestSubmitted') || 'Request submitted successfully!');
            e.target.reset();
            ui.showView('overview');
            await loadDashboardData();

        } catch (error) {
            console.error('Submit error:', error);
            alert('Error submitting request: ' + error.message);
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
    });
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

        const container = document.getElementById('detailsContent');
        const role = currentUser.profile.role;
        const statusClass = `badge-${req.status}`;
        
        let actionsHtml = '';
        if (role === 'it_procurement' && req.status === 'pending') {
            actionsHtml = `
                <div class="card mt-4 border-info">
                    <div class="card-header bg-info text-white">${i18nManager.get('itProcurementReview') || 'IT / Procurement Review'}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments') || 'Add comments...'}"></textarea>
                        <button class="btn btn-success action-btn" data-action="it_approved">${i18nManager.get('approveToFinance') || 'Approve to Finance'}</button>
                        <button class="btn btn-danger action-btn" data-action="rejected">${i18nManager.get('rejected') || 'Reject'}</button>
                    </div>
                </div>
            `;
        } else if (role === 'finance' && req.status === 'it_approved') {
            actionsHtml = `
                <div class="card mt-4 border-success">
                    <div class="card-header bg-success text-white">${i18nManager.get('financeApproval') || 'Finance Approval'}</div>
                    <div class="card-body">
                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label class="form-label">${i18nManager.get('budgetLine') || 'Budget Line Item'}</label>
                                <input type="text" id="budget_line" class="form-control">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">${i18nManager.get('commitmentNo') || 'Commitment Number'}</label>
                                <input type="text" id="commitment_no" class="form-control">
                            </div>
                        </div>
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('amountInWords') || 'Amount in words...'}"></textarea>
                        <button class="btn btn-primary action-btn" data-action="finance_approved">${i18nManager.get('approveAndFund') || 'Approve & Fund'}</button>
                        <button class="btn btn-danger action-btn" data-action="rejected">${i18nManager.get('rejected') || 'Reject'}</button>
                    </div>
                </div>
            `;
        } else if ((role === 'it_procurement' || role === 'admin') && req.status === 'finance_approved') {
            actionsHtml = `
                <div class="card mt-4 border-primary">
                    <div class="card-header bg-primary text-white">${i18nManager.get('markAsPurchased')}</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="${i18nManager.get('addComments')}"></textarea>
                        <button class="btn btn-primary action-btn" data-action="completed">${i18nManager.get('markAsPurchased')}</button>
                    </div>
                </div>
            `;
        }

        container.innerHTML = `
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">${i18nManager.get('requestDetails')} #${req.id.substring(0, 8)}</h5>
                    <button class="btn btn-sm btn-outline-secondary" onclick="ui.showView('overview')">${i18nManager.get('closing')}</button>
                </div>
                <div class="card-body">
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('subject').toUpperCase()}</h6>
                            <p class="h5 fw-bold">${req.subject}</p>
                            <h6 class="text-muted small fw-bold mt-3">${i18nManager.get('justification').split('(')[0].trim().toUpperCase()}</h6>
                            <p>${req.justification || 'No justification provided'}</p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('requester').toUpperCase()}</h6>
                            <p>${req.profiles.full_name}<br><small class="text-muted">${i18nManager.get(req.profiles.role)} | ${req.profiles.department || ''}</small></p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">${i18nManager.get('status').toUpperCase()}</h6>
                            <span class="badge ${statusClass}">${i18nManager.get(req.status).toUpperCase()}</span>
                            <h6 class="text-muted small fw-bold mt-2">${i18nManager.get('totalPrice').toUpperCase()}</h6>
                            <p class="h5 fw-bold text-primary">${req.total_amount.toFixed(2)} AED</p>
                        </div>
                    </div>

                    <table class="table table-sm table-bordered">
                        <thead class="bg-light">
                            <tr>
                                <th>${i18nManager.get('itemDescription')}</th>
                                <th>${i18nManager.get('specs')}</th>
                                <th>${i18nManager.get('unit')}</th>
                                <th>${i18nManager.get('qty')}</th>
                                <th>${i18nManager.get('price')}</th>
                                <th>${i18nManager.get('total')}</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${req.request_items.map(item => `
                                <tr>
                                    <td>${item.product_name}</td>
                                    <td>${item.specifications || '-'}</td>
                                    <td>${item.unit}</td>
                                    <td>${item.quantity}</td>
                                    <td>${item.unit_price.toFixed(2)}</td>
                                    <td>${(item.quantity * item.unit_price).toFixed(2)}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>

                    ${actionsHtml}
                </div>
            </div>
        `;
        ui.showView('overview'); // This is a bug in the code, should be request-details? No, showView handles it.
        ui.showView('request-details');

        // Handle action buttons
        container.querySelectorAll('.action-btn').forEach(btn => {
            btn.addEventListener('click', async () => {
                const action = btn.dataset.action;
                const comments = document.getElementById('actionComments').value;
                const updates = {};
                
                if (action === 'finance_approved') {
                    updates.budget_line_item = document.getElementById('budget_line').value;
                    updates.commitment_number = document.getElementById('commitment_no').value;
                    updates.amount_in_words = comments;
                }

                ui.setLoading(true);
                try {
                    await db.updateRequestStatus(requestId, action, updates);
                    await db.logApproval(requestId, currentUser.id, action, comments);
                    alert(`Request ${action.replace('_', ' ')}!`);
                    ui.showView('overview');
                    await loadDashboardData();
                } catch (e) {
                    alert('Error: ' + e.message);
                } finally {
                    ui.setLoading(false);
                }
            });
        });

    } catch (e) {
        console.error(e);
        alert('Error loading details');
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
        alert('Error deleting profile: ' + error.message);
    } finally {
        ui.setLoading(false);
    }
}
