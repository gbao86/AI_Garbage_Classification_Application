import { getSupabaseConfig } from './config.js';

const { url, key } = getSupabaseConfig();
// Khởi tạo client dùng chung cho toàn bộ web admin
export const db = supabase.createClient(url, key);

export async function loginWithEmail(email, password) {
    const { data, error } = await db.auth.signInWithPassword({ email, password });
    if (error) throw error;

    // Kiểm tra quyền Admin ngay lập tức
    const { data: profile, error: profileError } = await db.from('profiles').select('role').eq('id', data.user.id).single();
    if (profileError || !profile || (profile.role !== 'admin' && profile.role !== 'super_admin')) {
        await db.auth.signOut();
        throw new Error('Truy cập bị từ chối: Bạn không có quyền Admin!');
    }
    return data.user;
}

export async function loginWithGoogle() {
    const { error } = await db.auth.signInWithOAuth({
        provider: 'google',
        options: {
            redirectTo: window.location.origin + '/dashboard.html'
        }
    });
    if (error) throw error;
}

// Bảo vệ trang: Nếu chưa login hoặc không phải Admin thì đá về index.html
export async function protectPage() {
    const { data: { user } } = await db.auth.getUser();
    if (!user) {
        window.location.href = 'index.html';
        return;
    }
    const { data: profile } = await db.from('profiles').select('role').eq('id', user.id).single();
    if (!profile || (profile.role !== 'admin' && profile.role !== 'super_admin')) {
        await db.auth.signOut();
        window.location.href = 'index.html';
    }
    return user;
}

export async function logout() {
    await db.auth.signOut();
    window.location.href = 'index.html';
}

/** Dùng sau OAuth redirect / getSession — đảm bảo role admin */
export async function checkAdminPermissions(user) {
    if (!user?.id) {
        throw new Error('Chưa đăng nhập');
    }
    const { data: profile, error } = await db.from('profiles').select('role').eq('id', user.id).single();
    if (error || !profile || (profile.role !== 'admin' && profile.role !== 'super_admin')) {
        await db.auth.signOut();
        throw new Error('Truy cập bị từ chối: Bạn không có quyền Admin!');
    }
    return user;
}

export const handleLogout = logout;
