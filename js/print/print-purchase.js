window.ui = window.ui || {};
Object.assign(window.ui, {
    printRequest(req, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) {
            ui.showNotification(i18nManager.get('errorPrintContainer'), 'error');
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
});
