window.ui = window.ui || {};
Object.assign(window.ui, {
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
        const gregorianDate = dateObj.toLocaleDateString('en-GB');
        const topDateG = new Date(req.created_at || new Date()).toLocaleDateString('en-GB');

        let timeStr = dateObj.toLocaleTimeString('ar-SA', {hour: '2-digit', minute:'2-digit'});

        const requester = req.profiles || {};
        const staffName = req.requested_by_name || requester.full_name || '';
        const staffTitle = req.requested_by_title || (requester.job_title || '');
        const dept = requester.department || '';

        let itOfficerName = '';
        if (req.status === 'completed' && currentUser && currentUser.profile.role === 'it_procurement') {
            itOfficerName = currentUser.profile.full_name;
        } else if (req.status === 'completed' || req.status === 'received_by_staff') {
            itOfficerName = '...........................................';
        }

        // Items HTML
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

        const isAccepted = req.staff_acceptance_status === 'accepted' || req.status === 'received_by_staff';
        const isRejected = req.staff_acceptance_status === 'rejected' || req.status === 'rejected_by_staff';
        const checkAccepted = isAccepted ? '✔' : '&nbsp;&nbsp;&nbsp;';
        const checkRejected = isRejected ? '✔' : '&nbsp;&nbsp;&nbsp;';

        let rejectionSection = '';
        if (req.staff_rejection_reason) {
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

                </div>
                
                <!-- Bottom Footer -->
                <div style="margin-top:15px; text-align:center; font-size:12px; color:#555;">
                    الأصل: ملف الموظف | نسخة: المستلم | نسخة: إدارة تقنية المعلومات
                </div>
            </div>
        `;

        window.print();
    },
});
