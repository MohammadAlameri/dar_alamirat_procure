const i18n = {
    en: {
        title: "Dar Alamirat Procurement",
        dashboard: "Dashboard",
        myRequests: "My Requests",
        pendingApprovals: "Pending Approvals",
        allRequests: "All Requests",
        reports: "Reports",
        userManagement: "User Management",
        signOut: "Sign Out",
        dashboardOverview: "Dashboard Overview",
        totalRequests: "TOTAL REQUESTS",
        pendingReview: "PENDING REVIEW",
        approved: "APPROVED",
        rejected: "REJECTED",
        recentRequests: "Recent Purchase Requests",
        newRequest: "New Request",
        requestId: "Request ID",
        subject: "Subject",
        requester: "Requester",
        status: "Status",
        date: "Date",
        action: "Action",
        activityLog: "Activity Log",
        noActivity: "No recent activity",
        nonSalesPurchase: "Non-Sales Supplies Purchase Request",
        backToDashboard: "Back to Dashboard",
        justification: "Justification (مبررات الاحتياج)",
        requestedItems: "Requested Items",
        description: "Description (Product & Model)",
        specs: "Specs",
        unit: "Unit",
        qty: "Qty",
        unitPrice: "Unit Price",
        total: "Total",
        addItem: "Add Item",
        grandTotal: "Grand Total:",
        submitRequest: "Submit Request",
        closing: "Close",
        requestDetails: "Request Details",
        totalPrice: "TOTAL PRICE",
        itemDescription: "Item Description",
        price: "Price",
        loginTitle: "Login - Dar Alamirat Procurement",
        emailAddress: "Email Address",
        password: "Password",
        forgot: "Forgot?",
        rememberMe: "Remember me",
        signIn: "Sign In",
        noAccount: "Don't have an account?",
        contactAdmin: "Contact Admin",
        procurementSystem: "Procurement Management System",
        // Statuses
        pending: "PENDING",
        it_approved: "IT APPROVED",
        finance_approved: "FINANCE APPROVED",
        rejected_status: "REJECTED",
        completed: "COMPLETED",
        // Roles
        admin: "Admin",
        employee: "Employee",
        it_procurement: "IT / Procurement",
        finance: "Finance"
    },
    ar: {
        title: "دار الأميرات للمشتريات",
        dashboard: "لوحة التحكم",
        myRequests: "طلباتي",
        pendingApprovals: "طلبات بانتظار الموافقة",
        allRequests: "كل الطلبات",
        reports: "التقارير",
        userManagement: "إدارة المستخدمين",
        signOut: "تسجيل الخروج",
        dashboardOverview: "نظرة عامة على لوحة التحكم",
        totalRequests: "إجمالي الطلبات",
        pendingReview: "قيد المراجعة",
        approved: "تمت الموافقة",
        rejected: "مرفوض",
        recentRequests: "طلبات الشراء الأخيرة",
        newRequest: "طلب جديد",
        requestId: "رقم الطلب",
        subject: "الموضوع",
        requester: "صاحب الطلب",
        status: "الحالة",
        date: "التاريخ",
        action: "إجراء",
        activityLog: "سجل النشاطات",
        noActivity: "لا يوجد نشاط أخير",
        nonSalesPurchase: "طلب شراء مستلزمات غير مخصصة للبيع",
        backToDashboard: "العودة للوحة التحكم",
        justification: "مبررات الاحتياج",
        requestedItems: "الأصناف المطلوبة",
        description: "الوصف (المنتج والموديل)",
        specs: "المواصفات",
        unit: "الوحدة",
        qty: "الكمية",
        unitPrice: "سعر الوحدة",
        total: "الإجمالي",
        addItem: "إضافة صنف",
        grandTotal: "الإجمالي الكلي:",
        submitRequest: "إرسال الطلب",
        closing: "إغلاق",
        requestDetails: "تفاصيل الطلب",
        totalPrice: "إجمالي السعر",
        itemDescription: "وصف الصنف",
        price: "السعر",
        loginTitle: "تسجيل الدخول - دار الأميرات للمشتريات",
        emailAddress: "البريد الإلكتروني",
        password: "كلمة المرور",
        forgot: "نسيت؟",
        rememberMe: "تذكرني",
        signIn: "تسجيل الدخول",
        noAccount: "ليس لديك حساب؟",
        contactAdmin: "اتصل بالمسؤول",
        procurementSystem: "نظام إدارة المشتريات",
        // Statuses
        pending: "قيد الانتظار",
        it_approved: "موافقة تقنية",
        finance_approved: "موافقة مالية",
        rejected_status: "مرفوض",
        completed: "مكتمل",
        // Roles
        admin: "مدير",
        employee: "موظف",
        it_procurement: "تقنية / مشتريات",
        finance: "مالية"
    }
};

const i18nManager = {
    currentLang: localStorage.getItem('lang') || 'en',

    init() {
        this.applyLanguage(this.currentLang);
    },

    setLanguage(lang) {
        this.currentLang = lang;
        localStorage.setItem('lang', lang);
        this.applyLanguage(lang);
        // Refresh the page or update UI components
        globalThis.location.reload(); 
    },

    applyLanguage(lang) {
        document.documentElement.lang = lang;
        document.documentElement.dir = (lang === 'ar') ? 'rtl' : 'ltr';
        
        // Translate elements with data-i18n attribute
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.dataset.i18n;
            if (i18n[lang][key]) {
                if (el.tagName === 'INPUT' && (el.type === 'text' || el.type === 'email' || el.type === 'password')) {
                    el.placeholder = i18n[lang][key];
                } else {
                    el.innerText = i18n[lang][key];
                }
            }
        });
    },

    get(key) {
        return i18n[this.currentLang][key] || key;
    }
};

// Initialize on load
// document.addEventListener('DOMContentLoaded', () => i18nManager.init());
