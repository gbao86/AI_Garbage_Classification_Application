import { getSupabaseConfig } from './config.js';

const { url, key } = getSupabaseConfig();

// Đảm bảo thư viện Supabase đã sẵn sàng
if (typeof supabase === 'undefined') {
    console.error('[admin-auth] THIẾU THƯ VIỆN: supabase-js chưa được nạp từ CDN!');
}

export const db = supabase.createClient(url, key);

async function getUserRole(userId) {
    try {
        console.log('[admin-auth] Đang lấy role cho user:', userId);
        const { data, error } = await db.from('profiles').select('role').eq('id', userId).maybeSingle();
        if (error) {
            console.error('[admin-auth] Lỗi query profile:', error);
            return null;
        }
        return data ? data.role : null;
    } catch (e) {
        console.error('[admin-auth] Ngoại lệ khi lấy role:', e);
        return null;
    }
}

export async function loginWithEmail(email, password) {
    console.log('[admin-auth] Bắt đầu signInWithPassword cho:', email);
    try {
        const { data, error } = await db.auth.signInWithPassword({ email, password });

        if (error) {
            console.error('[admin-auth] Supabase trả về lỗi đăng nhập:', error.message);
            throw error;
        }

        console.log('[admin-auth] Đăng nhập thành công, đang kiểm tra quyền...');
        const role = await getUserRole(data.user.id);
        console.log('[admin-auth] Role tìm thấy:', role);

        if (role !== 'admin' && role !== 'super_admin') {
            console.warn('[admin-auth] User không phải admin, đang đăng xuất...');
            await db.auth.signOut();
            throw new Error('Tài khoản của bạn không có quyền Admin!');
        }

        return data.user;
    } catch (e) {
        console.error('[admin-auth] Lỗi thực thi loginWithEmail:', e.message);
        throw e;
    }
}

export async function loginWithMagicLink(email) {
    console.log('[admin-auth] Đang gửi Magic Link tới:', email);
    const { error } = await db.auth.signInWithOtp({
        email,
        options: {
            emailRedirectTo: window.location.origin + window.location.pathname,
            shouldCreateUser: false
        }
    });
    if (error) throw error;
}

export async function logout() {
    await db.auth.signOut();
    window.location.href = 'index.html';
}

export async function checkAdminPermissions(user) {
    if (!user) throw new Error('Chưa đăng nhập');
    const role = await getUserRole(user.id);
    if (role !== 'admin' && role !== 'super_admin') {
        await db.auth.signOut();
        throw new Error('Từ chối: Bạn không phải Admin!');
    }
    return user;
}

export const handleLogout = logout;
