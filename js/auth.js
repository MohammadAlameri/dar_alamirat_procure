// Authentication Logic
const auth = {
    async signIn(email, password) {
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });
        if (error) throw error;
        return data;
    },

    async signOut() {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;
        window.location.href = 'auth.html';
    },

    async getCurrentUser() {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return null;

        const profile = await db.getProfile(user.id);
        return { ...user, profile };
    }
};

// Check if already logged in
async function checkExistingSession() {
    if (document.getElementById('loginForm')) {
        const { data: { session } } = await supabase.auth.getSession();
        if (session) {
            globalThis.location.href = 'index.html';
        }
    }
}
checkExistingSession();

// Login page event listener
if (document.getElementById('loginForm')) {
    document.getElementById('loginForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const btn = document.getElementById('loginBtn');
        const alert = document.getElementById('authAlert');

        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Signing in...';
        alert.classList.add('d-none');

        try {
            await auth.signIn(email, password);
            window.location.href = 'index.html';
        } catch (error) {
            console.error(error);
            alert.querySelector('.alert').innerText = error.message;
            alert.classList.remove('d-none');
        } finally {
            btn.disabled = false;
            btn.innerText = 'Sign In';
        }
    });
}
