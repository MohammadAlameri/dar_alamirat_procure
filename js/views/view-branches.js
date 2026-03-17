// Branch Management View
async function loadBranchManagement() {
    ui.setLoading(true);
    try {
        const branches = await db.getAllBranches();
        ui.renderBranchesTable(branches);
    } catch (err) {
        console.error("Error loading branches:", err);
        ui.showNotification("Error loading branches", "error");
    } finally {
        ui.setLoading(false);
    }
}

Object.assign(window.ui, {
    renderBranchesTable(branches) {
        const tbody = document.getElementById('branchesTableBody');
        if (!tbody) return;

        const isAr = (localStorage.getItem('lang') || 'en') === 'ar';

        tbody.innerHTML = branches.map(b => `
            <tr>
                <td class="ps-4">
                    <div class="fw-bold text-dark">${b.name}</div>
                    <div class="small text-muted">${b.name_ar || ''}</div>
                </td>
                <td><span class="badge bg-light text-dark border">${b.code}</span></td>
                <td>${b.address || '-'}</td>
                <td class="text-end pe-4">
                    <button class="btn btn-sm btn-outline-primary me-1" onclick="ui.showBranchModal('${b.id}')" title="Edit">
                        <i data-lucide="edit" style="width: 14px;"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-info me-1" onclick="ui.showUserBranchModal('${b.id}')" title="Users">
                        <i data-lucide="users" style="width: 14px;"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="ui.deleteBranch('${b.id}')" title="Delete">
                        <i data-lucide="trash-2" style="width: 14px;"></i>
                    </button>
                </td>
            </tr>
        `).join('') || `<tr><td colspan="4" class="text-center py-4 text-muted">No branches found.</td></tr>`;

        lucide.createIcons();
    },

    async showBranchModal(branchId = null) {
        const modal = new bootstrap.Modal(document.getElementById('branchModal'));
        const form = document.getElementById('branchForm');
        form.reset();
        document.getElementById('branch_id_input').value = branchId || '';
        document.getElementById('branchFormTitle').innerText = i18nManager.get(branchId ? 'editBranch' : 'addBranch');

        if (branchId) {
            try {
                const { data: branch, error } = await supabaseClient.from('branches').select('*').eq('id', branchId).single();
                if (error) throw error;
                document.getElementById('branch_name_input').value = branch.name;
                document.getElementById('branch_name_ar_input').value = branch.name_ar || '';
                document.getElementById('branch_code_input').value = branch.code;
                document.getElementById('branch_address_input').value = branch.address || '';
            } catch (err) {
                console.error("Error fetching branch details:", err);
            }
        }

        modal.show();
    },

    async deleteBranch(branchId) {
        if (!confirm(i18nManager.get('confirmDelete'))) return;
        
        ui.setLoading(true);
        try {
            await db.deleteBranch(branchId);
            ui.showNotification(i18nManager.get('deletedSuccessfully'), 'success');
            await loadBranchManagement();
        } catch (err) {
            ui.showNotification("Error deleting branch: " + err.message, "error");
        } finally {
            ui.setLoading(false);
        }
    },

    async showUserBranchModal(branchId) {
        const modal = new bootstrap.Modal(document.getElementById('userBranchModal'));
        document.getElementById('ub_branch_id').value = branchId;
        
        // Populate user select
        try {
            const profiles = await db.getAllProfiles();
            const select = document.getElementById('ub_user_select');
            select.innerHTML = '<option value="" disabled selected>Select User</option>' + 
                profiles.map(p => `<option value="${p.id}">${p.full_name} (${i18nManager.get(p.role)})</option>`).join('');
            
            await ui.refreshAssignedUsers(branchId);
        } catch (err) {
            console.error("Error populating users:", err);
        }

        modal.show();
    },

    async refreshAssignedUsers(branchId) {
        try {
            const { data: users, error } = await supabaseClient
                .from('user_branches')
                .select('*, profiles:user_id (full_name, role)')
                .eq('branch_id', branchId);
            
            if (error) throw error;

            const tbody = document.getElementById('assignedUsersTableBody');
            tbody.innerHTML = users.map(u => `
                <tr>
                    <td>${u.profiles?.full_name}</td>
                    <td><span class="badge ${u.access_level === 'full' ? 'bg-success' : 'bg-secondary'}">${u.access_level.toUpperCase()}</span></td>
                    <td>
                        <button class="btn btn-sm btn-link text-danger p-0" onclick="ui.removeUserFromBranch('${u.id}', '${branchId}')">
                            <i data-lucide="x-circle" style="width: 14px;"></i>
                        </button>
                    </td>
                </tr>
            `).join('') || '<tr><td colspan="3" class="text-center text-muted">No users assigned.</td></tr>';
            
            lucide.createIcons();
        } catch (err) {
            console.error("Error refreshing assigned users:", err);
        }
    },

    async removeUserFromBranch(assignmentId, branchId) {
        if (!confirm(i18nManager.get('confirmDelete'))) return;
        try {
            await db.removeUserFromBranch(assignmentId);
            await ui.refreshAssignedUsers(branchId);
            ui.showNotification("User removed from branch", "success");
        } catch (err) {
            ui.showNotification("Error removing user: " + err.message, "error");
        }
    }
});

// Event Listeners
document.getElementById('branchForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const branchId = document.getElementById('branch_id_input').value;
    const branchData = {
        name: document.getElementById('branch_name_input').value,
        name_ar: document.getElementById('branch_name_ar_input').value,
        code: document.getElementById('branch_code_input').value,
        address: document.getElementById('branch_address_input').value
    };

    ui.setLoading(true);
    try {
        if (branchId) {
            await db.updateBranch(branchId, branchData);
            ui.showNotification(i18nManager.get('updatedSuccessfully'), 'success');
        } else {
            await db.createBranch(branchData);
            ui.showNotification(i18nManager.get('createdSuccessfully'), 'success');
        }
        bootstrap.Modal.getInstance(document.getElementById('branchModal')).hide();
        await loadBranchManagement();
    } catch (err) {
        ui.showNotification("Error saving branch: " + err.message, "error");
    } finally {
        ui.setLoading(false);
    }
});

document.getElementById('userBranchForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const branchId = document.getElementById('ub_branch_id').value;
    const userId = document.getElementById('ub_user_select').value;
    const accessLevel = document.getElementById('ub_access_level').value;

    try {
        await db.assignUserToBranch(userId, branchId, accessLevel);
        ui.showNotification("User assigned to branch", "success");
        await ui.refreshAssignedUsers(branchId);
    } catch (err) {
        ui.showNotification("Error assigning user: " + err.message, "error");
    }
});
