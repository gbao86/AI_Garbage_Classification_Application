import { getSupabaseConfig } from './config.js';

const { url, key } = getSupabaseConfig();

// Khởi tạo client
export const db = supabase.createClient(url, key, {
    auth: { persistSession: true }
});

export async function checkAdminPermissions() {
    // Gọi trực tiếp hàm RPC is_admin() đã định nghĩa trong SQL
    // Hàm này có SECURITY DEFINER nên sẽ chạy cực nhanh và bỏ qua RLS chặn profiles
    const { data: isAdmin, error } = await db.rpc('is_admin');

    if (error) {
        console.error('[admin-auth] Lỗi RPC is_admin:', error);
        throw new Error('Không thể xác thực quyền: ' + error.message);
    }

    if (!isAdmin) {
        await db.auth.signOut();
        throw new Error('Tài khoản của bạn không có quyền Admin!');
    }

    const { data: { user } } = await db.auth.getUser();
    return user;
}

export async function loginWithEmail(email, password) {
    const { data, error } = await db.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return await checkAdminPermissions();
}

export async function logout() {
    await db.auth.signOut();
    window.location.replace('index.html');
}

export const handleLogout = logout;
