// Branch Database Operations
window.db = window.db || {};

window.db.getAllBranches = async function() {
    const { data, error } = await supabaseClient
        .from('branches')
        .select('*')
        .order('name', { ascending: true });
    
    if (error) throw error;
    return data;
};

window.db.createBranch = async function(branchData) {
    const { data, error } = await supabaseClient
        .from('branches')
        .insert([branchData])
        .select()
        .single();
    
    if (error) throw error;
    return data;
};

window.db.updateBranch = async function(id, branchData) {
    const { data, error } = await supabaseClient
        .from('branches')
        .update(branchData)
        .eq('id', id)
        .select()
        .single();
    
    if (error) throw error;
    return data;
};

window.db.deleteBranch = async function(id) {
    const { error } = await supabaseClient
        .from('branches')
        .delete()
        .eq('id', id);
    
    if (error) throw error;
    return true;
};

window.db.assignUserToBranch = async function(userId, branchId, accessLevel) {
    const { data, error } = await supabaseClient
        .from('user_branches')
        .insert([{ user_id: userId, branch_id: branchId, access_level: accessLevel }])
        .select()
        .single();
    
    if (error) throw error;
    return data;
};

window.db.removeUserFromBranch = async function(assignmentId) {
    const { error } = await supabaseClient
        .from('user_branches')
        .delete()
        .eq('id', assignmentId);
    
    if (error) throw error;
    return true;
};
