// UI Helper Functions
const ui = {
    showView(viewId) {
        // Simple client-side authorization
        const role = currentUser?.profile?.role;
        if (viewId === 'user-management' && role !== 'admin') {
            viewId = 'overview';
        }
        if (viewId === 'all-requests' && !['admin', 'it_procurement', 'finance'].includes(role)) {
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
            'user-management': i18nManager.get('userManagement')
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
            tbody.innerHTML = `<tr><td colspan="6" class="text-center py-4 text-muted">${i18nManager.currentLang === 'ar' ? 'لم يتم العثور على طلبات' : 'No requests found'}</td></tr>`;
            return;
        }

        requests.forEach(req => {
            const date = req.created_at ? new Date(req.created_at).toLocaleDateString() : '-';
            const statusClass = `badge-${req.status}`;
            // Use profile name, or raw requested_by_name, or 'System'
            const userName = req.profiles?.full_name || req.requested_by_name || 'System';
            
            tbody.innerHTML += `
                <tr>
                    <td class="ps-4 fw-medium text-primary">#${req.id.substring(0, 8)}</td>
                    <td>${req.subject}</td>
                    <td>${userName}</td>
                    <td><span class="badge ${statusClass}">${i18nManager.get(req.status)}</span></td>
                    <td>${date}</td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-outline-primary view-details-btn" data-id="${req.id}">
                            ${i18nManager.get('action') || 'Action'}
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
            const canSeeAll = ['admin', 'it_procurement', 'finance'].includes(role);
            links.all.classList.toggle('d-none', !canSeeAll);
        }

        if (links.approvals) {
            const canApprove = ['admin', 'it_procurement', 'finance', 'manager'].includes(role);
            links.approvals.classList.toggle('d-none', !canApprove);
        }

        if (links.reports) links.reports.classList.add('d-none');
    },

    addRowToItemsTable() {
        const tbody = document.getElementById('itemsBody');
        if (!tbody) return;
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><input type="text" class="form-control" name="product_name[]" required></td>
            <td><input type="text" class="form-control" name="specifications[]"></td>
            <td><input type="text" class="form-control" name="unit[]" placeholder="pcs"></td>
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
            tbody.innerHTML = `<tr><td colspan="5" class="text-center py-4 text-muted">${i18nManager.currentLang === 'ar' ? 'لا يوجد مستخدمين' : 'No profiles found'}</td></tr>`;
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
        select.innerHTML = `<option value="">-- ${i18nManager.currentLang === 'ar' ? 'بدون' : 'None'} --</option>`;
        
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
            alert('Print container not found');
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
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:5mm 10mm; max-width:210mm; margin:0 auto;">
                
                <!-- Header -->
                <div style="border:1.5px solid #000; padding:5px; margin-bottom:5px;">
                    <div style="text-align:center; border-bottom:1.5px solid #000; padding-bottom:5px; margin-bottom:5px;">
                        <div style="font-size:22px; font-weight:900; color:#000;">DAR ALAMIRAT</div>
                        <div style="font-size:16px; font-weight:bold;">دار الاميرات</div>
                    </div>
                    <div style="text-align:center; font-size:16px; font-weight:bold; margin-bottom:8px;">نموذج طلب شــــــراء</div>
                    
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

        window.print();
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
        if (req.status === 'completed' && currentUser && currentUser.profile.role === 'IT/Procurement') {
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
                rejectionSection += `<div style="padding-right:20px; margin-bottom:5px; border-bottom:1px dotted #000; direction: rtl; text-align: right;">${r} <span style="float:left;">-${idx + 1}</span></div>`;
            });
        } else if (isRejected) {
             rejectionSection = `<div style="padding-right:20px; margin-bottom:5px; border-bottom:1px dotted #000; direction: rtl; text-align: right;">نعتذر، تم الرفض بدون إبداء أسباب <span style="float:left;">-1</span></div>`;
        } else {
            rejectionSection = `
                <div style="padding-right:20px; color:#aaa; margin-bottom: 5px; direction: rtl; text-align: right;">
                ...................................................................................................................................................
                </div>
            `;
        }

        container.innerHTML = `
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:10mm; max-width:210mm; margin:0 auto; font-size:16px;">
                
                <!-- Main Outer Box -->
                <div style="padding: 10px; position:relative;">
                    
                    <!-- Header -->
                    <div style="text-align:center; margin-bottom: 30px; position:relative;">
                        <div style="display:inline-block; text-align:center; color: #4a77b4;">
                            <h1 style="margin:0; font-family: 'Arial', sans-serif; font-weight:900; font-size:36px; display:flex; align-items:center; justify-content:center; gap:10px;">
                                <span>دار الاميرات</span>
                                <span style="font-size:46px;">DA</span>
                            </h1>
                            <div style="font-size:16px; font-weight:bold; letter-spacing:2px; font-family: 'Arial', sans-serif;">DAR ALAMIRAT</div>
                        </div>
                        <h2 style="margin:20px 0 0 0; font-weight:bold; font-size:26px; text-decoration:underline;">استلام عهدة اصل</h2>
                    </div>

                    <!-- Dates -->
                    <div style="display:flex; justify-content:space-between; margin-bottom:20px; font-weight:bold; font-size:16px;">
                        <div>التاريخ: .... / .... / .... 14هـ</div>
                        <div>التاريخ: ${topDateG}</div>
                    </div>

                    <!-- Table 1: Receiver Info -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:25px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="6" style="background:#e6e6e6; font-weight:bold; padding:10px; border: 1.5px solid #000; border-bottom: 2px solid #000;">بيانات المستلم</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:10px; width:15%;">اسم الموظف</td>
                            <td style="border: 1.5px solid #000; padding:10px; width:35%; text-align:right; padding-right:15px;">${staffName}</td>
                            <td style="border: 1.5px solid #000; padding:10px; width:10%;">الإدارة</td>
                            <td style="border: 1.5px solid #000; padding:10px; width:15%; text-align:right; padding-right:15px;">${dept}</td>
                            <td style="border: 1.5px solid #000; padding:10px; width:10%;">المسمى الوظيفي</td>
                            <td style="border: 1.5px solid #000; padding:10px; width:15%; text-align:right; padding-right:15px;">${staffTitle}</td>
                        </tr>
                    </table>

                    <!-- Table 2: Items -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:25px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="5" style="background:#e6e6e6; font-weight:bold; padding:10px; border: 1.5px solid #000; border-bottom: 2px solid #000;">بيانات العهدة</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:10px; width:5%;">م</th>
                            <th style="border: 1.5px solid #000; padding:10px; width:45%;">الوصف</th>
                            <th style="border: 1.5px solid #000; padding:10px; width:15%;">النوع</th>
                            <th style="border: 1.5px solid #000; padding:10px; width:10%;">الكمية</th>
                            <th style="border: 1.5px solid #000; padding:10px; width:25%;">ملاحظة</th>
                        </tr>
                        ${itemsHtml}
                    </table>

                    <!-- Table 3: Declaration -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:25px; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:10px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">إقرار</td>
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
    }
};
