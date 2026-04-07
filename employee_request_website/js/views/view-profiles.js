// Profiles View
async function handleProfileDelete(id) {
    ui.setLoading(true);
    try {
        await db.deleteProfile(id);
        await loadDashboardData();
    } catch (error) {
        ui.showNotification(i18nManager.get('errorDeleteProfile') + error.message, 'error');
    } finally {
        ui.setLoading(false);
    }
}
