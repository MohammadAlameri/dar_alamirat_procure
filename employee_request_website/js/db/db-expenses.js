window.db = window.db || {};

window.db.getExpenseRequests = async function(filters = {}) {
    let query = supabaseClient
        .from('expense_requests')
        .select(`
            *,
            profiles:employee_id (full_name, role, manager_id)
        `)
        .order('created_at', { ascending: false });

    if (filters.userId) {
        query = query.eq('employee_id', filters.userId);
    }
    if (filters.branchId) {
        query = query.eq('branch_id', filters.branchId);
    }
    if (filters.status) {
        query = query.eq('status', filters.status);
    }
    if (filters.dateFrom) {
        query = query.gte('created_at', filters.dateFrom);
    }
    if (filters.dateTo) {
        const nextDay = new Date(filters.dateTo);
        nextDay.setDate(nextDay.getDate() + 1);
        query = query.lt('created_at', nextDay.toISOString().split('T')[0]);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
};

window.db.createExpenseRequest = async function(expenseData) {
    const { data, error } = await supabaseClient
        .from('expense_requests')
        .insert([expenseData])
        .select()
        .single();
    if (error) throw error;
    return data;
};

window.db.updateExpenseStatus = async function(id, status, updates = {}) {
    const { data, error } = await supabaseClient
        .from('expense_requests')
        .update({ status, ...updates, updated_at: new Date() })
        .eq('id', id)
        .select();
    if (error) throw error;
    return data && data.length > 0 ? data[0] : null;
};

window.db.logExpenseApproval = async function(requestId, userId, action, comments) {
    const { error } = await supabaseClient
        .from('expense_approvals_log')
        .insert([{ request_id: requestId, user_id: userId, action, comments }]);
    if (error) throw error;
};

window.db.updateExpenseFull = async function(id, expenseData) {
    const { error: expError } = await supabaseClient
        .from('expense_requests')
        .update({...expenseData, updated_at: new Date()})
        .eq('id', id);
    if (expError) throw expError;

    const { error: logsError } = await supabaseClient
        .from('expense_approvals_log')
        .delete()
        .eq('request_id', id);
    if (logsError) throw logsError;
};
