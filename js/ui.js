// UI Helper Functions
const ui = {
    showView(viewId) {
        const viewEl = document.getElementById(`view-${viewId}`);
        if (!viewEl) {
            console.error(`View element view-${viewId} not found`);
            return;
        }

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
        if (!tbody) return;
        tbody.innerHTML = '';

        if (requests.length === 0) {
            tbody.innerHTML = `<tr><td colspan="6" class="text-center py-4 text-muted">${i18nManager.currentLang === 'ar' ? 'لم يتم العثور على طلبات' : 'No requests found'}</td></tr>`;
            return;
        }

        requests.forEach(req => {
            const date = new Date(req.created_at).toLocaleDateString();
            const statusClass = `badge-${req.status}`;
            const userName = req.profiles ? req.profiles.full_name : 'Unknown';
            
            tbody.innerHTML += `
                <tr>
                    <td class="ps-4 fw-medium text-primary">#${req.id.substring(0, 8)}</td>
                    <td>${req.subject}</td>
                    <td>${userName}</td>
                    <td><span class="badge ${statusClass}">${i18nManager.get(req.status === 'rejected' ? 'rejected_status' : req.status)}</span></td>
                    <td>${date}</td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-outline-primary view-details-btn" data-id="${req.id}">
                            ${i18nManager.get('action')}
                        </button>
                    </td>
                </tr>
            `;
        });
    },

    updateUserUI(user) {
        document.getElementById('userName').innerText = user.profile.full_name;
        document.getElementById('userRole').innerText = i18nManager.get(user.profile.role);
        
        const initials = user.profile.full_name.split(' ').map(n => n[0]).join('').toUpperCase();
        document.getElementById('userInitials').innerText = initials;

        // Role-based sidebar visibility
        const role = user.profile.role;
        const linkAdmin = document.getElementById('link-admin');
        const linkApprovals = document.getElementById('link-approvals');
        const linkAllRequests = document.getElementById('link-all-requests');
        const linkReports = document.getElementById('link-reports');

        if (linkAdmin && role !== 'admin') linkAdmin.classList.add('d-none');
        if (role === 'employee') {
            if (linkApprovals) linkApprovals.classList.add('d-none');
            if (linkAllRequests) linkAllRequests.classList.add('d-none');
            if (linkReports) linkReports.classList.add('d-none');
        }
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
        const tbody = document.getElementById('profilesTableBody');
        if (!tbody) return;
        tbody.innerHTML = '';

        if (profiles.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4 text-muted">No profiles found</td></tr>';
            return;
        }

        profiles.forEach(profile => {
            tbody.innerHTML += `
                <tr>
                    <td class="ps-4 fw-medium">${profile.full_name}</td>
                    <td>${profile.email || '-'}</td>
                    <td><span class="badge bg-secondary">${i18nManager.get(profile.role)}</span></td>
                    <td>${profile.department || '-'}</td>
                    <td class="text-end pe-4">
                        <button class="btn btn-sm btn-outline-primary edit-profile-btn" 
                                data-id="${profile.id}" 
                                data-name="${profile.full_name}"
                                data-email="${profile.email || ''}"
                                data-role="${profile.role}"
                                data-title="${profile.job_title || ''}"
                                data-dept="${profile.department || ''}">
                            <i data-lucide="edit-3" style="width:14px;"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger delete-profile-btn" data-id="${profile.id}" data-name="${profile.full_name}">
                            <i data-lucide="trash-2" style="width:14px;"></i>
                        </button>
                    </td>
                </tr>
            `;
        });
        lucide.createIcons();
    },

    toggleProfileForm(showForm) {
        if (showForm) {
            document.getElementById('profile-list-section')?.classList.add('d-none');
            document.getElementById('profile-form-section')?.classList.remove('d-none');
        } else {
            document.getElementById('profile-list-section')?.classList.remove('d-none');
            document.getElementById('profile-form-section')?.classList.add('d-none');
            document.getElementById('createUserForm')?.reset();
            document.getElementById('profile_id').value = '';
            document.getElementById('passwordHint').classList.add('d-none');
            document.getElementById('password').required = true;
            document.getElementById('profileFormTitle').innerText = i18nManager.get('createUser');
        }
    }
};
