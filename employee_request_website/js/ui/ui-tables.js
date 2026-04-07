window.ui = window.ui || {};
Object.assign(window.ui, {
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


});
