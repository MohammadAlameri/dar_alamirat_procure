window.ui = window.ui || {};
Object.assign(window.ui, {
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
        const modalEl = document.getElementById('profileModal');
        if (!modalEl) return;
        
        let modal = bootstrap.Modal.getInstance(modalEl);
        if (!modal) modal = new bootstrap.Modal(modalEl);

        if (showForm) {
            this.updateManagerFieldVisibility();
            modal.show();
        } else {
            modal.hide();
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

    renderCategoriesTable(categories) {
        const tbody = document.getElementById('categoriesTableBody');
        if (!tbody) return;
        tbody.innerHTML = '';
        if (!categories || categories.length === 0) {
            tbody.innerHTML = `<tr><td colspan="2" class="text-center py-3 text-muted">No categories</td></tr>`;
            return;
        }
        categories.forEach(cat => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="ps-4">${cat.name}</td>
                <td class="text-end pe-4">
                    <button class="btn btn-sm btn-outline-primary edit-category-btn" data-id="${cat.id}" data-name="${cat.name}">
                        <i data-lucide="edit-3" style="width:14px;"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger delete-category-btn" data-id="${cat.id}">
                        <i data-lucide="trash-2" style="width:14px;"></i>
                    </button>
                </td>
            `;
            tbody.appendChild(tr);
        });
        if (typeof lucide !== 'undefined') lucide.createIcons();
    },

    renderProductsTable(products) {
        const tbody = document.getElementById('productsTableBody');
        if (!tbody) return;
        tbody.innerHTML = '';
        if (!products || products.length === 0) {
            tbody.innerHTML = `<tr><td colspan="3" class="text-center py-3 text-muted">No products</td></tr>`;
            return;
        }
        products.forEach(p => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="ps-4">${p.name}</td>
                <td>${p.categories?.name || '-'}</td>
                <td class="text-end pe-4">
                    <button class="btn btn-sm btn-outline-primary edit-product-btn" data-id="${p.id}" data-name="${p.name}" data-catid="${p.category_id}">
                        <i data-lucide="edit-3" style="width:14px;"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger delete-product-btn" data-id="${p.id}">
                        <i data-lucide="trash-2" style="width:14px;"></i>
                    </button>
                </td>
            `;
            tbody.appendChild(tr);
        });
        if (typeof lucide !== 'undefined') lucide.createIcons();
    },

    toggleCategoryForm(show) {
        const modalEl = document.getElementById('categoryModal');
        if (!modalEl) return;
        
        let modal = bootstrap.Modal.getInstance(modalEl);
        if (!modal) modal = new bootstrap.Modal(modalEl);

        if (show) {
            modal.show();
        } else {
            modal.hide();
            document.getElementById('categoryForm').reset();
            document.getElementById('category_id').value = '';
            document.getElementById('categoryFormTitle').innerText = i18nManager.get('addCategory');
            document.getElementById('categoryFormTitle').setAttribute('data-i18n', 'addCategory');
        }
    },

    toggleProductForm(show) {
        const modalEl = document.getElementById('productModal');
        if (!modalEl) return;
        
        let modal = bootstrap.Modal.getInstance(modalEl);
        if (!modal) modal = new bootstrap.Modal(modalEl);

        if (show) {
            modal.show();
        } else {
            modal.hide();
            document.getElementById('productForm').reset();
            document.getElementById('pm_product_id').value = '';
            document.getElementById('productFormTitle').innerText = i18nManager.get('addProduct');
            document.getElementById('productFormTitle').setAttribute('data-i18n', 'addProduct');
        }
    },

    populateCategorySelects(categories) {
        const selects = document.querySelectorAll('.category-select, #filterCategoryDropdown, #pm_product_category');
        selects.forEach(select => {
            const isFilter = select.id === 'filterCategoryDropdown';
            const currentValue = select.value;
            select.innerHTML = isFilter ? `<option value="all" data-i18n="allCategories">${i18nManager.get('allCategories')}</option>` : `<option value="" disabled selected data-i18n="selectCategory">${i18nManager.get('selectCategory')}</option>`;
            categories.forEach(cat => {
                const opt = document.createElement('option');
                opt.value = cat.id;
                opt.innerText = cat.name;
                select.appendChild(opt);
            });
            if (currentValue) select.value = currentValue;
        });
    },


});
