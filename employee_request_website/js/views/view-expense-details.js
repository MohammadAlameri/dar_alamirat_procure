// Expense Details View
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
                            <h6 class="text-muted small fw-bold mt-3">${i18nManager.get('branch').toUpperCase()}</h6>
                            <p class="fw-bold text-dark">${branchName}</p>
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
