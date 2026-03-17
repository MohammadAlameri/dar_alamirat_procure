window.ui = window.ui || {};
Object.assign(window.ui, {
    showView(viewId) {
        // Simple client-side authorization
        const role = currentUser?.profile?.role;
        if (viewId === 'user-management' && role !== 'admin') {
            viewId = 'overview';
        }
        if (viewId === 'branch-management' && role !== 'admin') {
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
            'expense-requests': i18nManager.get('expenseRequests'),
            'product-management': i18nManager.get('productManagement'),
            'branch-management': i18nManager.get('branchManagement')
        };
        document.getElementById('currentViewTitle').innerText = titleMap[viewId] || i18nManager.get('requestDetails');
        
        lucide.createIcons();
    },

    setLoading(isLoading) {
        const loader = document.getElementById('loader');
        if (isLoading) loader.classList.remove('d-none');
        else loader.classList.add('d-none');
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
            reports: document.getElementById('link-reports'),
            products: document.getElementById('link-products'),
            branches: document.getElementById('link-branches')
        };

        if (links.admin) links.admin.classList.toggle('d-none', role !== 'admin');
        
        if (links.all) {
            const canSeeAll = ['admin', 'it_procurement', 'finance', 'general_manager', 'manager', 'accountant'].includes(role);
            links.all.classList.toggle('d-none', !canSeeAll);
        }

        if (links.approvals) {
            const canApprove = ['admin', 'it_procurement', 'finance', 'manager', 'general_manager', 'accountant', 'employee'].includes(role);
            links.approvals.classList.toggle('d-none', !canApprove);
        }

        if (links.reports) {
            const canSeeReports = ['admin', 'it_procurement', 'finance', 'general_manager', 'manager', 'accountant'].includes(role);
            links.reports.classList.toggle('d-none', !canSeeReports);
        }
        if (links.products) links.products.classList.toggle('d-none', role !== 'admin');
        if (links.branches) links.branches.classList.toggle('d-none', role !== 'admin');
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
    },

    renderBranchSelector(userBranches, currentBranchId) {
        const selector = document.getElementById('branchSelector');
        if (!selector) return;

        const isAr = (localStorage.getItem('lang') || 'en') === 'ar';
        
        selector.innerHTML = userBranches.map(ub => {
            const branchName = isAr ? (ub.branches.name_ar || ub.branches.name) : ub.branches.name;
            const levelLabel = ub.access_level === 'full' ? '' : ` (${isAr ? 'عرض فقط' : 'View Only'})`;
            return `<option value="${ub.branch_id}" ${ub.branch_id === currentBranchId ? 'selected' : ''}>${branchName}${levelLabel}</option>`;
        }).join('');

        // If no branches, hide container
        const container = document.getElementById('branchSelectorContainer');
        if (container) {
            container.classList.toggle('d-none', userBranches.length === 0);
        }

        // Add change listener if not already added
        if (!selector.dataset.listenerAdded) {
            selector.addEventListener('change', async (e) => {
                const branchId = e.target.value;
                permissions.setCurrentBranch(branchId);
                ui.setLoading(true);
                try {
                    await loadDashboardData();
                } finally {
                    ui.setLoading(false);
                }
            });
            selector.dataset.listenerAdded = 'true';
        }
    }

});
