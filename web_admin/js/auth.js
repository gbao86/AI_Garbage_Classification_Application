import { createClient } from '@supabase/supabase-js';
import { getSupabaseConfig } from './config.js';

const { url, key } = getSupabaseConfig();

// Khởi tạo client duy nhất
export const db = createClient(url, key, {
    auth: { persistSession: true }
});

export async function checkAdminPermissions(sessionUser) {
    // If a user object is provided (dashboard init), use its id; otherwise rely on current auth session.
    const userId = sessionUser?.id;
    if (!userId) {
        // Fallback: get current session user
        const { data: { user }, error: userError } = await db.auth.getUser();
        if (userError || !user) throw new Error('Phiên đăng nhập đã hết hạn.');
        return await checkAdminPermissions(user);
    }

    // Query the profiles table for role
    const { data, error } = await db.from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    if (error) {
        console.error('[admin-auth] Lỗi truy vấn role:', error.message);
        throw new Error('Không thể xác thực quyền admin: ' + error.message);
    }
    if (!data || !(data.role === 'admin' || data.role === 'super_admin')) {
        console.warn('[admin-auth] Từ chối: User không phải admin.');
        await db.auth.signOut();
        throw new Error('Tài khoản của bạn không có quyền quản trị (Admin/Super Admin).');
    }
    // Return a minimal user object (email needed for UI)
    return { id: userId, email: sessionUser?.email, role: data.role };
}

export async function loginWithEmail(email, password) {
    console.log('[admin-auth] Bắt đầu đăng nhập:', email);
    const { data, error } = await db.auth.signInWithPassword({ email, password });

    if (error) {
        console.error('[admin-auth] Lỗi đăng nhập:', error.message);
        throw error;
    }

    // data.user chứa thông tin người dùng đã đăng nhập
    return await checkAdminPermissions(data.user);
}

export async function loginWithMagicLink(email) {
    console.log('[admin-auth] Gửi Magic Link tới:', email);
    const { error } = await db.auth.signInWithOtp({
        email,
        options: {
            emailRedirectTo: window.location.origin + window.location.pathname
        }
    });
    if (error) throw error;
}

export async function logout() {
    await db.auth.signOut();
    window.location.replace('index.html');
}

export const handleLogout = logout;
