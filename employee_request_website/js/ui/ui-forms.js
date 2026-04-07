window.ui = window.ui || {};
Object.assign(window.ui, {
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
            <td>
                <select class="form-select category-select" name="category_id[]" required>
                    <option value="" disabled selected>${i18nManager.get('selectCategory')}</option>
                    ${globalCategories ? globalCategories.map(c => `<option value="${c.id}">${c.name}</option>`).join('') : ''}
                </select>
            </td>
            <td>
                <div class="position-relative">
                    <input type="text" class="form-control product-search" name="product_name[]" required autocomplete="off" placeholder="${i18nManager.get('searchProduct')}">
                    <input type="hidden" name="product_id[]" class="product-id-input">
                    <div class="product-results dropdown-menu w-100"></div>
                </div>
            </td>
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
        if (typeof lucide !== 'undefined') lucide.createIcons();
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
                        <td>
                            <select class="form-select category-select" name="category_id[]" required>
                                <option value="" disabled>${i18nManager.get('selectCategory')}</option>
                                ${globalCategories.map(c => `<option value="${c.id}" ${item.category_id === c.id ? 'selected' : ''}>${c.name}</option>`).join('')}
                            </select>
                        </td>
                        <td>
                            <div class="position-relative">
                                <input type="text" class="form-control product-search" name="product_name[]" value="${item.product_name || ''}" required autocomplete="off" placeholder="${i18nManager.get('searchProduct')}">
                                <input type="hidden" name="product_id[]" value="${item.product_id || ''}" class="product-id-input">
                                <div class="product-results dropdown-menu w-100"></div>
                            </div>
                        </td>
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


});
