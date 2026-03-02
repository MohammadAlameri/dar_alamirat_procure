// Main App Controller
let currentUser = null;

document.addEventListener('DOMContentLoaded', async () => {
    // 1. Check Auth 
    ui.setLoading(true);
    try {
        const { data: { session } } = await supabase.auth.getSession();
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

    // Create New Request button
    document.getElementById('createNewBtn').addEventListener('click', () => {
        ui.showView('create-request');
    });

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
            alert('Request submitted successfully!');
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
        const { data: req, error } = await supabase
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
                    <div class="card-header bg-info text-white">IT / Procurement Review</div>
                    <div class="card-body">
                        <textarea id="actionComments" class="form-control mb-3" placeholder="Add comments..."></textarea>
                        <button class="btn btn-success action-btn" data-action="it_approved">Approve to Finance</button>
                        <button class="btn btn-danger action-btn" data-action="rejected">Reject</button>
                    </div>
                </div>
            `;
        } else if (role === 'finance' && req.status === 'it_approved') {
            actionsHtml = `
                <div class="card mt-4 border-success">
                    <div class="card-header bg-success text-white">Finance Approval</div>
                    <div class="card-body">
                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label class="form-label">Budget Line Item</label>
                                <input type="text" id="budget_line" class="form-control">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Commitment Number</label>
                                <input type="text" id="commitment_no" class="form-control">
                            </div>
                        </div>
                        <textarea id="actionComments" class="form-control mb-3" placeholder="Amount in words..."></textarea>
                        <button class="btn btn-primary action-btn" data-action="finance_approved">Approve & Fund</button>
                        <button class="btn btn-danger action-btn" data-action="rejected">Reject</button>
                    </div>
                </div>
            `;
        }

        container.innerHTML = `
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">Request Details #${req.id.substring(0, 8)}</h5>
                    <button class="btn btn-sm btn-outline-secondary" onclick="ui.showView('overview')">Close</button>
                </div>
                <div class="card-body">
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <h6 class="text-muted small fw-bold">SUBJECT</h6>
                            <p class="h5 fw-bold">${req.subject}</p>
                            <h6 class="text-muted small fw-bold mt-3">JUSTIFICATION</h6>
                            <p>${req.justification || 'No justification provided'}</p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">REQUESTER</h6>
                            <p>${req.profiles.full_name}<br><small class="text-muted">${req.profiles.job_title} | ${req.profiles.department}</small></p>
                        </div>
                        <div class="col-md-3">
                            <h6 class="text-muted small fw-bold">STATUS</h6>
                            <span class="badge ${statusClass}">${req.status.toUpperCase()}</span>
                            <h6 class="text-muted small fw-bold mt-2">TOTAL PRICE</h6>
                            <p class="h5 fw-bold text-primary">${req.total_amount.toFixed(2)} AED</p>
                        </div>
                    </div>

                    <table class="table table-sm table-bordered">
                        <thead class="bg-light">
                            <tr>
                                <th>Item Description</th>
                                <th>Specs</th>
                                <th>Unit</th>
                                <th>Qty</th>
                                <th>Price</th>
                                <th>Total</th>
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
