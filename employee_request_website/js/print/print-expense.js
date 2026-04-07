window.ui = window.ui || {};
Object.assign(window.ui, {
    printExpenseRequest(exp, approvals = []) {
        const container = document.getElementById('print-container');
        if (!container) {
            ui.showNotification(i18nManager.get('errorPrintContainer'), 'error');
            return;
        }

        // Format dates
        let hijriDate = '';
        try {
            const date = new Date(exp.created_at);
            hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day: 'numeric', month: 'numeric', year: 'numeric'}).format(date).replace(/[هـ]/g, '').trim() + ' هـ';
        } catch(e) {
            hijriDate = new Date(exp.created_at).toLocaleDateString('ar') + ' هـ';
        }
        const gregorianDate = new Date(exp.created_at).toLocaleDateString('en-GB');

        const employeeName = exp.employee_name || '';
        const employeeTitle = exp.profiles?.job_title || '';
        const employeeDept = exp.profiles?.department || '';
        const amount = exp.amount ? Number(exp.amount).toFixed(2) : '0.00';

        const levelLabels = {
            manager: 'المدير المباشر',
            finance: 'الادارة المالية',
            general_manager: 'المدير العام'
        };
        const levelLabel = levelLabels[exp.highest_approval_level] || exp.highest_approval_level;

        const managerApproval = approvals.find(a => a.action === 'manager_approved');
        const financeApproval = approvals.find(a => a.action === 'finance_approved');
        const gmApproval = approvals.find(a => a.action === 'gm_approved');
        const paidApproval = approvals.find(a => a.action === 'paid');

        const getApproverName = (approval) => approval?.profiles?.full_name || '';
        const getApprovalDate = (approval) => {
            if (!approval) return '&nbsp;&nbsp;/&nbsp;&nbsp;/&nbsp;&nbsp;&nbsp;١٤هـ';
            try {
                return new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {day:'numeric',month:'numeric',year:'numeric'}).format(new Date(approval.created_at)).replace(/[هـ]/g, '').trim() + ' هـ';
            } catch(e) { return ''; }
        };

        container.innerHTML = `
            <div class="print-content" dir="rtl" style="direction:rtl; text-align:right; font-family: 'Times New Roman', 'Traditional Arabic', serif; color:#000; padding:2mm 10mm; max-width:210mm; margin:0 auto;">
                
                <!-- Header -->
                <div style="border:1.5px solid #000; padding:5px; margin-bottom:5px;">
                    <div style="text-align:center; border-bottom:1.5px solid #000; padding-bottom:5px; margin-bottom:5px;">
                        <div style="font-size:22px; font-weight:900; color:#000;">DAR ALAMIRAT</div>
                        <div style="font-size:16px; font-weight:bold;">دار الاميرات</div>
                    </div>
                    <div style="text-align:center; font-size:16px; font-weight:bold; margin-bottom:5px;">نموذج طلب صرف مصاريف</div>
                    
                    <div style="display:flex; justify-content:space-between; margin-bottom:4px; font-size:12px;">
                        <span>التاريخ: ${hijriDate}</span>
                        <span>Date: ${gregorianDate}</span>
                    </div>
                </div>

                <!-- Employee Info Section -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px; background:#f2f2f2; padding:4px;">بيانات الموظف مقدم الطلب</div>
                    <table style="width:100%; border-collapse:collapse; font-size:12px;">
                        <tr>
                            <td style="padding:4px; width:15%; font-weight:bold; border:1px solid #000;">اسم الموظف</td>
                            <td style="padding:4px; width:35%; border:1px solid #000;">${employeeName}</td>
                            <td style="padding:4px; width:15%; font-weight:bold; border:1px solid #000;">المسمى الوظيفي</td>
                            <td style="padding:4px; width:35%; border:1px solid #000;">${employeeTitle}</td>
                        </tr>
                        <tr>
                            <td style="padding:4px; font-weight:bold; border:1px solid #000;">الإدارة / القسم</td>
                            <td style="padding:4px; border:1px solid #000;">${employeeDept}</td>
                            <td style="padding:4px; font-weight:bold; border:1px solid #000;">رقم الطلب</td>
                            <td style="padding:4px; border:1px solid #000;">#${exp.id.substring(0, 8)}</td>
                        </tr>
                    </table>
                </div>

                <!-- Expense Details Section -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px; background:#f2f2f2; padding:4px;">تفاصيل المصروف</div>
                    <table style="width:100%; border-collapse:collapse; font-size:12px;">
                        <tr>
                            <td style="padding:6px; width:15%; font-weight:bold; border:1px solid #000;">الموضوع</td>
                            <td colspan="3" style="padding:6px; border:1px solid #000;">${exp.subject || ''}</td>
                        </tr>
                        <tr>
                            <td style="padding:6px; font-weight:bold; border:1px solid #000;">البيان</td>
                            <td colspan="3" style="padding:6px; border:1px solid #000; min-height:40px;">${exp.statement || ''}</td>
                        </tr>
                        <tr>
                            <td style="padding:6px; font-weight:bold; border:1px solid #000;">المبلغ المطلوب</td>
                            <td style="padding:6px; border:1px solid #000; font-weight:bold; font-size:14px;">${amount} ريال</td>
                            <td style="padding:6px; font-weight:bold; border:1px solid #000;">أعلى مستوى اعتماد</td>
                            <td style="padding:6px; border:1px solid #000;">${levelLabel}</td>
                        </tr>
                    </table>
                </div>

                <!-- Requester Signature -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">الموظف مقدم الطلب :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${employeeName}</span></span>
                        <span>الوظيفة : <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${employeeTitle}</span></span>
                        <span>التوقيع .....................</span>
                        <span>التاريخ: ${hijriDate}</span>
                    </div>
                </div>

                <!-- Section: Manager Approval -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">اعتماد المدير المباشر :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم <span style="border-bottom:1px dotted #000; min-width:140px; display:inline-block;">${getApproverName(managerApproval)}</span></span>
                        <span>التوقيع .....................</span>
                        <span>التاريخ:&nbsp; ${getApprovalDate(managerApproval)}</span>
                    </div>
                    ${managerApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${managerApproval.comments}</div>` : ''}
                </div>

                <!-- Section: Finance Approval (if level is finance or GM) -->
                ${exp.highest_approval_level === 'finance' || exp.highest_approval_level === 'general_manager' ? `
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">الإدارة المالية :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${getApproverName(financeApproval)}</span></span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${getApprovalDate(financeApproval)}</span>
                    </div>
                    ${financeApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${financeApproval.comments}</div>` : ''}
                </div>
                ` : ''}

                <!-- Section: GM Approval (if level is GM) -->
                ${exp.highest_approval_level === 'general_manager' ? `
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">اعتماد المدير العام :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${getApproverName(gmApproval)}</span></span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${getApprovalDate(gmApproval)}</span>
                    </div>
                    ${gmApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${gmApproval.comments}</div>` : ''}
                </div>
                ` : ''}

                <!-- Section: Accountant / Payment -->
                <div style="border:1.5px solid #000; margin-top:8px; padding:6px;">
                    <div style="font-weight:bold; font-size:13px; border-bottom:1px solid #000; padding-bottom:2px; margin-bottom:5px;">محاسب العهدة (الصرف) :</div>
                    <div style="display:flex; justify-content:space-between; font-size:12px; flex-wrap:wrap; gap:3px;">
                        <span>الاسم : <span style="border-bottom:1px dotted #000; min-width:180px; display:inline-block;">${getApproverName(paidApproval)}</span></span>
                        <span>المبلغ المصروف : <span style="font-weight:bold; border-bottom:1px solid #000;">${amount}</span> ريال</span>
                        <span>التوقيع ...........................</span>
                        <span>التاريخ ${getApprovalDate(paidApproval)}</span>
                    </div>
                    ${paidApproval?.comments ? `<div style="font-size:11px; margin-top:4px; color:#333;">ملاحظات: ${paidApproval.comments}</div>` : ''}
                </div>

                <!-- Instructions -->
                <div style="margin-top:10px; font-size:10px; line-height:1.5;">
                    <strong>تعليمات يجب مراعاتها :</strong><br>
                    1. لن ُيقبل أي طلب صرف مصاريف غير مستوفي للبيانات المذكورة أعلاه.<br>
                    2. يجب تقديم المستندات المؤيدة للمبلغ المطلوب (فواتير، ايصالات، ..الخ).<br>
                    3. الصرف على حسب مستوى الاعتماد المحدد في الطلب.<br>
                    4. يتم صرف المبلغ من العهدة بعد اكتمال جميع الاعتمادات المطلوبة.
                </div>
            </div>
        `;

        globalThis.print();
    },
});
