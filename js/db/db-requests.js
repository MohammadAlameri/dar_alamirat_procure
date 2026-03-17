window.db = window.db || {};

window.db.getRequests = async function(filters = {}) {
    let selectStr = `
        *,
        profiles:created_by (full_name, role, manager_id),
        request_items (*)
    `;

    if (filters.categoryId) {
        selectStr = `
            *,
            profiles:created_by (full_name, role, manager_id),
            request_items!inner (*)
        `;
    }

    let query = supabaseClient
        .from('purchase_requests')
        .select(selectStr)
        .order('created_at', { ascending: false });

    if (filters.userId) {
        query = query.eq('created_by', filters.userId);
    }
    if (filters.status) {
        query = query.eq('status', filters.status);
    }
    if (filters.branchId) {
        query = query.eq('branch_id', filters.branchId);
    }
    if (filters.categoryId) {
        query = query.eq('request_items.category_id', filters.categoryId);
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

window.db.createRequest = async function(requestData, items) {
    const { data: request, error: reqError } = await supabaseClient
        .from('purchase_requests')
        .insert([requestData])
        .select()
        .single();

    if (reqError) throw reqError;

    const itemsWithReqId = items.map(item => ({
        ...item,
        request_id: request.id
    }));

    const { error: itemsError } = await supabaseClient
        .from('request_items')
        .insert(itemsWithReqId);

    if (itemsError) throw itemsError;

    return request;
};

window.db.updateRequestFull = async function(requestId, requestData, items) {
    const { error: reqError } = await supabaseClient
        .from('purchase_requests')
        .update({...requestData, updated_at: new Date()})
        .eq('id', requestId);
    if (reqError) throw reqError;

    const { error: delError } = await supabaseClient
        .from('request_items')
        .delete()
        .eq('request_id', requestId);
    if (delError) throw delError;

    const itemsWithReqId = items.map(item => ({ ...item, request_id: requestId }));
    const { error: itemsError } = await supabaseClient
        .from('request_items')
        .insert(itemsWithReqId);
    if (itemsError) throw itemsError;

    const { error: logsError } = await supabaseClient
        .from('approvals_log')
        .delete()
        .eq('request_id', requestId);
    if (logsError) throw logsError;
};

window.db.updateRequestStatus = async function(id, status, updates = {}) {
    const { data, error } = await supabaseClient
        .from('purchase_requests')
        .update({ status, ...updates, updated_at: new Date() })
        .eq('id', id)
        .select();

    if (error) throw error;
    return data && data.length > 0 ? data[0] : null;
};

window.db.logApproval = async function(requestId, userId, action, comments) {
    const { error } = await supabaseClient
        .from('approvals_log')
        .insert([{ request_id: requestId, user_id: userId, action, comments }]);
    
    if (error) throw error;
};

window.db.getAllCategories = async function() {
    const { data, error } = await supabaseClient
        .from('categories')
        .select('*')
        .order('name', { ascending: true });
    
    if (error) throw error;
    return data;
};
