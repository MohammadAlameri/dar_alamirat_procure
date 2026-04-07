window.ui = window.ui || {};
Object.assign(window.ui, {
    printExpenseReceipt(exp, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) return;

        // Dates
        const dateObj = new Date(exp.updated_at || exp.created_at);
        const daysAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
        const dayOfWeek = daysAr[dateObj.getDay()];
        let hijriDate = '';
        try {
            hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(dateObj).replace(/[هـ]/g, '').trim() + ' هـ';
        } catch(e) { hijriDate = dateObj.toLocaleDateString('ar') + ' هـ'; }
        const gregorianDate = dateObj.toLocaleDateString('en-GB');
        const topDateG = new Date(exp.created_at).toLocaleDateString('en-GB');
        let timeStr = dateObj.toLocaleTimeString('ar-SA', {hour: '2-digit', minute:'2-digit'});

        const employeeName = exp.employee_name || '';
        const employeeTitle = exp.profiles?.job_title || '';
        const employeeDept = exp.profiles?.department || '';
        const amount = exp.amount ? Number(exp.amount).toFixed(2) : '0.00';

        const paidApproval = approvals.find(a => a.action === 'paid');
        const accountantName = paidApproval?.profiles?.full_name || '...........................................';
        let paidDate = '';
        if (paidApproval) {
            try { paidDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(paidApproval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ'; } catch(e) { paidDate = ''; }
        }
        const paidGregorianDate = paidApproval ? new Date(paidApproval.created_at).toLocaleDateString('en-GB') : '';

        const receivedApproval = approvals.find(a => a.action === 'received');
        const isReceived = exp.status === 'completed' || !!receivedApproval;

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
                        <h2 style="margin:10px 0 0 0; font-weight:bold; font-size:26px; text-decoration:underline;">سند استلام مبلغ مصاريف</h2>
                    </div>

                    <!-- Dates -->
                    <div style="display:flex; justify-content:space-between; margin-bottom:20px; font-weight:bold; font-size:16px;">
                        <div>التاريخ: .... / .... / .... 14هـ</div>
                        <div>التاريخ: ${topDateG}</div>
                    </div>

                    <!-- Table 1: Employee Info -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="6" style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; border-bottom: 2px solid #000;">بيانات المستلم</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%;">اسم الموظف</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:35%; text-align:right; padding-right:15px;">${employeeName}</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:10%;">الإدارة</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%; text-align:right; padding-right:15px;">${employeeDept}</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:10%;">المسمى الوظيفي</td>
                            <td style="border: 1.5px solid #000; padding:8px; width:15%; text-align:right; padding-right:15px;">${employeeTitle}</td>
                        </tr>
                    </table>

                    <!-- Table 2: Expense Details -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px; text-align:center;">
                        <tr>
                            <td colspan="4" style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; border-bottom: 2px solid #000;">تفاصيل المصروف</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px; width:15%;">الموضوع</th>
                            <td colspan="3" style="border: 1.5px solid #000; padding:8px; text-align:right; padding-right:15px;">${exp.subject}</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px;">البيان</th>
                            <td colspan="3" style="border: 1.5px solid #000; padding:8px; text-align:right; padding-right:15px;">${exp.statement || ''}</td>
                        </tr>
                        <tr>
                            <th style="border: 1.5px solid #000; padding:8px;">المبلغ</th>
                            <td style="border: 1.5px solid #000; padding:8px; font-weight:bold; font-size:18px;">${amount} ريال</td>
                            <th style="border: 1.5px solid #000; padding:8px;">رقم الطلب</th>
                            <td style="border: 1.5px solid #000; padding:8px;">#${exp.id.substring(0, 8)}</td>
                        </tr>
                    </table>

                    <!-- Table 3: Declaration -->
                    <table style="width:100%; border-collapse:collapse; margin-bottom:15px; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:8px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">إقرار باستلام المبلغ</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:20px; line-height:2.2;">
                                أقر أنا الموقع أدناه / <strong>${employeeName}</strong> بأنني استلمت مبلغ وقدره <strong>${amount}</strong> ريال وذلك بموجب طلب صرف مصاريف رقم <strong>#${exp.id.substring(0, 8)}</strong> عن <strong>${exp.subject}</strong> وذلك في يوم / <strong>${dayOfWeek}</strong> الموافق <strong>${gregorianDate}</strong> / <strong>${hijriDate}</strong> في تمام الساعة <strong>${timeStr}</strong>.
                                <br><br>
                                وأتعهد بصرف المبلغ في الغرض المخصص له وتقديم المستندات المؤيدة خلال المدة المحددة.
                                <div style="display:flex; justify-content:space-between; margin-top:35px; font-weight:bold; padding:0 30px;">
                                    <div>المستلم/ <span style="font-weight:normal; text-decoration:underline;">${employeeName}</span></div>
                                    <div>التوقيع/ ...........................................</div>
                                </div>
                                <br>
                            </td>
                        </tr>
                    </table>

                    <!-- Table 4: Payment Officer Details -->
                    <table style="width:100%; border-collapse:collapse; border: 1.5px solid #000; font-size:16px;">
                        <tr>
                            <td style="background:#e6e6e6; font-weight:bold; padding:10px; border: 1.5px solid #000; text-align:center; border-bottom: 2px solid #000;">خاص بمسؤول الصرف (محاسب العهدة)</td>
                        </tr>
                        <tr>
                            <td style="border: 1.5px solid #000; padding:20px; line-height:2.2;">
                                <div style="display:flex; justify-content:flex-start; gap:80px; font-weight:bold; margin-bottom:20px;">
                                    <div>تم صرف المبلغ بحالة ( ${isReceived ? '✔' : '&nbsp;&nbsp;&nbsp;'} ) نعم</div>
                                </div>
                                <div style="display:flex; justify-content:space-between; align-items:center; margin-top:25px; font-weight:bold;">
                                    <div>تم الصرف في يوم/ <strong>${paidApproval ? daysAr[new Date(paidApproval.created_at).getDay()] : '............'}</strong></div>
                                    <div style="flex-grow:1; text-align:center;">الموافق <strong>${paidGregorianDate || '.... / .... / ....'}</strong> / <strong>${paidDate || '.... / .... / .... هـ'}</strong></div>
                                </div>
                                <div style="display:flex; justify-content:space-between; margin-top:35px; font-weight:bold; padding:0 30px;">
                                    <div>مسؤول الصرف: <span style="font-weight:normal; text-decoration:underline;">${accountantName}</span></div>
                                    <div>التوقيع: ...........................................</div>
                                </div>
                                <br>
                            </td>
                        </tr>
                    </table>

                </div>
                
                <!-- Bottom Footer -->
                <div style="margin-top:15px; text-align:center; font-size:12px; color:#555;">
                    الأصل: ملف الموظف | نسخة: المستلم | نسخة: الإدارة المالية
                </div>
            </div>
        `;

        window.print();
    },
});
