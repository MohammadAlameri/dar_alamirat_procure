// Reports View Logic
let currentReportData = [];

async function loadReportsView() {
    ui.setLoading(true);
    try {
        // Populate filter dropdowns
        const branches = await db.getAllBranches();
        const profiles = await db.getAllProfiles();
        const categories = await db.getAllCategories();

        const branchSelect = document.getElementById('rep_branch');
        const staffSelect = document.getElementById('rep_staff');
        const catSelect = document.getElementById('rep_category');
        const statusSelect = document.getElementById('rep_status');

        if (branchSelect) {
            branchSelect.innerHTML = `<option value="all">${i18nManager.get('all')}</option>` +
                branches.map(b => `<option value="${b.id}">${i18nManager.currentLang === 'ar' ? (b.name_ar || b.name) : b.name}</option>`).join('');
        }

        if (staffSelect) {
            staffSelect.innerHTML = `<option value="all">${i18nManager.get('all')}</option>` +
                profiles.map(p => `<option value="${p.id}">${p.full_name}</option>`).join('');
        }

        if (catSelect) {
            catSelect.innerHTML = `<option value="all">${i18nManager.get('all')}</option>` +
                categories.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
        }

        // Common statuses
        const statuses = ['pending', 'manager_approved', 'finance_approved', 'rejected_by_manager', 'rejected_by_finance', 'completed', 'paid', 'received'];
        if (statusSelect) {
            statusSelect.innerHTML = `<option value="all">${i18nManager.get('all')}</option>` +
                statuses.map(s => `<option value="${s}">${i18nManager.get(s)}</option>`).join('');
        }

    } catch (err) {
        console.error("Error loading report filters:", err);
    } finally {
        ui.setLoading(false);
    }
}

async function generateReport(e) {
    if (e) e.preventDefault();
    ui.setLoading(true);

    const type = document.getElementById('rep_type').value;
    const filters = {
        branchId: document.getElementById('rep_branch').value !== 'all' ? document.getElementById('rep_branch').value : null,
        userId: document.getElementById('rep_staff').value !== 'all' ? document.getElementById('rep_staff').value : null,
        status: document.getElementById('rep_status').value !== 'all' ? document.getElementById('rep_status').value : null,
        dateFrom: document.getElementById('rep_date_from').value || null,
        dateTo: document.getElementById('rep_date_to').value || null,
        categoryId: type === 'procure' && document.getElementById('rep_category').value !== 'all' ? document.getElementById('rep_category').value : null
    };

    try {
        let data = [];
        if (type === 'procure') {
            data = await db.getRequests(filters);
        } else {
            data = await db.getExpenseRequests(filters);
        }

        currentReportData = data;
        renderReportTable(data, type);
        updateReportStats(data, type);
    } catch (err) {
        console.error("Error generating report:", err);
        ui.showNotification("Error generating report", "error");
    } finally {
        ui.setLoading(false);
    }
}

function renderReportTable(data, type) {
    const head = document.getElementById('reportTableHead');
    const body = document.getElementById('reportTableBody');
    if (!head || !body) return;

    if (type === 'procure') {
        head.innerHTML = `
            <th class="ps-4">${i18nManager.get('date')}</th>
            <th>${i18nManager.get('subject')}</th>
            <th>${i18nManager.get('requester')}</th>
            <th>${i18nManager.get('status')}</th>
            <th class="text-end pe-4">${i18nManager.get('total')}</th>
        `;
        body.innerHTML = data.map(r => `
            <tr>
                <td class="ps-4 small">${new Date(r.created_at).toLocaleDateString()}</td>
                <td class="fw-bold">${r.subject}</td>
                <td>${r.profiles?.full_name || '-'}</td>
                <td><span class="badge badge-${r.status} small">${i18nManager.get(r.status)}</span></td>
                <td class="text-end pe-4 fw-bold">${(r.total_amount || 0).toLocaleString()}</td>
            </tr>
        `).join('') || `<tr><td colspan="5" class="text-center py-4 text-muted">${i18nManager.get('noRequestsFound')}</td></tr>`;
    } else {
        head.innerHTML = `
            <th class="ps-4">${i18nManager.get('date')}</th>
            <th>${i18nManager.get('subject')}</th>
            <th>${i18nManager.get('requester')}</th>
            <th>${i18nManager.get('status')}</th>
            <th class="text-end pe-4">${i18nManager.get('amount')}</th>
        `;
        body.innerHTML = data.map(r => `
            <tr>
                <td class="ps-4 small">${new Date(r.created_at).toLocaleDateString()}</td>
                <td class="fw-bold">${r.subject}</td>
                <td>${r.profiles?.full_name || '-'}</td>
                <td><span class="badge badge-${r.status} small">${i18nManager.get(r.status)}</span></td>
                <td class="text-end pe-4 fw-bold">${(r.amount || 0).toLocaleString()}</td>
            </tr>
        `).join('') || `<tr><td colspan="5" class="text-center py-4 text-muted">${i18nManager.get('noRequestsFound')}</td></tr>`;
    }
}

function updateReportStats(data, type) {
    const countEl = document.getElementById('repStat_count');
    const amountEl = document.getElementById('repStat_amount');
    const completedEl = document.getElementById('repStat_completed');

    if (!countEl || !amountEl || !completedEl) return;

    const count = data.length;
    const totalAmount = data.reduce((sum, r) => sum + (type === 'procure' ? (r.total_amount || 0) : (r.amount || 0)), 0);
    const completedCount = data.filter(r => ['completed', 'received', 'paid'].includes(r.status)).length;

    countEl.innerText = count;
    amountEl.innerText = totalAmount.toLocaleString(undefined, { minimumFractionDigits: 2 });
    completedEl.innerText = completedCount;
}

function exportReportToCsv() {
    if (!currentReportData || currentReportData.length === 0) {
        ui.showNotification("No data to export", "warning");
        return;
    }

    const type = document.getElementById('rep_type').value;
    let headers = [];
    let rows = [];

    // Helper to escape CSV fields
    const escape = (val) => {
        if (val === null || val === undefined) return '""';
        const str = String(val).replace(/"/g, '""');
        return `"${str}"`;
    };

    if (type === 'procure') {
        headers = ['Date', 'Subject', 'Requester', 'Status', 'Total Price'];
        rows = currentReportData.map(r => [
            new Date(r.created_at).toLocaleDateString(),
            escape(r.subject),
            escape(r.profiles?.full_name),
            escape(r.status),
            r.total_amount || 0
        ]);
    } else {
        headers = ['Date', 'Subject', 'Requester', 'Status', 'Amount'];
        rows = currentReportData.map(r => [
            new Date(r.created_at).toLocaleDateString(),
            escape(r.subject),
            escape(r.profiles?.full_name),
            escape(r.status),
            r.amount || 0
        ]);
    }

    let csvContent = headers.join(",") + "\n"
        + rows.map(e => e.join(",")).join("\n");

    // Add UTF-8 BOM so Excel opens it with the correct encoding for Arabic
    const BOM = "\uFEFF";
    const blob = new Blob([BOM + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);

    const link = document.createElement("a");
    link.style.display = 'none';
    link.setAttribute("href", url);
    link.setAttribute("download", `report_${type}_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

// Event Listeners
document.getElementById('reportFilterForm')?.addEventListener('submit', generateReport);
document.getElementById('exportCsvBtn')?.addEventListener('click', exportReportToCsv);
document.getElementById('rep_type')?.addEventListener('change', (e) => {
    const procureOnly = document.querySelectorAll('.procure-only');
    procureOnly.forEach(el => el.classList.toggle('d-none', e.target.value !== 'procure'));
});
