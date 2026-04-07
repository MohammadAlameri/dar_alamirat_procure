// Use the global supabase object from CDN to create the client
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Initialize global db object
window.db = window.db || {};
