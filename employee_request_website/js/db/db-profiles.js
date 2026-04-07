window.db = window.db || {};

window.db.getProfile = async function(userId) {
    const { data, error } = await supabaseClient
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    if (error) throw error;
    return data;
};

window.db.createProfile = async function(profileData) {
    const { data, error } = await supabaseClient
        .from('profiles')
        .insert([profileData])
        .select()
        .single();
    if (error) throw error;
    return data;
};

window.db.getAllProfiles = async function() {
    const { data, error } = await supabaseClient
        .from('profiles')
        .select('*')
        .order('full_name', { ascending: true });
    if (error) throw error;
    return data;
};

window.db.updateProfile = async function(id, profileData) {
    const { data, error } = await supabaseClient
        .from('profiles')
        .update(profileData)
        .eq('id', id)
        .select()
        .single();
    if (error) throw error;
    return data;
};

window.db.deleteProfile = async function(id) {
    const { error } = await supabaseClient
        .from('profiles')
        .delete()
        .eq('id', id);
    if (error) throw error;
};
