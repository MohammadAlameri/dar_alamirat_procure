// UI Helper Functions
const ui = {
    showView(viewId) {
        // Simple client-side authorization
        const role = currentUser?.profile?.role;
        if (viewId === 'user-management' && role !== 'admin') {
            viewId = 'overview';
        }
        if (viewId === 'all-requests' && !['admin', 'it_procurement', 'finance', 'general_manager', 'manager', 'accountant'].includes(role)) {
            viewId = 'overview';
        }

        const viewEl = document.getElementById(`view-${viewId}`);
        if (!viewEl) return;

        document.querySelectorAll('.view-content').forEach(el => el.classList.add('d-none'));
        viewEl.classList.remove('d-none');
        
        // Update nav active state
        document.querySelectorAll('#sidebar .nav-link').forEach(el => {
            if (el.dataset.view === viewId) el.classList.add('active');
            else el.classList.remove('active');
        });

        // Update title
        const titleMap = {
            'overview': i18nManager.get('dashboardOverview'),
            'create-request': i18nManager.get('newRequest'),
            'my-requests': i18nManager.get('myRequests'),
            'pending-approvals': i18nManager.get('pendingApprovals'),
            'reports': i18nManager.get('reports'),
            'user-management': i18nManager.get('userManagement'),
            'expense-requests': i18nManager.get('expenseRequests')
        };
        document.getElementById('currentViewTitle').innerText = titleMap[viewId] || i18nManager.get('requestDetails');
        
        lucide.createIcons();
    },

    setLoading(isLoading) {
        const loader = document.getElementById('loader');
        if (isLoading) loader.classList.remove('d-none');
        else loader.classList.add('d-none');
    },

    renderRequestsTable(tableId, requests, role) {
        const tbody = document.getElementById(tableId);
        if (!tbody) {
            console.warn(`Table body ${tableId} not found.`);
            return;
        }
        tbody.innerHTML = '';

        if (!requests || requests.length === 0) {
            tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">${i18nManager.get('noRequestsFound')}</td></tr>`;
            return;
        }

        requests.forEach(req => {
            const date = req.created_at ? new Date(req.created_at).toLocaleDateString() : '-';
            const statusClass = `badge-${req.status}`;
            const userName = req.profiles?.full_name || req.requested_by_name || req.employee_name || 'System';
            const isExpense = req.type === 'expense';
            const typeLabel = i18nManager.get(isExpense ? 'expense' : 'procure');
            const typeBadgeClass = isExpense ? 'bg-info' : 'bg-primary';
            const detailBtnClass = isExpense ? 'view-expense-details-btn' : 'view-details-btn';
            const total = req.amount || req.total_amount || 0;
            const displayTotal = Number(total).toFixed(2);
            
            tbody.innerHTML += `
                <tr>
                    <td class="ps-4 fw-medium text-primary">#${req.id.substring(0, 8)}</td>
                    <td><span class="badge ${typeBadgeClass}">${typeLabel}</span></td>
                    <td>${req.subject}</td>
                    <td>${userName}</td>
                    <td><span class="badge ${statusClass}">${i18nManager.get(req.status)}</span></td>
                    <td>${date}</td>
                    <td>${displayTotal}</td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-outline-primary ${detailBtnClass}" data-id="${req.id}">
                            ${i18nManager.get('action')}
                        </button>
                    </td>
                </tr>
            `;
        });
    },

    renderExpensesTable(tableId, expenses, role) {
        const tbody = document.getElementById(tableId);
        if (!tbody) return;
        tbody.innerHTML = '';

        if (!expenses || expenses.length === 0) {
            tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">${i18nManager.get('noRequestsFound')}</td></tr>`;
            return;
        }

        expenses.forEach(exp => {
            const date = exp.created_at ? new Date(exp.created_at).toLocaleDateString() : '-';
            const statusClass = `badge-${exp.status}`;
            const userName = exp.profiles?.full_name || exp.employee_name || 'System';
            
            tbody.innerHTML += `
                <tr>
                    <td class="ps-4 fw-medium text-primary">#${exp.id.substring(0, 8)}</td>
                    <td>${exp.subject}</td>
                    <td>${userName}</td>
                    <td>${Number(exp.amount).toFixed(2)}</td>
                    <td><span class="badge ${statusClass}">${i18nManager.get(exp.status)}</span></td>
                    <td>${date}</td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-outline-primary view-expense-details-btn" data-id="${exp.id}">
                            ${i18nManager.get('action')}
                        </button>
                    </td>
                </tr>
            `;
        });
    },

    updateUserUI(user) {
        if (!user || !user.profile) {
            console.error("DEBUG: Cannot update UI, user profile missing.");
            return;
        }

        const role = user.profile.role;
        const fullName = user.profile.full_name || 'User';
        console.log("DEBUG: Updating UI for", fullName, "(Role:", role + ")");

        const setSafeText = (id, text) => {
            const el = document.getElementById(id);
            if (el) el.innerText = text;
        };

        setSafeText('userName', fullName);
        setSafeText('userRole', i18nManager.get(role));
        
        const initials = fullName.split(' ').filter(n => n).map(n => n[0]).join('').toUpperCase();
        setSafeText('userInitials', initials || '?');

        // Sidebar Links - Safe checks
        const links = {
            admin: document.getElementById('link-admin'),
            approvals: document.getElementById('link-approvals'),
            all: document.getElementById('link-all-requests'),
            reports: document.getElementById('link-reports')
        };

        if (links.admin) links.admin.classList.toggle('d-none', role !== 'admin');
        
        if (links.all) {
            const canSeeAll = ['admin', 'it_procurement', 'finance', 'general_manager', 'manager', 'accountant'].includes(role);
            links.all.classList.toggle('d-none', !canSeeAll);
        }

        if (links.approvals) {
            const canApprove = ['admin', 'it_procurement', 'finance', 'manager', 'general_manager', 'accountant'].includes(role);
            links.approvals.classList.toggle('d-none', !canApprove);
        }

        if (links.reports) links.reports.classList.add('d-none');
    },

    resetPurchaseRequestForm() {
        const form = document.getElementById('purchaseRequestForm');
        if (form) form.reset();
        const editIdEl = document.getElementById('editRequestId');
        if (editIdEl) editIdEl.value = '';
        const tbody = document.getElementById('itemsBody');
        if (tbody) {
            tbody.innerHTML = '';
            this.addRowToItemsTable();
        }
        this.calculateTotals();
    },

    resetExpenseRequestForm() {
        const form = document.getElementById('expenseRequestForm');
        if (form) form.reset();
        const editIdEl = document.getElementById('editExpenseId');
        if (editIdEl) editIdEl.value = '';
    },

    addRowToItemsTable() {
        const tbody = document.getElementById('itemsBody');
        if (!tbody) return;
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><input type="text" class="form-control" name="product_name[]" required></td>
            <td><input type="text" class="form-control" name="specifications[]"></td>
            <td><input type="text" class="form-control" name="unit[]" placeholder="${i18nManager.get('pcs')}"></td>
            <td><input type="number" class="form-control qty-input" name="quantity[]" value="1" min="1" required></td>
            <td><input type="number" class="form-control price-input" name="unit_price[]" step="0.01" value="0.00" required></td>
            <td><input type="number" class="form-control row-total" readonly value="0.00"></td>
            <td><input type="text" class="form-control" name="country_of_origin[]"></td>
            <td><input type="text" class="form-control" name="warranty_period[]"></td>
            <td><input type="text" class="form-control" name="brand_model[]"></td>
            <td><button type="button" class="btn btn-sm btn-outline-danger remove-row"><i data-lucide="trash-2" style="width: 14px;"></i></button></td>
        `;
        tbody.appendChild(tr);
        lucide.createIcons();
    },

    calculateTotals() {
        let grandTotal = 0;
        document.querySelectorAll('#itemsBody tr').forEach(row => {
            const qtyInput = row.querySelector('.qty-input');
            const priceInput = row.querySelector('.price-input');
            const totalInput = row.querySelector('.row-total');
            
            if (qtyInput && priceInput && totalInput) {
                const qty = Number.parseFloat(qtyInput.value) || 0;
                const price = Number.parseFloat(priceInput.value) || 0;
                const total = qty * price;
                totalInput.value = total.toFixed(2);
                grandTotal += total;
            }
        });
        const grandTotalEl = document.getElementById('grandTotal');
        if (grandTotalEl) grandTotalEl.value = grandTotal.toFixed(2);
    },

    loadRequestForEdit(req) {
        this.showView('create-request');
        document.getElementById('currentViewTitle').innerText = i18nManager.get('editRequest');
        const editIdEl = document.getElementById('editRequestId');
        if (editIdEl) editIdEl.value = req.id;
        
        const subjIn = document.getElementById('subjectInput');
        if (subjIn) subjIn.value = req.subject;
        const justIn = document.getElementById('justificationInput');
        if (justIn) justIn.value = req.justification || '';
        const nameIn = document.getElementById('requestedByName');
        if (nameIn) nameIn.value = req.requested_by_name || '';
        const titleIn = document.getElementById('requestedByTitle');
        if (titleIn) titleIn.value = req.requested_by_title || '';
        
        const tbody = document.getElementById('itemsBody');
        if (tbody) {
            tbody.innerHTML = '';
            if (req.request_items && req.request_items.length > 0) {
                req.request_items.forEach(item => {
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td><input type="text" class="form-control" name="product_name[]" value="${item.product_name || ''}" required></td>
                        <td><input type="text" class="form-control" name="specifications[]" value="${item.specifications || ''}"></td>
                        <td><input type="text" class="form-control" name="unit[]" value="${item.unit || ''}" placeholder="${i18nManager.get('pcs')}"></td>
                        <td><input type="number" class="form-control qty-input" name="quantity[]" value="${item.quantity || 1}" min="1" required></td>
                        <td><input type="number" class="form-control price-input" name="unit_price[]" step="0.01" value="${item.unit_price || 0}" required></td>
                        <td><input type="number" class="form-control row-total" readonly value="${item.total_price || ((item.quantity||0)*(item.unit_price||0)).toFixed(2)}"></td>
                        <td><input type="text" class="form-control" name="country_of_origin[]" value="${item.country_of_origin || ''}"></td>
                        <td><input type="text" class="form-control" name="warranty_period[]" value="${item.warranty_period || ''}"></td>
                        <td><input type="text" class="form-control" name="brand_model[]" value="${item.brand_model || ''}"></td>
                        <td><button type="button" class="btn btn-sm btn-outline-danger remove-row"><i data-lucide="trash-2" style="width: 14px;"></i></button></td>
                    `;
                    tbody.appendChild(tr);
                });
            } else {
                this.addRowToItemsTable();
            }
        }
        this.calculateTotals();
        if (typeof lucide !== 'undefined') lucide.createIcons();
    },

    loadExpenseForEdit(exp) {
        this.showView('create-expense');
        document.getElementById('currentViewTitle').innerText = i18nManager.get('editRequest');
        const editIdEl = document.getElementById('editExpenseId');
        if (editIdEl) editIdEl.value = exp.id;
        
        const subjIn = document.getElementById('expenseSubject');
        if (subjIn) subjIn.value = exp.subject;
        const amountIn = document.getElementById('expenseAmount');
        if (amountIn) amountIn.value = exp.amount;
        const levelSelect = document.getElementById('expenseApprovalLevel');
        if (levelSelect) levelSelect.value = exp.highest_approval_level;
        const stmtIn = document.getElementById('expenseStatement');
        if (stmtIn) stmtIn.value = exp.statement;
        
        if (typeof lucide !== 'undefined') lucide.createIcons();
    },

    renderProfilesTable(profiles) {
        console.log("DEBUG: renderProfilesTable starting with", profiles?.length, "profiles");
        const tbody = document.getElementById('profilesTableBody');
        if (!tbody) {
            console.error("DEBUG ERR: profilesTableBody element NOT FOUND!");
            return;
        }
        tbody.innerHTML = '';

        if (!profiles || profiles.length === 0) {
            console.log("DEBUG: Profiles list is empty.");
            tbody.innerHTML = `<tr><td colspan="5" class="text-center py-4 text-muted">${i18nManager.get('noProfilesFound')}</td></tr>`;
            return;
        }

        profiles.forEach((profile, index) => {
            try {
                const roleName = i18nManager.get(profile.role) || profile.role;
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td class="ps-4 fw-medium">${profile.full_name || '-'}</td>
                    <td>${profile.email || '-'}</td>
                    <td><span class="badge bg-secondary">${roleName}</span></td>
                    <td>${profile.department || '-'}</td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-outline-primary edit-profile-btn" 
                                data-id="${profile.id}" 
                                data-name="${profile.full_name || ''}"
                                data-email="${profile.email || ''}"
                                data-role="${profile.role}"
                                data-title="${profile.job_title || ''}"
                                data-dept="${profile.department || ''}"
                                data-manager="${profile.manager_id || ''}">
                            <i data-lucide="edit-3" style="width:14px;"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger delete-profile-btn" data-id="${profile.id}" data-name="${profile.full_name || ''}">
                            <i data-lucide="trash-2" style="width:14px;"></i>
                        </button>
                    </td>
                `;
                tbody.appendChild(tr);
            } catch (err) {
                console.error(`Error rendering profile at index ${index}:`, err);
            }
        });
        
        if (typeof lucide !== 'undefined') lucide.createIcons();
        console.log("DEBUG: Profiles table populated.");
    },

    updateManagerFieldVisibility() {
        const role = document.getElementById('role')?.value;
        const managerGroup = document.getElementById('managerGroup');
        if (managerGroup) {
            // Only show manager selection if role is 'employee' (staff)
            if (role === 'employee') {
                managerGroup.classList.remove('d-none');
            } else {
                managerGroup.classList.add('d-none');
            }
        }
    },

    toggleProfileForm(showForm) {
        if (showForm) {
            document.getElementById('profile-list-section')?.classList.add('d-none');
            document.getElementById('profile-form-section')?.classList.remove('d-none');
            this.updateManagerFieldVisibility();
        } else {
            document.getElementById('profile-list-section')?.classList.remove('d-none');
            document.getElementById('profile-form-section')?.classList.add('d-none');
            document.getElementById('createUserForm')?.reset();
            document.getElementById('profile_id').value = '';
            document.getElementById('passwordHint').classList.add('d-none');
            document.getElementById('password').required = true;
            document.getElementById('profileFormTitle').innerText = i18nManager.get('createUser');
            document.getElementById('manager_id').value = '';
        }
    },

    populateManagerDropdown(managers) {
        const select = document.getElementById('manager_id');
        if (!select) return;
        
        // Keep the "None" option
        select.innerHTML = `<option value="">-- ${i18nManager.get('none')} --</option>`;
        
        managers.forEach(m => {
            const opt = document.createElement('option');
            opt.value = m.id;
            opt.innerText = `${m.full_name} (${m.department || ''})`;
            select.appendChild(opt);
        });
    },

    printRequest(req, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) {
            this.showNotification(i18nManager.get('errorPrintContainer'), 'error');
            return;
        }


        // Format Hijri date
        let hijriDate = '';
        try {
            const date = new Date(req.created_at);
            hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day: 'numeric', month: 'numeric', year: 'numeric'}).format(date).replace(/[هـ]/g, '').trim() + ' هـ';
        } catch(e) {
            hijriDate = new Date(req.created_at).toLocaleDateString('ar') + ' هـ';
        }

        // Find approvals by role/action
        const managerApproval = approvals.find(a => a.action === 'manager_approved');
        const itApproval = approvals.find(a => a.action === 'it_approved');
        const financeApproval = approvals.find(a => a.action === 'finance_approved');
        
        const managerName = managerApproval && managerApproval.profiles ? managerApproval.profiles.full_name : '';
        const managerTitle = managerApproval && managerApproval.profiles ? (managerApproval.profiles.job_title || '') : '';
        let managerDate = '';
        if (managerApproval) {
            try { managerDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(managerApproval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ'; } catch(e) { managerDate = ''; }
        }

        const itApproverName = itApproval && itApproval.profiles ? itApproval.profiles.full_name : '';
        const itApproverTitle = itApproval && itApproval.profiles ? (itApproval.profiles.job_title || '') : '';
        let itApprovalDate = '';
        if (itApproval) {
            try { itApprovalDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(itApproval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ'; } catch(e) { itApprovalDate = ''; }
        }

        const finApproverName = financeApproval && financeApproval.profiles ? financeApproval.profiles.full_name : '';
        let finApprovalDate = '';
        if (financeApproval) {
            try { finApprovalDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(financeApproval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ'; } catch(e) { finApprovalDate = ''; }
        }

        // Requester info (filled at creation)
        const requesterName = req.requested_by_name || '';
        const requesterTitle = req.requested_by_title || '';

        // Suppliers
        const suppliers = req.suggested_suppliers ? req.suggested_suppliers.split('\n') : ['', '', ''];
        while (suppliers.length < 3) suppliers.push('');

        // Budget info
        const budgetAllows = req.budget_status === true;
        const budgetDenied = req.budget_status === false;
        const budgetLine = req.budget_line_item || '';
        const commitNum = req.commitment_number || '';
        const totalAmount = req.total_amount ? Number(req.total_amount).toFixed(2) : '0.00';
        const amountWords = req.amount_in_words || '';

        // Build items rows (only actual items)
        let itemsHtml = '';
        const items = req.request_items || [];
        items.forEach((item, i) => {
            const desc = [item.product_name || '', item.specifications || ''].filter(Boolean).join(' - ');
            const unitPrice = item.unit_price ? Number(item.unit_price).toFixed(2) : '';
            const totalPrice = (item.quantity && item.unit_price) ? (Number(item.quantity) * Number(item.unit_price)).toFixed(2) : '';
            itemsHtml += `
                <tr>
                    <td style="width:25px; border:1px solid #000; padding:3px;">${i + 1}</td>
                    <td style="text-align:right; border:1px solid #000; padding:3px;">${desc}</td>
                    <td style="border:1px solid #000; padding:3px;">${item.unit || ''}</td>
                    <td style="border:1px solid #000; padding:3px;">${item.quantity || ''}</td>
                    <td style="border:1px solid #000; padding:3px;">${unitPrice}</td>
                    <td style="border:1px solid #000; padding:3px;">${totalPrice}</td>
                    <td style="border:1px solid #000; padding:3px;">${item.country_of_origin || ''}</td>
                    <td style="border:1px solid #000; padding:3px;">${item.warranty_period || ''}</td>
                    <td style="border:1px solid #000; padding:3px;">${item.brand_model || ''}</td>
                </tr>
            `;
        });

        container.innerHTML = `
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:2mm 10mm; max-width:210mm; margin:0 auto;">
                
                <!-- Header -->
                <div style="border:1.5px solid #000; padding:5px; margin-bottom:5px;">
                    <div style="text-align:center; border-bottom:1.5px solid #000; padding-bottom:5px; margin-bottom:5px;">
                        <div style="font-size:22px; font-weight:900; color:#000;">DAR ALAMIRAT</div>
                        <div style="font-size:16px; font-weight:bold;">دار الاميرات</div>
                    </div>
                    <div style="text-align:center; font-size:16px; font-weight:bold; margin-bottom:5px;">نموذج طلب شــــــراء</div>
                    
                    <div style="display:flex; align-items:center; margin-bottom:4px;">
                        <span style="font-weight:bold; font-size:13px; white-space:nowrap; margin-left:8px;">الموضوع :</span>
                        <span style="border-bottom:1px dotted #000; flex-grow:1; padding-bottom:1px; font-size:13px;">${req.subject || ''}</span>
                    </div>
                    
                    <div style="display:flex; align-items:center;">
                        <span style="font-weight:bold; font-size:13px; white-space:nowrap; margin-left:8px;">مبررات الاحتياج :</span>
                        <span style="border-bottom:1px dotted #000; flex-grow:1; padding-bottom:1px; font-size:13px;">${req.justification || ''}</span>
                    </div>
                </div>

                <!-- Items Table -->
                <table style="width:100%; border-collapse:collapse; margin-top:5px; border:1px solid #000;">
                    <thead>
                        <tr>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:25px;">م</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2;">المواصفات المطلوبة</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:40px;">الوحدة</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:40px;">الكمية</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:55px;">* سعر الوحدة</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:60px;">* السعر الإجمالي</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:55px;">* بلد الصناعة</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:55px;">* مدة الضمان</th>
                            <th style="border:1px solid #000; padding:3px; text-align:center; font-size:10px; background:#f2f2f2; width:80px;">* الماركة / الموديل</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${itemsHtml}
                    </tbody>
                </table>

                <!-- Section 1: Employee Requester -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">الموظف طالب الاحتياج :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${requesterName}</span></span>
                        <span>الوظيفة : <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${requesterTitle}</span></span>
                        <span>التوقيع .....................</span>
                        <span>التاريخ: ${hijriDate} </span>
                    </div>
                </div>

                <!-- Section 2: Manager Approval -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">اعتماد مسؤول الجهة الطالبة :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${managerName}</span></span>
                        <span>الوظيفة : <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${managerTitle}</span></span>
                        <span>التوقيع .....................</span>
                        <span>التاريخ:&nbsp; ${managerApproval ? managerDate : '&nbsp;&nbsp;/&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;١٤هـ'}</span>
                    </div>
                </div>

                <!-- Section 3: IT / Procurement -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">إفادة ادارة المشتريات او قسم IT :</div>
                    <p style="font-size:11px; margin:4px 0;">بعد مراجعة المخزون لدينا تبين عدم توفر ما هو مطلوب أعلاه وعلى ذلك جرى التوقيع والتاكد من صحة الاحتياج للمشتريات اعلاه.</p>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>اسم المسؤول <span style="border-bottom:1px dotted #000; min-width:150px; display:inline-block;">${itApproverName}</span></span>
                        <span>التوقيع .........................</span>
                        <span>التاريخ: ${itApproval ? itApprovalDate : '&nbsp;&nbsp;/&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;١٤هـ'}</span>
                    </div>
                    <div style="display:flex; margin-top:5px; gap:0;">
                        <div style="flex:1; border:1px solid #000; padding:4px;">
                            <div style="font-weight:bold; font-size:11px; margin-bottom:2px;">أسماء الموردين المقترحين</div>
                            <div id="supplierRows">
                                ${req.suggested_suppliers ? req.suggested_suppliers.split('\n').filter(s => s.trim()).map((s, idx) => `<div style="font-size:11px;">${idx + 1}- ${s}</div>`).join('') : `
                                    <div style="font-size:11px;">1- ...........................................</div>
                                    <div style="font-size:11px;">2- ...........................................</div>
                                `}
                            </div>
                        </div>
                        <div style="width:330px; border:1px solid #000; border-right:0; padding:4px; display:flex; align-items:center; gap:8px;">
                            <div style="font-size:10px; white-space:nowrap;">* الإجمالي رقماً: <span style="font-weight:bold; border-bottom:1px solid #000;">${totalAmount}</span></div>
                            <div style="font-size:10px; flex-grow:1;">* الإجمالي كتابة: <span style="font-weight:bold; border-bottom:1px solid #000;">${amountWords || '..................................'}</span></div>
                        </div>
                    </div>
                </div>

                <!-- Section 4: Budget & Commitments -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">إدارة التخطيط والميزانية – الارتباطات :</div>
                    <div style="display:flex; gap:15px; font-size:12px; margin-bottom:5px;">
                        <span style="display:flex; align-items:center; gap:4px;"><span style="width:14px;height:14px;border:1px solid #000;display:inline-block;text-align:center;font-size:10px;">${budgetAllows ? '✓' : ''}</span> البند يسمح</span>
                        <span style="display:flex; align-items:center; gap:4px;"><span style="width:14px;height:14px;border:1px solid #000;display:inline-block;text-align:center;font-size:10px;">${budgetDenied ? '✓' : ''}</span> البند لا يسمح</span>
                    </div>
                    <div style="font-size:12px; margin-bottom:5px;">المبلغ : ( ${amountWords || '...................... , ..........................................'} ) ريال &nbsp;&nbsp; رقم البند <span style="border-bottom:1px dotted #000; min-width:100px; display:inline-block;">${budgetLine}</span> &nbsp; رقم الارتباط <span style="border-bottom:1px dotted #000; min-width:100px; display:inline-block;">${commitNum}</span></div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; margin-top:6px; flex-wrap:wrap; gap:3px;">
                        <span>الموظف المختص : .............................................</span>
                        <span>التوقيع ...................................</span>
                        <span>التاريخ&nbsp;&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;١٤هـ</span>
                    </div>
                </div>

                <!-- Section 5: Finance -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">الإدارة المالية :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${finApproverName}</span></span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${finApprovalDate ? finApprovalDate : '&nbsp;&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;١٤هـ'}</span>
                    </div>
                </div>

                <!-- Instructions -->
                <div style="margin-top:10px; font-size:10px; line-height:1.5;">
                    <strong>تعليمات يجب مراعاتها :</strong><br>
                    1. سوف يعاد إلى الجهة الطالبة أي طلب شراء غير مستوفي للبيانات المذكورة أعلاه.<br>
                    2. التسعير يتم على نفس طلب الشراء .<br>
                    3. يجب ذكر بلد الصنع والاسم التجاري للمنشأ + مدة الضمان .<br>
                    4. يجب تحديد حجم العبوه المطلوبة او توضع للصنف الواحد الكمية حسب العبوة بما يوافق الكمية المحددة .<br>
                    5 * تعبأ بحسب بيانات العرض المقبول من المورد
                </div>
            </div>
        `;

        globalThis.print();
    },

    printReceipt(req, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) return;

        // Dates and Times
        const dateObj = req.staff_receiving_date ? new Date(req.staff_receiving_date) : new Date();
        const daysAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
        const dayOfWeek = daysAr[dateObj.getDay()];
        let hijriDate = '';
        try {
            hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(dateObj).replace(/[هـ]/g, '').trim() + ' هـ';
        } catch(e) { hijriDate = dateObj.toLocaleDateString('ar') + ' هـ'; }
        const gregorianDate = dateObj.toLocaleDateString('en-GB'); // Just date string
        const topDateG = new Date(req.created_at || new Date()).toLocaleDateString('en-GB');

        let timeStr = dateObj.toLocaleTimeString('ar-SA', {hour: '2-digit', minute:'2-digit'});

        const requester = req.profiles || {};
        const staffName = req.requested_by_name || requester.full_name || '';
        const staffTitle = req.requested_by_title || (requester.job_title || '');
        const dept = requester.department || '';

        // Find the IT Officer Name (the one who marked it as complete)
        // If it's completed, we can try to show their name inside 'مسؤول التسليم'
        let itOfficerName = '';
        if (req.status === 'completed' && currentUser && currentUser.profile.role === 'it_procurement') {
            itOfficerName = currentUser.profile.full_name;
        } else if (req.status === 'completed' || req.status === 'received_by_staff') {
            // If another person is printing it, ideally we'd look in an approvals log, 
            // but for simplicity we will just show the name if available from context.
            // A more robust way would be to save 'it_officer_name' in the DB column. Let's do a fallback:
            itOfficerName = '...........................................'; // Empty space if unknown
        }

        // Items HTML (Dynamic Rows)
        let itemsHtml = '';
        const items = req.request_items || [];
        if (items.length === 0) {
            itemsHtml = `<tr><td colspan="5" style="border:1.5px solid #000; padding:10px; text-align:center;">لا توجد أصناف</td></tr>`;
        } else {
            items.forEach((item, i) => {
                itemsHtml += `
                    <tr>
                        <td style="border:1.5px solid #000; padding:10px; text-align:center;">${i + 1}</td>
                        <td style="border:1.5px solid #000; padding:10px; text-align:right;">${item.product_name} ${item.brand_model ? `(${item.brand_model})` : ''}</td>
                        <td style="border:1.5px solid #000; padding:10px; text-align:center;">-</td>
                        <td style="border:1.5px solid #000; padding:10px; text-align:center;">${item.quantity}</td>
                        <td style="border:1.5px solid #000; padding:10px; text-align:right;">${item.specifications || ''}</td>
                    </tr>
                `;
            });
        }

        // Checkbox states - more robust checks
        const isAccepted = req.staff_acceptance_status === 'accepted' || req.status === 'received_by_staff';
        const isRejected = req.staff_acceptance_status === 'rejected' || req.status === 'rejected_by_staff';
        const checkAccepted = isAccepted ? '✔' : '&nbsp;&nbsp;&nbsp;';
        const checkRejected = isRejected ? '✔' : '&nbsp;&nbsp;&nbsp;';

        // Rejection Section
        let rejectionSection = '';
        if (req.staff_rejection_reason) {
            // Split by actual newline characters from the textarea
            const reasons = req.staff_rejection_reason.split('\n').map(r => r.trim()).filter(Boolean);
            reasons.forEach((r, idx) => {
                rejectionSection += `<div style="padding-right:20px; margin-bottom:5px; border-bottom:1px dotted #000; direction: rtl; text-align: right;">${idx + 1}- ${r}</div>`;
            });
        } else if (isRejected) {
             rejectionSection = `<div style="padding-right:20px; margin-bottom:5px; border-bottom:1px dotted #000; direction: rtl; text-align: right;">1- نعتذر، تم الرفض بدون إبداء أسباب</div>`;
        } else {
            rejectionSection = `
                <div style="padding-right:20px; color:#aaa; margin-bottom: 5px; direction: rtl; text-align: right;">
                ...................................................................................................................................................
                </div>
            `;
        }

        container.innerHTML = `
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:2mm 10mm; max-width:210mm; margin:0 auto; font-size:16px;">
                
                <!-- Main Outer Box -->
                <div style="padding: 10px; position:relative;">
                    
                    <!-- Header -->
                    <div style="text-align:center; margin-bottom: 15px; position:relative;">
                        <div style="display:inline-block; text-align:center; color: #4a77b4;">
                            <h1 style="margin:0; font-family: 'Arial', sans-serif; font-weight:900; font-size:36px; display:flex; align-items:center; justify-content:center; gap:10px;">
                                <span>دار الاميرات</span>
                                <span style="font-size:46px;">DA</span>
                            </h1>
                            <div style="font-size:16px; font-weight:bold; letter-spacing:2px; font-family: 'Arial', sans-serif;">DAR ALAMIRAT</div>
                        </div>
                        <h2 style="margin:10px 0 0 0; font-weight:bold; font-size:26px; text-decoration:underline;">استلام عهدة اصل</h2>
                    </div>

                    <!-- Dates -->
                    <div style="display:flex; justify-content:space-between; margin-bottom:20px; font-weight:bold; font-size:16px;">
                        <div>التاريخ: .... / .... / .... 14هـ</div>
                        <div>التاريخ: ${topDateG}</div>
                    </div>

                    <!-- Table 1: Receiver Info -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="6" style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; border-bottom: 2px solid #000;">بيانات المستلم</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%;">اسم الموظف</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:35%; text-align:right; padding-right:15px;">${staffName}</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:10%;">الإدارة</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%; text-align:right; padding-right:15px;">${dept}</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:10%;">المسمى الوظيفي</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%; text-align:right; padding-right:15px;">${staffTitle}</td>
                        </tr>
                    </table>

                    <!-- Table 2: Items -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="5" style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; border-bottom: 2px solid #000;">بيانات العهدة</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px; width:5%;">م</th>
                            <th style="border: 1.5px solid #000; padding:8px; width:45%;">الوصف</th>
                            <th style="border: 1.5px solid #000; padding:8px; width:15%;">النوع</th>
                            <th style="border: 1.5px solid #000; padding:8px; width:10%;">الكمية</th>
                            <th style="border: 1.5px solid #000; padding:8px; width:25%;">ملاحظة</th>
                        </tr>
                        ${itemsHtml}
                    </table>

                    <!-- Table 3: Declaration -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">إقرار</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:20px; line-height:2.2;">
                                أقر أنا الموقع أدناه بأنني استلمت العُهد الموضحة أعلاه في يوم/ <strong>${dayOfWeek}</strong> الموافق <strong>${gregorianDate}</strong> / <strong>${hijriDate}</strong> في تمام الساعة <strong>${timeStr}</strong> بحالة صالحة للاستخدام وأتعهد بالمحافظة عليها وان لا أتنازل عنها لأي شخص آخر وسأقوم بإعادتها عند طلبها أو عند ترك العمل أو دفع قيمة ما تسببت في تلفه وسأكون عرضة للمسائلة في حين مخالفتي للإقرار.
                                <div style="display:flex; justify-content:space-between; margin-top:35px; font-weight:bold; padding:0 30px;">
                                    <div>المستلم/ <span style="font-weight:normal; text-decoration:underline;">${staffName}</span></div>
                                    <div>التوقيع/ ...........................................</div>
                                </div>
                                <br>
                            </td>
                        </tr>
                    </table>

                    <!-- Table 4: Handover Details -->
                    <table style="width:100%; border-collapse:collapse; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:10px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">خاص بمسؤول التسليم والاستلام</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:20px; line-height:2.2;">
                                <div style="display:flex; justify-content:flex-start; gap:80px; font-weight:bold; margin-bottom:20px;">
                                    <div>أ- تم استلام العُهد بحالة التسليم. ( ${checkAccepted} ) نعم</div>
                                    <div>( ${checkRejected} ) لا، للأسباب التالية :</div>
                                </div>
                                <div style="margin-bottom:20px;">
                                    ${rejectionSection}
                                </div>
                                <div style="display:flex; justify-content:space-between; align-items:center; margin-top:25px; font-weight:bold;">
                                    <div>تم استلام العُهد في يوم/ <strong>${dayOfWeek}</strong></div>
                                    <div style="flex-grow:1; text-align:center;">الموافق <strong>${gregorianDate}</strong> / <strong>${hijriDate}</strong></div>
                                    <div>في تمام الساعة <strong>${timeStr}</strong></div>
                                </div>
                                <div style="display:flex; justify-content:space-between; margin-top:35px; font-weight:bold; padding:0 30px;">
                                    <div>مسؤول التسليم: <span style="font-weight:normal; text-decoration:underline;">${req.status === 'completed' && itOfficerName ? itOfficerName : '...........................................'}</span></div>
                                    <div>التوقيع: ...........................................</div>
                                </div>
                                <br>
                            </td>
                        </tr>
                    </table>

                </div> <!-- End Main Box -->
                
                <!-- Bottom Footer -->
                <div style="margin-top:15px; text-align:center; font-size:12px; color:#555;">
                    الأصل: ملف الموظف | نسخة: المستلم | نسخة: إدارة تقنية المعلومات
                </div>
            </div>
        `;

        window.print();
    },

    printExpenseRequest(exp, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) {
            this.showNotification(i18nManager.get('errorPrintContainer'), 'error');
            return;
        }

        // Format dates
        let hijriDate = '';
        try {
            const date = new Date(exp.created_at);
            hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day: 'numeric', month: 'numeric', year: 'numeric'}).format(date).replace(/[هـ]/g, '').trim() + ' هـ';
        } catch(e) {
            hijriDate = new Date(exp.created_at).toLocaleDateString('ar') + ' هـ';
        }
        const gregorianDate = new Date(exp.created_at).toLocaleDateString('en-GB');

        // Employee info
        const employeeName = exp.employee_name || '';
        const employeeTitle = exp.profiles?.job_title || '';
        const employeeDept = exp.profiles?.department || '';

        // Amount
        const amount = exp.amount ? Number(exp.amount).toFixed(2) : '0.00';

        // Approval level label
        const levelLabels = {
            manager: 'المدير المباشر',
            finance: 'الادارة المالية',
            general_manager: 'المدير العام'
        };
        const levelLabel = levelLabels[exp.highest_approval_level] || exp.highest_approval_level;

        // Find approvals by action
        const managerApproval = approvals.find(a => a.action === 'manager_approved');
        const financeApproval = approvals.find(a => a.action === 'finance_approved');
        const gmApproval = approvals.find(a => a.action === 'gm_approved');
        const paidApproval = approvals.find(a => a.action === 'paid');

        const getApproverName = (approval) => approval?.profiles?.full_name || '';
        const getApprovalDate = (approval) => {
            if (!approval) return '&nbsp;&nbsp;/&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;١٤هـ';
            try {
                return new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(approval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ';
            } catch(e) { return ''; }
        };

        container.innerHTML = `
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:2mm 10mm; max-width:210mm; margin:0 auto;">
                
                <!-- Header -->
                <div style="border:1.5px solid #000; padding:5px; margin-bottom:5px;">
                    <div style="text-align:center; border-bottom:1.5px solid #000; padding-bottom:5px; margin-bottom:5px;">
                        <div style="font-size:22px; font-weight:900; color:#000;">DAR ALAMIRAT</div>
                        <div style="font-size:16px; font-weight:bold;">دار الاميرات</div>
                    </div>
                    <div style="text-align:center; font-size:16px; font-weight:bold; margin-bottom:5px;">نموذج طلب صرف مصاريف</div>
                    
                    <div style="display:flex; justify-content:space-between; margin-bottom:4px; font-size:12px;">
                        <span>التاريخ: ${hijriDate}</span>
                        <span>Date: ${gregorianDate}</span>
                    </div>
                </div>

                <!-- Employee Info Section -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px; background:#f2f2f2; padding:4px;">بيانات الموظف مقدم الطلب</div>
                    <table style="width:100%; border-collapse:collapse; font-size:12px;">
                        <tr>
                            <td style="padding:4px; width:15%; font-weight:bold; border:1px solid #000;">اسم الموظف</td>
                            <td style="padding:4px; width:35%; border:1px solid #000;">${employeeName}</td>
                            <td style="padding:4px; width:15%; font-weight:bold; border:1px solid #000;">المسمى الوظيفي</td>
                            <td style="padding:4px; width:35%; border:1px solid #000;">${employeeTitle}</td>
                        </tr>
                        <tr>
                            <td style="padding:4px; font-weight:bold; border:1px solid #000;">الإدارة / القسم</td>
                            <td style="padding:4px; border:1px solid #000;">${employeeDept}</td>
                            <td style="padding:4px; font-weight:bold; border:1px solid #000;">رقم الطلب</td>
                            <td style="padding:4px; border:1px solid #000;">#${exp.id.substring(0, 8)}</td>
                        </tr>
                    </table>
                </div>

                <!-- Expense Details Section -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px; background:#f2f2f2; padding:4px;">تفاصيل المصروف</div>
                    <table style="width:100%; border-collapse:collapse; font-size:12px;">
                        <tr>
                            <td style="padding:6px; width:15%; font-weight:bold; border:1px solid #000;">الموضوع</td>
                            <td colspan="3" style="padding:6px; border:1px solid #000;">${exp.subject || ''}</td>
                        </tr>
                        <tr>
                            <td style="padding:6px; font-weight:bold; border:1px solid #000;">البيان</td>
                            <td colspan="3" style="padding:6px; border:1px solid #000; min-height:40px;">${exp.statement || ''}</td>
                        </tr>
                        <tr>
                            <td style="padding:6px; font-weight:bold; border:1px solid #000;">المبلغ المطلوب</td>
                            <td style="padding:6px; border:1px solid #000; font-weight:bold; font-size:14px;">${amount} ريال</td>
                            <td style="padding:6px; font-weight:bold; border:1px solid #000;">أعلى مستوى اعتماد</td>
                            <td style="padding:6px; border:1px solid #000;">${levelLabel}</td>
                        </tr>
                    </table>
                </div>

                <!-- Requester Signature -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">الموظف مقدم الطلب :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${employeeName}</span></span>
                        <span>الوظيفة : <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${employeeTitle}</span></span>
                        <span>التوقيع .....................</span>
                        <span>التاريخ: ${hijriDate}</span>
                    </div>
                </div>

                <!-- Section: Manager Approval -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">اعتماد المدير المباشر :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${getApproverName(managerApproval)}</span></span>
                        <span>التوقيع .....................</span>
                        <span>التاريخ:&nbsp; ${getApprovalDate(managerApproval)}</span>
                    </div>
                    ${managerApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${managerApproval.comments}</div>` : ''}
                </div>

                <!-- Section: Finance Approval (if level is finance or GM) -->
                ${exp.highest_approval_level === 'finance' || exp.highest_approval_level === 'general_manager' ? `
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">الإدارة المالية :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${getApproverName(financeApproval)}</span></span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${getApprovalDate(financeApproval)}</span>
                    </div>
                    ${financeApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${financeApproval.comments}</div>` : ''}
                </div>
                ` : ''}

                <!-- Section: GM Approval (if level is GM) -->
                ${exp.highest_approval_level === 'general_manager' ? `
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">اعتماد المدير العام :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${getApproverName(gmApproval)}</span></span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${getApprovalDate(gmApproval)}</span>
                    </div>
                    ${gmApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${gmApproval.comments}</div>` : ''}
                </div>
                ` : ''}

                <!-- Section: Accountant / Payment -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">محاسب العهدة (الصرف) :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${getApproverName(paidApproval)}</span></span>
                        <span>المبلغ المصروف : <span style="font-weight:bold; border-bottom:1px solid #000;">${amount}</span> ريال</span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${getApprovalDate(paidApproval)}</span>
                    </div>
                    ${paidApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${paidApproval.comments}</div>` : ''}
                </div>

                <!-- Instructions -->
                <div style="margin-top:10px; font-size:10px; line-height:1.5;">
                    <strong>تعليمات يجب مراعاتها :</strong><br>
                    1. لن ُيقبل أي طلب صرف مصاريف غير مستوفي للبيانات المذكورة أعلاه.<br>
                    2. يجب تقديم المستندات المؤيدة للمبلغ المطلوب (فواتير، ايصالات، ..الخ).<br>
                    3. الصرف على حسب مستوى الاعتماد المحدد في الطلب.<br>
                    4. يتم صرف المبلغ من العهدة بعد اكتمال جميع الاعتمادات المطلوبة.
                </div>
            </div>
        `;

        globalThis.print();
    },

    printExpenseReceipt(exp, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) return;

        // Dates
        const dateObj = new Date(exp.updated_at || exp.created_at);
        const daysAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
        const dayOfWeek = daysAr[dateObj.getDay()];
        let hijriDate = '';
        try {
            hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(dateObj).replace(/[هـ]/g, '').trim() + ' هـ';
        } catch(e) { hijriDate = dateObj.toLocaleDateString('ar') + ' هـ'; }
        const gregorianDate = dateObj.toLocaleDateString('en-GB');
        const topDateG = new Date(exp.created_at).toLocaleDateString('en-GB');
        let timeStr = dateObj.toLocaleTimeString('ar-SA', {hour: '2-digit', minute:'2-digit'});

        // Employee info
        const employeeName = exp.employee_name || '';
        const employeeTitle = exp.profiles?.job_title || '';
        const employeeDept = exp.profiles?.department || '';
        const amount = exp.amount ? Number(exp.amount).toFixed(2) : '0.00';

        // Find accountant who paid
        const paidApproval = approvals.find(a => a.action === 'paid');
        const accountantName = paidApproval?.profiles?.full_name || '...........................................';
        let paidDate = '';
        if (paidApproval) {
            try { paidDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(paidApproval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ'; } catch(e) { paidDate = ''; }
        }
        const paidGregorianDate = paidApproval ? new Date(paidApproval.created_at).toLocaleDateString('en-GB') : '';

        // Received confirmation
        const receivedApproval = approvals.find(a => a.action === 'received');
        const isReceived = exp.status === 'completed' || !!receivedApproval;

        container.innerHTML = `
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:2mm 10mm; max-width:210mm; margin:0 auto; font-size:16px;">
                
                <!-- Main Outer Box -->
                <div style="padding: 10px; position:relative;">
                    
                    <!-- Header -->
                    <div style="text-align:center; margin-bottom: 15px; position:relative;">
                        <div style="display:inline-block; text-align:center; color: #4a77b4;">
                            <h1 style="margin:0; font-family: 'Arial', sans-serif; font-weight:900; font-size:36px; display:flex; align-items:center; justify-content:center; gap:10px;">
                                <span>دار الاميرات</span>
                                <span style="font-size:46px;">DA</span>
                            </h1>
                            <div style="font-size:16px; font-weight:bold; letter-spacing:2px; font-family: 'Arial', sans-serif;">DAR ALAMIRAT</div>
                        </div>
                        <h2 style="margin:10px 0 0 0; font-weight:bold; font-size:26px; text-decoration:underline;">سند استلام مبلغ مصاريف</h2>
                    </div>

                    <!-- Dates -->
                    <div style="display:flex; justify-content:space-between; margin-bottom:20px; font-weight:bold; font-size:16px;">
                        <div>التاريخ: .... / .... / .... 14هـ</div>
                        <div>التاريخ: ${topDateG}</div>
                    </div>

                    <!-- Table 1: Employee Info -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="6" style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; border-bottom: 2px solid #000;">بيانات المستلم</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%;">اسم الموظف</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:35%; text-align:right; padding-right:15px;">${employeeName}</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:10%;">الإدارة</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%; text-align:right; padding-right:15px;">${employeeDept}</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:10%;">المسمى الوظيفي</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%; text-align:right; padding-right:15px;">${employeeTitle}</td>
                        </tr>
                    </table>

                    <!-- Table 2: Expense Details -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="4" style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; border-bottom: 2px solid #000;">تفاصيل المصروف</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px; width:15%;">الموضوع</th>
                            <td colspan="3" style="border: 1.5px solid #000; padding:8px; text-align:right; padding-right:15px;">${exp.subject}</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px;">البيان</th>
                            <td colspan="3" style="border: 1.5px solid #000; padding:8px; text-align:right; padding-right:15px;">${exp.statement || ''}</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px;">المبلغ</th>
                            <td style="border: 1.5px solid #000; padding:8px; font-weight:bold; font-size:18px;">${amount} ريال</td>
                            <th style="border: 1.5px solid #000; padding:8px;">رقم الطلب</th>
                            <td style="border: 1.5px solid #000; padding:8px;">#${exp.id.substring(0, 8)}</td>
                        </tr>
                    </table>

                    <!-- Table 3: Declaration -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">إقرار باستلام المبلغ</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:20px; line-height:2.2;">
                                أقر أنا الموقع أدناه / <strong>${employeeName}</strong> بأنني استلمت مبلغ وقدره <strong>${amount}</strong> ريال وذلك بموجب طلب صرف مصاريف رقم <strong>#${exp.id.substring(0, 8)}</strong> عن <strong>${exp.subject}</strong> وذلك في يوم / <strong>${dayOfWeek}</strong> الموافق <strong>${gregorianDate}</strong> / <strong>${hijriDate}</strong> في تمام الساعة <strong>${timeStr}</strong>.
                                <br><br>
                                وأتعهد بصرف المبلغ في الغرض المخصص له وتقديم المستندات المؤيدة خلال المدة المحددة.
                                <div style="display:flex; justify-content:space-between; margin-top:35px; font-weight:bold; padding:0 30px;">
                                    <div>المستلم/ <span style="font-weight:normal; text-decoration:underline;">${employeeName}</span></div>
                                    <div>التوقيع/ ...........................................</div>
                                </div>
                                <br>
                            </td>
                        </tr>
                    </table>

                    <!-- Table 4: Payment Officer Details -->
                    <table style="width:100%; border-collapse:collapse; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:10px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">خاص بمسؤول الصرف (محاسب العهدة)</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:20px; line-height:2.2;">
                                <div style="display:flex; justify-content:flex-start; gap:80px; font-weight:bold; margin-bottom:20px;">
                                    <div>تم صرف المبلغ بحالة ( ${isReceived ? '✔' : '&nbsp;&nbsp;&nbsp;'} ) نعم</div>
                                </div>
                                <div style="display:flex; justify-content:space-between; align-items:center; margin-top:25px; font-weight:bold;">
                                    <div>تم الصرف في يوم/ <strong>${paidApproval ? daysAr[new Date(paidApproval.created_at).getDay()] : '............'}</strong></div>
                                    <div style="flex-grow:1; text-align:center;">الموافق <strong>${paidGregorianDate || '.... / .... / ....'}</strong> / <strong>${paidDate || '.... / .... / .... هـ'}</strong></div>
                                </div>
                                <div style="display:flex; justify-content:space-between; margin-top:35px; font-weight:bold; padding:0 30px;">
                                    <div>مسؤول الصرف: <span style="font-weight:normal; text-decoration:underline;">${accountantName}</span></div>
                                    <div>التوقيع: ...........................................</div>
                                </div>
                                <br>
                            </td>
                        </tr>
                    </table>

                </div> <!-- End Main Box -->
                
                <!-- Bottom Footer -->
                <div style="margin-top:15px; text-align:center; font-size:12px; color:#555;">
                    الأصل: ملف الموظف | نسخة: المستلم | نسخة: الإدارة المالية
                </div>
            </div>
        `;

        window.print();
    },

    showNotification(message, type = 'info', duration = 3000) {
        const container = document.getElementById('notification-container');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = `toast-notification ${type}`;
        
        // Map types to Lucide icons
        let icon = 'info';
        if (type === 'success') icon = 'check-circle';
        if (type === 'error') icon = 'x-circle';
        if (type === 'warning') icon = 'alert-triangle';

        toast.innerHTML = `
            <div class="toast-icon">
                <i data-lucide="${icon}"></i>
            </div>
            <div class="toast-content">${message}</div>
            <button class="toast-close">
                <i data-lucide="x" style="width: 14px;"></i>
            </button>
        `;

        container.appendChild(toast);
        
        // Initialize the new icons
        if (typeof lucide !== 'undefined') {
            lucide.createIcons();
        }

        const closeToast = (el) => {
            el.classList.add('fade-out');
            el.addEventListener('animationend', () => {
                el.remove();
            }, { once: true });
        };

        // Auto remove
        const timeout = setTimeout(() => {
            closeToast(toast);
        }, duration);

        toast.querySelector('.toast-close').addEventListener('click', () => {
            clearTimeout(timeout);
            closeToast(toast);
        });
    }
};
