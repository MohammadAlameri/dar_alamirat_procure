// Supabase Configuration
const SUPABASE_URL = 'https://gonldcbklguwjhekjhff.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvbmxkY2JrbGd1d2poZWtqaGZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0NTg3MjIsImV4cCI6MjA4ODAzNDcyMn0.UEKkRK4o-XDfA-8YwYf_syaGyiaepTjFNfruBvB1uFk';

// Use the global supabase object from CDN to create the client
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Database helper functions
const db = {
    async getProfile(userId) {
        const { data, error } = await supabaseClient
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .single();
        if (error) throw error;
        return data;
    },

    async getRequests(filters = {}) {
        let query = supabaseClient
            .from('purchase_requests')
            .select(`
                *,
                profiles:created_by (full_name, role),
                request_items (*)
            `)
            .order('created_at', { ascending: false });

        if (filters.userId) {
            query = query.eq('created_by', filters.userId);
        }
        if (filters.status) {
            query = query.eq('status', filters.status);
        }

        const { data, error } = await query;
        if (error) throw error;
        return data;
    },

    async createRequest(requestData, items) {
        // 1. Insert request
        const { data: request, error: reqError } = await supabaseClient
            .from('purchase_requests')
            .insert([requestData])
            .select()
            .single();

        if (reqError) throw reqError;

        // 2. Insert items
        const itemsWithReqId = items.map(item => ({
            ...item,
            request_id: request.id
        }));

        const { error: itemsError } = await supabaseClient
            .from('request_items')
            .insert(itemsWithReqId);

        if (itemsError) throw itemsError;

        return request;
    },

    async updateRequestStatus(id, status, updates = {}) {
        const { data, error } = await supabaseClient
            .from('purchase_requests')
            .update({ status, ...updates, updated_at: new Date() })
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return data;
    },

    async logApproval(requestId, userId, action, comments) {
        const { error } = await supabaseClient
            .from('approvals_log')
            .insert([{ request_id: requestId, user_id: userId, action, comments }]);
        
        if (error) throw error;
    },

    async createProfile(profileData) {
        const { data, error } = await supabaseClient
            .from('profiles')
            .insert([profileData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    async getAllProfiles() {
        // Since RLS is active, it will naturally exclude 'admin' profiles for non-admins if configured,
        // but we'll additionally filter in the app to be safe.
        const { data, error } = await supabaseClient
            .from('profiles')
            .select('*')
            .neq('role', 'admin') // Never show admins to other admins if requested
            .order('full_name', { ascending: true });
        
        if (error) throw error;
        return data;
    },

    async updateProfile(id, profileData) {
        const { data, error } = await supabaseClient
            .from('profiles')
            .update(profileData)
            .eq('id', id)
            .select()
            .single();
        if (error) throw error;
        return data;
    },

    async deleteProfile(id) {
        const { error } = await supabaseClient
            .from('profiles')
            .delete()
            .eq('id', id);
        if (error) throw error;
    }
};
