// Request Details View
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
        const canApprove = permissions.canApprove(req.branch_id);
        
        // Only show approval actions if user has 'full' access to the branch
        if (canApprove) {
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
        }

        // 5. Staff Receipt Step: purchased -> received_by_staff (Always allowed for the creator)
        if ((req.status === 'purchased' || req.status === 'rejected_by_staff') && currentUser.id === req.created_by) {
            actionsHtml += `
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

        // Fetch Branch name
        let branchName = i18nManager.get('unknown');
        if (req.branch_id) {
            const { data: branch } = await supabaseClient.from('branches').select('name, name_ar').eq('id', req.branch_id).single();
            if (branch) branchName = (i18nManager.currentLang === 'ar' ? (branch.name_ar || branch.name) : branch.name);
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
                            ${canApprove && req.status !== 'completed' && req.status !== 'purchased' ? `
                                <input type="text" id="detail-subject" class="form-control form-control-sm h5 fw-bold mb-3" value="${req.subject}">
                            ` : `<p class="h5 fw-bold">${req.subject}</p>`}
                            
                            <h6 class="text-muted small fw-bold mt-3">${i18nManager.get('branch').toUpperCase()}</h6>
                            <p class="fw-bold text-dark">${branchName}</p>
                            
                            <h6 class="text-muted small fw-bold mt-3">${i18nManager.get('justification').split('(')[0].trim().toUpperCase()}</h6>
                            ${canApprove && req.status !== 'completed' && req.status !== 'purchased' ? `
                                <textarea id="detail-justification" class="form-control form-control-sm mb-3" rows="3">${req.justification || ''}</textarea>
                            ` : `<p>${req.justification || i18nManager.get('noJustification')}</p>`}
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
                            <p class="h5 fw-bold text-primary">${(req.total_amount || 0).toFixed(2)} SAR</p>
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
                            ${approvals && approvals.length > 0 ? approvals.map(app => {
                                // Clean up comments to remove sensitive IDs if they exist (historical data)
                                let displayComments = app.comments || i18nManager.get('noComments');
                                if (typeof displayComments === 'string') {
                                    displayComments = displayComments.replace(/\(ID:\s*[a-f0-9-]+\)/gi, '').trim();
                                }
                                
                                return `
                                    <div class="list-group-item">
                                        <div class="d-flex justify-content-between">
                                            <span class="fw-bold text-dark">${app.profiles?.full_name || 'System'}</span>
                                            <small class="text-muted">${new Date(app.created_at).toLocaleString(i18nManager.currentLang === 'ar' ? 'ar-SA' : 'en-US')}</small>
                                        </div>
                                        <div class="small">
                                            <span class="badge ${app.action.includes('rejected') ? 'bg-danger' : 'bg-success'} me-2">
                                                ${i18nManager.get(app.action) || app.action}
                                            </span>
                                            <span class="text-secondary italic">${displayComments}</span>
                                        </div>
                                    </div>
                                `;
                            }).join('') : `<div class="list-group-item text-muted small">${i18nManager.get('noLogEntries')}</div>`}
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
                                    <tr data-item-id="${item.id}" class="request-item-row">
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
                                        <td>
                                            ${canEditProduct ? `
                                                <input type="text" class="form-control form-control-sm detail-specs" value="${item.specifications || ''}">
                                            ` : (item.specifications || '-')}
                                        </td>
                                        <td>
                                            ${canEditProduct ? `
                                                <input type="text" class="form-control form-control-sm detail-unit" value="${item.unit || ''}">
                                            ` : item.unit}
                                        </td>
                                        <td>
                                            ${canEditProduct ? `
                                                <input type="number" class="form-control form-control-sm detail-qty" value="${item.quantity}" min="1">
                                            ` : item.quantity}
                                        </td>
                                        <td>
                                            ${canEditProduct ? `
                                                <input type="number" step="0.01" class="form-control form-control-sm detail-price" value="${item.unit_price.toFixed(2)}">
                                            ` : item.unit_price.toFixed(2)}
                                        </td>
                                        <td class="detail-row-total">${(item.quantity * item.unit_price).toFixed(2)}</td>
                                    </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>

                    ${actionsHtml}
                </div>
            </div>
        `;
        // Track changes for logging
        const changedItemIds = new Set();
        let mainFieldsModified = false;

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

        container.querySelectorAll('.action-btn').forEach(btn => {
            btn.addEventListener('click', async () => {
                const action = btn.dataset.action;
                const comments = document.getElementById('actionComments').value;
                const updates = {};
                
                ui.setLoading(true);
                try {
                    // 1. Update main request fields if they have inputs
                    const subjectIn = document.getElementById('detail-subject');
                    const justificationIn = document.getElementById('detail-justification');
                    if (subjectIn) updates.subject = subjectIn.value;
                    if (justificationIn) updates.justification = justificationIn.value;

                    // 2. Update items (collect all data first)
                    const itemRows = container.querySelectorAll('.request-item-row');
                    const itemsToUpdate = [];
                    let newGrandTotal = 0;
                    
                    for (const row of itemRows) {
                        const itemId = row.dataset.itemId;
                        const catInput = row.querySelector('.detail-category-select');
                        
                        if (catInput) {
                            const qty = parseFloat(row.querySelector('.detail-qty').value) || 0;
                            const price = parseFloat(row.querySelector('.detail-price').value) || 0;
                            newGrandTotal += (qty * price);

                            itemsToUpdate.push({
                                id: itemId,
                                request_id: requestId,
                                category_id: catInput.value || null,
                                product_id: row.querySelector('.detail-product-id').value || null,
                                product_name: row.querySelector('.detail-product-search').value,
                                specifications: row.querySelector('.detail-specs').value,
                                unit: row.querySelector('.detail-unit').value,
                                quantity: qty,
                                unit_price: price
                            });
                        } else {
                            newGrandTotal += parseFloat(row.querySelector('.detail-row-total').innerText) || 0;
                        }
                    }

                    // Perform batch updates for items
                    if (itemsToUpdate.length > 0) {
                        const { error: itemsErr } = await supabaseClient.from('request_items').upsert(itemsToUpdate);
                        if (itemsErr) throw itemsErr;
                    }

                    // 3. Set standard status updates and the new total
                    updates.total_amount = newGrandTotal;

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

                    // 4. Update the request status and all collected fields
                    await db.updateRequestStatus(requestId, action, updates);

                    // 5. Log modified items if any
                    if (changedItemIds.size > 0) {
                        for (const itemId of changedItemIds) {
                            const item = req.request_items.find(i => i.id === itemId);
                            if (item) {
                                await db.logApproval(requestId, currentUser.id, 'item_updated', `${i18nManager.get('item_updated')}: ${item.product_name}`);
                            }
                        }
                    }

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

        // Handle Inline Row Total Calculation AND sync with memory object (req.request_items)
        container.querySelectorAll('#detail-subject, #detail-justification, .detail-category-select, .detail-product-search, .detail-specs, .detail-unit, .detail-qty, .detail-price').forEach(el => {
            el.addEventListener('input', (e) => {
                // Sync main fields
                if (el.id === 'detail-subject' || el.id === 'detail-justification') {
                    mainFieldsModified = true;
                    if (el.id === 'detail-subject') req.subject = el.value;
                    if (el.id === 'detail-justification') req.justification = el.value;
                }

                const tr = e.target.closest('tr');
                if (!tr) return; // Not an item field

                const itemId = tr.dataset.itemId;
                changedItemIds.add(itemId);
                
                const item = req.request_items.find(i => i.id === itemId);
                if (!item) return;

                // Sync UI to memory object 'item'
                if (el.classList.contains('detail-category-select')) item.category_id = el.value;
                if (el.classList.contains('detail-product-search')) item.product_name = el.value;
                if (el.classList.contains('detail-product-id')) item.product_id = el.value;
                if (el.classList.contains('detail-specs')) item.specifications = el.value;
                if (el.classList.contains('detail-unit')) item.unit = el.value;
                if (el.classList.contains('detail-qty')) item.quantity = parseFloat(el.value) || 0;
                if (el.classList.contains('detail-price')) item.unit_price = parseFloat(el.value) || 0;

                // Update Row Total in UI
                const rowTotal = (item.quantity * item.unit_price).toFixed(2);
                tr.querySelector('.detail-row-total').innerText = rowTotal;
                
                // Update Grand Total in the UI text and memory object
                let sum = 0;
                req.request_items.forEach(i => {
                    sum += (i.quantity * i.unit_price);
                });
                req.total_amount = sum;

                const totalDisplay = container.querySelector('.text-primary.h5.fw-bold');
                if (totalDisplay) {
                    totalDisplay.innerText = sum.toFixed(2) + ' SAR';
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
                            const idInput = tr.querySelector('.detail-product-id');
                            idInput.value = p.id;
                            resultsDiv.classList.remove('show');

                            // Manually trigger input event on both search and id input to sync memory
                            searchInput.dispatchEvent(new Event('input'));
                            idInput.dispatchEvent(new Event('input'));
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

function resetAndBackToPurchase() {
    ui.resetPurchaseRequestForm();
    ui.showView('overview');
}
