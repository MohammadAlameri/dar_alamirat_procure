// Authentication Logic
const auth = {
    async signIn(email, password) {
        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email,
            password
        });
        if (error) throw error;
        return data;
    },

    async signOut() {
        const { error } = await supabaseClient.auth.signOut();
        if (error) throw error;
        globalThis.location.href = 'auth.html';
    },

    async getCurrentUser() {
        const { data: { user } } = await supabaseClient.auth.getUser();
        if (!user) return null;

        const profile = await db.getProfile(user.id);
        return { ...user, profile };
    }
};

// Check if already logged in (Only on login page)
async function checkExistingSession() {
    if (document.getElementById('loginForm')) {
        const { data: { session } } = await supabaseClient.auth.getSession();
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
        const alertEl = document.getElementById('authAlert');

        btn.disabled = true;
        btn.innerHTML = `<span class="spinner-border spinner-border-sm"></span> ${i18nManager.get('signingIn')}`;
        alertEl.classList.add('d-none');

        try {
            await auth.signIn(email, password);
            globalThis.location.href = 'index.html';
        } catch (error) {
            console.error(error);
            alertEl.querySelector('.alert').innerText = error.message;
            alertEl.classList.remove('d-none');
        } finally {
            btn.disabled = false;
            btn.innerText = i18nManager.get('signIn') || 'Sign In';
        }
    });
}

// Password toggle for login
document.getElementById('togglePassword')?.addEventListener('click', () => {
    const passwordInput = document.getElementById('password');
    const icon = document.querySelector('#togglePassword i');
    if (passwordInput.type === 'password') {
        passwordInput.type = 'text';
        icon.dataset.lucide = 'eye-off';
    } else {
        passwordInput.type = 'password';
        icon.dataset.lucide = 'eye';
    }
    lucide.createIcons();
});

// Contact Admin Alert
document.querySelector('[data-i18n="contactAdmin"]')?.addEventListener('click', (e) => {
    e.preventDefault();
    ui.showNotification(i18nManager.get('contactAdminMsg'), 'info');
});
