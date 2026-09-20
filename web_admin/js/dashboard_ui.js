import { db, handleLogout, checkAdminPermissions } from './auth.js';
import * as api from './dashboard_api.js';

// Expose core variables/functions
window.db = db;
window.handleLogout = handleLogout;

// Mobile Sidebar Drawer Controller
window.toggleMobileSidebar = (forceState) => {
    const sidebar = document.getElementById('sidebar');
    const backdrop = document.getElementById('sidebar-backdrop');
    if (!sidebar) return;
    const isClosed = sidebar.classList.contains('-translate-x-full');
    const shouldOpen = typeof forceState === 'boolean' ? forceState : isClosed;
    if (shouldOpen) {
        sidebar.classList.remove('-translate-x-full');
        backdrop?.classList.remove('hidden');
    } else {
        sidebar.classList.add('-translate-x-full');
        backdrop?.classList.add('hidden');
    }
};

window.toggleTheme = () => {
    const isDark = document.documentElement.classList.contains('dark');
    if (isDark) {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('ecosort_theme', 'light');
    } else {
        document.documentElement.classList.add('dark');
        localStorage.setItem('ecosort_theme', 'dark');
    }
    updateThemeToggleUI();
};

function updateThemeToggleUI() {
    const isDark = document.documentElement.classList.contains('dark');
    const btn = document.getElementById('theme-toggle-btn');
    if (btn) {
        btn.innerHTML = isDark ? `
            <svg class="w-4 h-4 text-amber-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
            </svg>
            <span>Chế độ Sáng</span>
        ` : `
            <svg class="w-4 h-4 text-slate-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
            </svg>
            <span>Chế độ Tối</span>
        `;
    }

    const mobileBtns = document.querySelectorAll('.mobile-theme-btn');
    mobileBtns.forEach(mBtn => {
        mBtn.innerHTML = isDark ? `
            <svg class="w-5 h-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
            </svg>
        ` : `
            <svg class="w-5 h-5 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
            </svg>
        `;
    });
}

// Init theme UI on load
updateThemeToggleUI();

// UI View State
let allSubmissions = [];
let wasteGroups = [];
let userPage = 1;
const USER_LIMIT = 25;
let currentUserRole = 'admin'; // Will be set during init
let privilegedActions = [];
let paPage = 1;
const PA_LIMIT = 25;

const ACTION_TYPE_MAP = {
    'promote_user_admin': 'Nâng cấp User lên Admin',
    'demote_admin': 'Hạ cấp Admin xuống User',
    'toggle_kill_switch': 'Ngắt khẩn cấp (Kill Switch)',
    'delete_collection_point': 'Xóa điểm bỏ rác',
    'purge_user_data': 'Xóa dữ liệu người dùng',
    'other': 'Hành động khác'
};

const STATE_BADGE_MAP = {
    'draft': '<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-slate-100 text-slate-600 border border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700">Bản thảo</span>',
    'awaiting_second_approval': '<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30">Chờ duyệt lần 2</span>',
    'approved': '<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30">Đã duyệt (Chờ thực thi)</span>',
    'rejected': '<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-rose-50 text-rose-700 border border-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:border-rose-500/30">Đã từ chối</span>',
    'executed': '<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-teal-50 text-teal-700 border border-teal-200 dark:bg-teal-500/10 dark:text-teal-400 dark:border-teal-500/30">Đã thực thi</span>',
    'expired': '<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-slate-100 text-slate-500 border border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700">Đã hết hạn</span>'
};

// UI Helper functions
function slugify(str) {
    return String(str)
        .normalize('NFKD')
        .replace(/[\u0300-\u036f]/g, '')
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9 -]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-');
}

function escapeHTML(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function generateSecureRandomString(length = 4) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const array = new Uint8Array(length);
    (window.crypto || crypto).getRandomValues(array);
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars[array[i] % chars.length];
    }
    return result;
}

// -------------------------------------------------------------
// TAB 1: SUBMISSIONS MANAGEMENT
// -------------------------------------------------------------
window.fetchSubmissions = async () => {
    const grid = document.getElementById('grid-submissions');
    const loader = document.getElementById('loader-submissions');
    const status = document.getElementById('filter-status').value;

    loader.classList.remove('hidden');
    grid.innerHTML = '';

    try {
        allSubmissions = await api.apiFetchSubmissions(status);
        loader.classList.add('hidden');

        if (allSubmissions.length === 0) {
            grid.innerHTML = `<div class="col-span-full py-16 text-center text-slate-500 dark:text-slate-400 font-semibold text-sm">Không có báo cáo nào ở trạng thái ${escapeHTML(status)}</div>`;
            return;
        }

        allSubmissions.forEach(item => {
            const card = document.createElement('div');
            card.className = 'glass-panel glass-panel-hover rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col justify-between shadow-sm';
            card.innerHTML = `
                <div class="h-44 bg-slate-100 dark:bg-slate-950 relative group border-b border-slate-200 dark:border-slate-800">
                    ${item.scan_image_path ? `<img src="${escapeHTML(item.scan_image_path)}" class="w-full h-full object-cover">` : '<div class="w-full h-full flex items-center justify-center text-slate-400 dark:text-slate-600 text-xs font-semibold uppercase tracking-wider">Không có ảnh</div>'}
                </div>
                <div class="p-5 flex-1 flex flex-col justify-between">
                    <div>
                        <h3 class="font-bold text-slate-900 dark:text-white text-base truncate font-heading">${escapeHTML(item.suggested_name_vi || 'Yêu cầu mới')}</h3>
                        <p class="text-xs text-emerald-600 dark:text-emerald-400 font-semibold uppercase tracking-wider mt-1 mb-5">${escapeHTML(item.tflite_top_label || 'AI chưa phân loại')}</p>
                    </div>

                    <div class="flex gap-2 pt-2 border-t border-slate-100 dark:border-slate-800/60">
                        <button onclick="showDetail('${escapeHTML(item.id)}')" class="flex-1 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 py-2.5 rounded-xl text-xs font-bold transition">CHI TIẾT</button>
                        ${status === 'pending_review' ? `
                            <button onclick="updateStatus('${escapeHTML(item.id)}', 'rejected')" class="bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 px-3.5 rounded-xl font-bold text-xs transition">HỦY</button>
                        ` : ''}
                    </div>
                </div>
            `;
            grid.appendChild(card);
        });
    } catch (e) {
        loader.classList.add('hidden');
        grid.innerHTML = '';
        const errorDiv = document.createElement('div');
        errorDiv.className = 'col-span-full p-6 bg-rose-50 dark:bg-rose-950/20 border border-rose-200 dark:border-rose-900/40 text-rose-600 dark:text-rose-400 rounded-xl text-sm font-semibold';
        errorDiv.textContent = `Lỗi: ${e && e.message ? e.message : 'Không xác định'}`;
        grid.appendChild(errorDiv);
    }
};

window.showDetail = (id) => {
    const item = allSubmissions.find(s => s.id === id);
    if (!item) return;

    const content = document.getElementById('detail-content');
    content.innerHTML = `
        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="bg-slate-100 dark:bg-slate-950 rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 flex items-center justify-center min-h-[180px]">
                ${item.scan_image_path ? `<img src="${escapeHTML(item.scan_image_path)}" class="w-full h-full object-contain">` : '<p class="p-10 text-center text-slate-400 dark:text-slate-600 font-semibold text-xs uppercase tracking-wider">KHÔNG CÓ ẢNH</p>'}
            </div>
            <div class="space-y-3">
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Tên đề xuất</span>
                    <p class="text-lg font-bold text-slate-900 dark:text-white mt-1 font-heading">${escapeHTML(item.suggested_name_vi || 'N/A')}</p>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Nhãn AI (TFLite)</span>
                    <p class="font-bold text-emerald-600 dark:text-emerald-400 mt-1">${escapeHTML(item.tflite_top_label || 'N/A')} (${(item.tflite_confidence * 100).toFixed(1)}%)</p>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trạng thái</span>
                    <p class="font-bold text-emerald-600 dark:text-emerald-400 uppercase mt-1 text-sm">${escapeHTML(item.status)}</p>
                </div>
            </div>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Phân tích Gemini</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1.5 leading-relaxed">${escapeHTML(item.gemini_payload?.result_text || 'Chưa có phân tích')}</p>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Kiến thức bổ sung (Fun Fact)</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1.5">${escapeHTML(item.suggested_fun_fact || 'N/A')}</p>
        </div>
        ${item.status === 'pending_review' ? `
            <div class="pt-4 border-t border-slate-200 dark:border-slate-800 flex gap-3">
                <button onclick="approveWithData('${escapeHTML(item.id)}')" class="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">DUYỆT VÀO HỆ THỐNG</button>
                <button onclick="updateStatus('${escapeHTML(item.id)}', 'rejected')" class="flex-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 py-3 rounded-xl font-bold text-sm transition">TỪ CHỐI</button>
            </div>
        ` : ''}
    `;

    document.getElementById('detail-modal').classList.remove('hidden');
    document.getElementById('detail-modal').classList.add('flex');
};

window.closeDetailModal = () => {
    document.getElementById('detail-modal').classList.add('hidden');
    document.getElementById('detail-modal').classList.remove('flex');
};

window.fetchWasteGroups = async () => {
    try {
        wasteGroups = await api.apiFetchWasteGroups();
        const select = document.getElementById('approve-group');
        select.innerHTML = '<option value="">-- Chọn nhóm rác --</option>';
        wasteGroups.forEach(g => {
            select.innerHTML += `<option value="${g.id}">${g.name_vi}</option>`;
        });
    } catch (e) {
        console.error('Lỗi tải nhóm rác:', e);
    }
};

window.approveWithData = (id) => {
    const item = allSubmissions.find(s => s.id === id);
    if (!item) return;

    document.getElementById('approve-id').value = item.id;
    document.getElementById('approve-image-url').value = item.scan_image_path || '';
    document.getElementById('approve-name').value = item.suggested_name_vi || '';
    document.getElementById('approve-funfact').value = item.suggested_fun_fact || '';

    // Guess group based on AI label if possible, or leave empty
    document.getElementById('approve-group').value = '';

    document.getElementById('approve-modal').classList.remove('hidden');
    document.getElementById('approve-modal').classList.add('flex');
};

window.closeApproveModal = () => {
    document.getElementById('approve-modal').classList.add('hidden');
    document.getElementById('approve-modal').classList.remove('flex');
};

window.submitApproveData = async () => {
    const btn = document.getElementById('btn-submit-approve');
    const id = document.getElementById('approve-id').value;
    const imageUrl = document.getElementById('approve-image-url').value;
    const nameVi = document.getElementById('approve-name').value.trim();
    const groupId = document.getElementById('approve-group').value;
    const funFact = document.getElementById('approve-funfact').value.trim();

    if (!nameVi || !groupId) return alert('Vui lòng nhập tên và chọn nhóm rác!');

    let slug = slugify(nameVi);
    slug += '-' + generateSecureRandomString(4);

    btn.disabled = true;
    btn.innerText = 'ĐANG LƯU...';

    try {
        const { data: { session } } = await db.auth.getSession();
        const userId = session?.user?.id;

        await api.apiInsertWasteDictionary({
            slug,
            nameVi,
            funFact,
            imageUrl,
            groupId,
            userId
        });

        await api.apiUpdateSubmissionStatus(id, 'approved');

        alert('Đã duyệt và lưu vào từ điển thành công!');
        closeApproveModal();
        closeDetailModal();
        window.fetchSubmissions();
    } catch (e) {
        console.error(e);
        alert(e.message);
    } finally {
        btn.disabled = false;
        btn.innerText = 'XÁC NHẬN LƯU VÀO TỪ ĐIỂN';
    }
};

window.updateStatus = async (id, newStatus) => {
    try {
        await api.apiUpdateSubmissionStatus(id, newStatus);
        closeDetailModal();
        window.fetchSubmissions();
    } catch (e) {
        alert(e.message);
    }
};

window.switchTab = (tab) => {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));
    document.querySelectorAll('nav button').forEach(el => el.classList.remove('sidebar-active', 'hover:bg-slate-100', 'dark:hover:bg-slate-800'));
    
    const targetTab = document.getElementById('tab-' + tab);
    const targetBtn = document.getElementById('btn-' + tab);
    if (targetTab) targetTab.classList.remove('hidden');
    if (targetBtn) targetBtn.classList.add('sidebar-active');

    // Add back hover class to inactive buttons
    document.querySelectorAll('nav button').forEach(btn => {
        if (!btn.classList.contains('sidebar-active')) {
            btn.classList.add('hover:bg-slate-100', 'dark:hover:bg-slate-800');
        }
    });

    // Close mobile drawer when tab selected
    window.toggleMobileSidebar(false);

    if (tab === 'submissions') window.fetchSubmissions();
    if (tab === 'users') window.fetchUsers(1);
    if (tab === 'privileged_actions') window.fetchPrivilegedActions(1);
    if (tab === 'settings') window.fetchSystemSettings();
    if (tab === 'collection_points') window.fetchCollectionPoints(1);
};

// -------------------------------------------------------------
// TAB 2: USER MANAGEMENT
// -------------------------------------------------------------
function updateUserPagination(total) {
    const btnPrev = document.getElementById('btn-user-prev');
    const btnNext = document.getElementById('btn-user-next');
    const info = document.getElementById('user-page-info');

    const start = (userPage - 1) * USER_LIMIT + 1;
    const end = Math.min(userPage * USER_LIMIT, total);

    if (total === 0) {
        info.innerText = 'Không có dữ liệu';
        btnPrev.disabled = true;
        btnNext.disabled = true;
    } else {
        info.innerText = `Hiển thị ${start}-${end} trên ${total}`;
        btnPrev.disabled = userPage === 1;
        btnNext.disabled = end >= total;
    }
}

window.fetchUsers = async (page = 1) => {
    userPage = page;
    const tbody = document.getElementById('table-users');
    const loader = document.getElementById('loader-users');
    const search = document.getElementById('filter-user-search').value;
    const roleFilter = document.getElementById('filter-user-role').value;
    const statusFilter = document.getElementById('filter-user-status').value;

    tbody.innerHTML = '';
    loader.classList.remove('hidden');
    document.getElementById('user-page-info').innerText = 'Đang tải...';

    try {
        const data = await api.apiFetchUsers(userPage, USER_LIMIT, search);
        loader.classList.add('hidden');

        let filteredData = data || [];
        if (roleFilter) filteredData = filteredData.filter(u => u.role === roleFilter);
        if (statusFilter) {
            const isLocked = statusFilter === 'locked';
            filteredData = filteredData.filter(u => u.is_locked === isLocked);
        }

        if (filteredData.length === 0) {
            tbody.innerHTML = `<tr><td colspan="5" class="p-8 text-center text-slate-400 dark:text-slate-500 font-semibold text-sm">Không tìm thấy người dùng nào</td></tr>`;
            updateUserPagination(0);
            return;
        }

        const totalCount = data.length > 0 && data[0].total_count ? parseInt(data[0].total_count) : filteredData.length;

        filteredData.forEach(u => {
            const tr = document.createElement('tr');
            tr.className = 'hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition border-b border-slate-200 dark:border-slate-800/60 last:border-none';

            const roleColor = u.role === 'super_admin' ? 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-500/10 dark:border-purple-500/30 dark:text-purple-400' :
                u.role === 'admin' ? 'bg-sky-50 text-sky-700 border-sky-200 dark:bg-cyan-500/10 dark:border-cyan-500/30 dark:text-cyan-400' : 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:border-slate-700 dark:text-slate-400';

            const statusHtml = u.is_locked
                ? '<span class="px-2.5 py-0.5 rounded-full bg-rose-50 dark:bg-rose-500/10 border border-rose-200 dark:border-rose-500/30 text-rose-700 dark:text-rose-400 font-bold text-[11px] uppercase tracking-wider flex items-center justify-center gap-1.5 w-max mx-auto"><div class="w-1.5 h-1.5 rounded-full bg-rose-500"></div> Bị khóa</span>'
                : '<span class="px-2.5 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/30 text-emerald-700 dark:text-emerald-400 font-bold text-[11px] uppercase tracking-wider flex items-center justify-center gap-1.5 w-max mx-auto"><div class="w-1.5 h-1.5 rounded-full bg-emerald-500"></div> Hoạt động</span>';

            const isProtected = u.role === 'super_admin' && currentUserRole !== 'super_admin';

            tr.innerHTML = `
                <td class="p-3.5 sm:p-4">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/60 flex items-center justify-center font-bold text-emerald-600 dark:text-emerald-400 font-heading text-xs shrink-0">
                            ${(u.display_name || u.email || '?').charAt(0).toUpperCase()}
                        </div>
                        <div class="min-w-0">
                            <p class="font-semibold text-slate-900 dark:text-white text-sm truncate font-heading">${escapeHTML(u.display_name || 'Chưa cập nhật')}</p>
                            <p class="text-xs text-slate-500 dark:text-slate-400 font-normal truncate">${escapeHTML(u.email || 'Ẩn email')}</p>
                        </div>
                    </div>
                </td>
                <td class="p-3.5 sm:p-4 text-center">
                    <span class="px-2.5 py-1 rounded-lg ${roleColor} border font-bold text-[11px] uppercase tracking-wider">${u.role}</span>
                </td>
                <td class="p-3.5 sm:p-4 text-center">${statusHtml}</td>
                <td class="p-3.5 sm:p-4 text-xs text-slate-500 dark:text-slate-400 font-medium">${u.last_sign_in_at ? new Date(u.last_sign_in_at).toLocaleString() : 'Chưa có data'}</td>
                <td class="p-3.5 sm:p-4 text-right">
                    <button onclick="openUserActionModal('${u.id}', '${u.email}', '${u.role}', ${u.is_locked})" 
                        class="px-3 py-1.5 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-300 dark:border-slate-700 rounded-lg text-xs font-semibold shadow-sm transition ${isProtected ? 'opacity-40 cursor-not-allowed' : ''}"
                        ${isProtected ? 'disabled title="Không có quyền thao tác lên Super Admin"' : ''}>
                        QUẢN LÝ
                    </button>
                </td>
            `;
            tbody.appendChild(tr);
        });

        updateUserPagination(totalCount);
    } catch (e) {
        loader.classList.add('hidden');
        tbody.innerHTML = `<tr><td colspan="5" class="p-8 text-center text-rose-500 font-semibold text-sm">Lỗi: ${escapeHTML(e.message)}</td></tr>`;
    }
};

window.changeUserPage = (delta) => {
    window.fetchUsers(userPage + delta);
};

window.openUserActionModal = (id, email, role, isLocked) => {
    if (role === 'super_admin' && currentUserRole !== 'super_admin') {
        return alert('Từ chối truy cập: Bạn không có quyền thao tác lên tài khoản Super Admin.');
    }

    document.getElementById('action-user-id').value = id;
    document.getElementById('action-user-locked').value = isLocked;
    document.getElementById('user-action-email').innerText = email !== 'undefined' && email ? email : 'ID: ' + id;
    
    document.getElementById('user-action-modal').dataset.targetRole = role;

    const btnBan = document.getElementById('btn-toggle-ban');
    const inputReason = document.getElementById('ban-reason');

    if (isLocked) {
        btnBan.innerText = 'MỞ KHÓA TÀI KHOẢN (UNBAN)';
        btnBan.className = 'w-full bg-emerald-600 text-white py-2.5 rounded-lg font-bold text-xs shadow-sm hover:bg-emerald-500 transition';
        inputReason.classList.add('hidden');
    } else {
        btnBan.innerText = 'KHÓA TÀI KHOẢN (BAN)';
        btnBan.className = 'w-full bg-rose-600 text-white py-2.5 rounded-lg font-bold text-xs shadow-sm hover:bg-rose-500 transition';
        inputReason.classList.remove('hidden');
        inputReason.value = '';
    }

    const btnPromote = document.getElementById('btn-request-promote');
    const btnDemote = document.getElementById('btn-request-demote');
    const roleSection = document.getElementById('user-role-actions-section');

    db.auth.getUser().then(({ data: { user } }) => {
        const isSelf = user && user.id === id;
        if (isSelf) {
            roleSection.classList.add('hidden');
        } else {
            roleSection.classList.remove('hidden');
            if (role === 'user') {
                btnPromote.classList.remove('hidden');
                btnDemote.classList.add('hidden');
            } else if (role === 'admin') {
                btnPromote.classList.add('hidden');
                btnDemote.classList.remove('hidden');
            } else {
                roleSection.classList.add('hidden');
            }
        }
    }).catch(e => {
        console.error(e);
    });

    document.getElementById('user-action-modal').classList.remove('hidden');
};

window.closeUserActionModal = () => {
    document.getElementById('user-action-modal').classList.add('hidden');
};

window.toggleBanUser = async () => {
    const id = document.getElementById('action-user-id').value;
    const isLockedStr = document.getElementById('action-user-locked').value;
    const isCurrentlyLocked = isLockedStr === 'true';
    const reason = document.getElementById('ban-reason').value.trim();

    if (!isCurrentlyLocked && !reason) {
        return alert('Vui lòng nhập lý do khóa tài khoản!');
    }

    if (!confirm(`Bạn chắc chắn muốn ${isCurrentlyLocked ? 'mở khóa' : 'khóa'} tài khoản này?`)) return;

    try {
        await api.apiBanUser(id, reason, !isCurrentlyLocked);
        alert(`Đã ${isCurrentlyLocked ? 'mở khóa' : 'khóa'} thành công!`);
        closeUserActionModal();
        window.fetchUsers(userPage);
    } catch (e) {
        console.error(e);
        alert('Lỗi: ' + e.message);
    }
};

window.resetUserPassword = async () => {
    const email = document.getElementById('user-action-email').innerText;
    if (email.startsWith('ID:')) return alert('Không có email của user này để gửi link reset.');

    if (!confirm(`Gửi email đặt lại mật khẩu tới: ${email}?`)) return;

    try {
        await api.apiResetUserPassword(email);
        alert('Đã gửi link đặt lại mật khẩu thành công! Yêu cầu user kiểm tra hòm thư.');
    } catch (e) {
        console.error(e);
        alert('Lỗi: ' + e.message);
    }
};

window.viewUserAuditLogs = () => {
    alert('Tính năng xem Audit Logs đang được xây dựng (Sẽ nạp từ bảng public.audit_logs)');
};

window.requestRolePromotion = async () => {
    const targetUserId = document.getElementById('action-user-id').value;
    const targetEmail = document.getElementById('user-action-email').innerText;
    const reason = prompt('Nhập lý do đề xuất nâng quyền Admin (Bắt buộc):');
    if (!reason) return;

    try {
        const { data: { session } } = await db.auth.getSession();
        const currentUserId = session?.user?.id;

        await api.apiInsertPrivilegedAction({
            actionType: 'promote_user_admin',
            payload: { user_id: targetUserId, email: targetEmail },
            requesterId: currentUserId,
            reason: reason
        });

        alert('Đã gửi đề xuất nâng cấp quyền Admin! Yêu cầu cần một Admin/Super Admin khác phê duyệt để có hiệu lực.');
        closeUserActionModal();
    } catch (e) {
        alert('Lỗi: ' + e.message);
    }
};

window.requestRoleDemotion = async () => {
    const targetUserId = document.getElementById('action-user-id').value;
    const targetEmail = document.getElementById('user-action-email').innerText;
    const reason = prompt('Nhập lý do đề xuất hạ quyền Admin xuống User (Bắt buộc):');
    if (!reason) return;

    try {
        const { data: { session } } = await db.auth.getSession();
        const currentUserId = session?.user?.id;

        await api.apiInsertPrivilegedAction({
            actionType: 'demote_admin',
            payload: { user_id: targetUserId, email: targetEmail },
            requesterId: currentUserId,
            reason: reason
        });

        alert('Đã gửi đề xuất hạ quyền Admin! Yêu cầu cần một Admin/Super Admin khác phê duyệt để có hiệu lực.');
        closeUserActionModal();
    } catch (e) {
        alert('Lỗi: ' + e.message);
    }
};

// -------------------------------------------------------------
// TAB 3: PRIVILEGED ACTIONS & SYSTEM CONFIG
// -------------------------------------------------------------
function updatePAPagination(total) {
    const btnPrev = document.getElementById('btn-pa-prev');
    const btnNext = document.getElementById('btn-pa-next');
    const info = document.getElementById('pa-page-info');

    const start = (paPage - 1) * PA_LIMIT + 1;
    const end = Math.min(paPage * PA_LIMIT, total);

    if (total === 0) {
        info.innerText = 'Không có dữ liệu';
        btnPrev.disabled = true;
        btnNext.disabled = true;
    } else {
        info.innerText = `Hiển thị ${start}-${end} trên ${total}`;
        btnPrev.disabled = paPage === 1;
        btnNext.disabled = end >= total;
    }
}

window.fetchPrivilegedActions = async (page = 1) => {
    paPage = page;
    const tbody = document.getElementById('table-privileged-actions');
    const loader = document.getElementById('loader-privileged-actions');
    const stateFilter = document.getElementById('filter-pa-state').value;

    tbody.innerHTML = '';
    loader.classList.remove('hidden');
    document.getElementById('pa-page-info').innerText = 'Đang tải...';

    try {
        const profiles = await api.apiFetchAllProfiles();
        const profilesMap = {};
        profiles.forEach(p => profilesMap[p.id] = p.display_name || p.id);

        const fromIndex = (paPage - 1) * PA_LIMIT;
        const toIndex = fromIndex + PA_LIMIT - 1;

        const { data, count } = await api.apiFetchPrivilegedActions(stateFilter, fromIndex, toIndex);
        loader.classList.add('hidden');
        privilegedActions = data || [];

        if (privilegedActions.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="p-8 text-center text-slate-400 dark:text-slate-500 font-semibold text-sm">Không có yêu cầu đặc quyền nào</td></tr>';
            updatePAPagination(0);
            return;
        }

        privilegedActions.forEach(item => {
            const tr = document.createElement('tr');
            tr.className = 'hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition border-b border-slate-200 dark:border-slate-800/60 last:border-none';

            const actionName = ACTION_TYPE_MAP[item.action_type] || item.action_type;
            const stateHtml = STATE_BADGE_MAP[item.state] || item.state;
            const requesterName = profilesMap[item.requester_id] || 'N/A';

            tr.innerHTML = `
                <td class="p-3.5 sm:p-4">
                    <p class="font-bold text-slate-900 dark:text-white text-sm font-heading">${actionName}</p>
                    <p class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mt-0.5">ID: ${item.id}</p>
                </td>
                <td class="p-3.5 sm:p-4 text-center text-sm font-medium text-slate-700 dark:text-slate-300">${requesterName}</td>
                <td class="p-3.5 sm:p-4 text-center">${stateHtml}</td>
                <td class="p-3.5 sm:p-4 text-xs text-slate-500 dark:text-slate-400 font-medium">${new Date(item.created_at).toLocaleString()}</td>
                <td class="p-3.5 sm:p-4 text-right">
                    <button onclick="showPADetail('${item.id}')"
                        class="px-3 py-1.5 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-300 dark:border-slate-700 rounded-lg text-xs font-semibold shadow-sm transition">
                        CHI TIẾT
                    </button>
                </td>
            `;
            tbody.appendChild(tr);
        });

        updatePAPagination(count || 0);
    } catch (e) {
        loader.classList.add('hidden');
        tbody.innerHTML = `<tr><td colspan="5" class="p-8 text-center text-rose-500 font-semibold text-sm">Lỗi: ${escapeHTML(e.message)}</td></tr>`;
    }
};

window.changePAPage = (delta) => {
    window.fetchPrivilegedActions(paPage + delta);
};

window.showPADetail = async (id) => {
    const item = privilegedActions.find(a => a.id === id);
    if (!item) return;

    const modal = document.getElementById('pa-detail-modal');
    const content = document.getElementById('pa-detail-content');
    content.innerHTML = '<p class="text-slate-500 dark:text-slate-400 font-medium text-center text-sm">Đang tải chi tiết phê duyệt...</p>';
    modal.classList.remove('hidden');

    try {
        const approvals = await api.apiFetchApprovals(id);
        const profiles = await api.apiFetchAllProfiles();
        const profilesMap = {};
        profiles.forEach(p => profilesMap[p.id] = p.display_name || p.id);

        const { data: { session } } = await db.auth.getSession();
        const currentUserId = session?.user?.id;

        const actionName = ACTION_TYPE_MAP[item.action_type] || item.action_type;
        const stateHtml = STATE_BADGE_MAP[item.state] || item.state;
        const requesterName = profilesMap[item.requester_id] || item.requester_id;

        const hasApproved = approvals && approvals.some(a => a.approver_id === currentUserId);
        const isRequester = item.requester_id === currentUserId;

        let approvalsHtml = '';
        if (approvals && approvals.length > 0) {
            approvalsHtml = approvals.map(a => `
                <div class="flex justify-between items-center bg-slate-50 dark:bg-slate-900/60 p-3 rounded-xl border border-slate-200 dark:border-slate-800">
                    <div>
                        <p class="font-bold text-slate-900 dark:text-white text-sm font-heading">${profilesMap[a.approver_id] || a.approver_id}</p>
                        <p class="text-xs text-slate-600 dark:text-slate-300 mt-0.5">${a.comment || 'Không có bình luận'}</p>
                    </div>
                    <span class="text-[10px] text-slate-400 font-semibold">${new Date(a.created_at).toLocaleString()}</span>
                </div>
            `).join('');
        } else {
            approvalsHtml = '<p class="text-xs text-slate-400 italic">Chưa có lượt phê duyệt nào.</p>';
        }

        const payloadStr = JSON.stringify(item.payload, null, 2);

        content.innerHTML = `
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div class="space-y-3">
                    <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                        <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Loại hành động</span>
                        <p class="text-base font-bold text-slate-900 dark:text-white mt-1 font-heading">${actionName}</p>
                    </div>
                    <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                        <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Người yêu cầu</span>
                        <p class="font-bold text-emerald-600 dark:text-emerald-400 mt-1">${requesterName}</p>
                    </div>
                    <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                        <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trạng thái</span>
                        <div class="mt-1.5">${stateHtml}</div>
                    </div>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-2">Dữ liệu Payload (JSON)</span>
                    <pre class="bg-white dark:bg-slate-950 text-slate-800 dark:text-emerald-400 p-3 rounded-lg text-xs font-mono overflow-auto flex-1 max-h-[160px] border border-slate-200 dark:border-slate-800">${payloadStr}</pre>
                </div>
            </div>

            <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Lý do tạo yêu cầu</span>
                <p class="text-slate-700 dark:text-slate-300 text-sm mt-1 leading-relaxed">${item.execution_note || 'N/A'}</p>
            </div>

            <div class="space-y-2.5">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Danh sách phê duyệt (${approvals ? approvals.length : 0}/2)</span>
                <div class="space-y-2 max-h-[160px] overflow-y-auto">
                    ${approvalsHtml}
                </div>
            </div>

            <div class="pt-4 border-t border-slate-200 dark:border-slate-800 flex flex-wrap gap-3">
                ${(item.state === 'draft' || item.state === 'awaiting_second_approval') ? `
                    ${isRequester ? `
                        <div class="w-full p-3 bg-amber-50 dark:bg-amber-500/10 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-500/20 rounded-xl text-xs font-semibold text-center">
                            ⚠️ Bạn là người tạo yêu cầu này. Cần Admin khác phê duyệt để đảm bảo quy trình khách quan.
                        </div>
                    ` : `
                        ${hasApproved ? `
                            <div class="w-full p-3 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/20 rounded-xl text-xs font-semibold text-center">
                                ✓ Bạn đã phê duyệt yêu cầu này rồi.
                            </div>
                        ` : `
                            <button onclick="approvePARequest('${item.id}')" class="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">PHÊ DUYỆT</button>
                            <button onclick="rejectPARequest('${item.id}')" class="flex-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 py-3 rounded-xl font-bold text-sm transition">TỪ CHỐI</button>
                        `}
                    `}
                ` : ''}

                ${item.state === 'approved' ? `
                    <button onclick="executePARequest('${item.id}')" class="w-full bg-sky-600 hover:bg-sky-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">THỰC THI HÀNH ĐỘNG</button>
                ` : ''}

                ${item.state === 'executed' ? `
                    <div class="w-full p-3.5 bg-sky-50 dark:bg-sky-950/30 text-sky-800 dark:text-sky-300 border border-sky-200 dark:border-sky-800/40 rounded-xl text-xs">
                        <p class="font-bold">✓ Đã thực thi thành công</p>
                        <p class="mt-1 font-semibold text-sky-700 dark:text-sky-400">Ghi chú: ${item.execution_note || 'N/A'}</p>
                        <p class="text-[10px] text-slate-500 dark:text-slate-400 mt-1">Lúc: ${new Date(item.executed_at).toLocaleString()}</p>
                    </div>
                ` : ''}
            </div>
        `;
    } catch (e) {
        content.innerHTML = `<div class="p-8 text-rose-500 font-semibold text-sm text-center">Lỗi tải chi tiết: ${escapeHTML(e.message)}</div>`;
    }
};

window.closePADetailModal = () => {
    document.getElementById('pa-detail-modal').classList.add('hidden');
};

window.approvePARequest = async (id) => {
    const comment = prompt('Nhập ý kiến phê duyệt (Không bắt buộc):');
    if (comment === null) return;

    try {
        const data = await api.apiApprovePrivilegedAction(id, comment);
        alert('Đã phê duyệt thành công! Trạng thái hiện tại: ' + (ACTION_TYPE_MAP[data] || data));
        closePADetailModal();
        window.fetchPrivilegedActions(paPage);
    } catch (e) {
        alert('Lỗi phê duyệt: ' + e.message);
    }
};

window.rejectPARequest = async (id) => {
    const reason = prompt('Nhập lý do từ chối (Bắt buộc):');
    if (!reason) return;

    try {
        const { data: { session } } = await db.auth.getSession();
        const currentEmail = session?.user?.email || 'Admin';

        const rejectionNote = `Bị từ chối bởi ${currentEmail}. Lý do: ${reason}`;
        await api.apiRejectPrivilegedAction(id, rejectionNote);

        alert('Đã từ chối yêu cầu này!');
        closePADetailModal();
        window.fetchPrivilegedActions(paPage);
    } catch (e) {
        alert('Lỗi: ' + e.message);
    }
};

window.executePARequest = async (id) => {
    const item = privilegedActions.find(a => a.id === id);
    if (!item) return;

    if (!confirm('Bạn chắc chắn muốn thực thi hành động này trực tiếp lên hệ thống?')) return;

    try {
        const { data: { session } } = await db.auth.getSession();
        const executorEmail = session?.user?.email || 'Admin';

        await api.apiExecuteAction(item.action_type, item.payload);

        const executionNote = `Thực thi thành công bởi ${executorEmail}`;
        await api.apiMarkActionExecuted(id, executionNote);

        alert('Thực thi hành động thành công!');
        closePADetailModal();
        window.fetchPrivilegedActions(paPage);
    } catch (e) {
        alert('Lỗi thực thi: ' + e.message);
    }
};

window.openCreatePAModal = async () => {
    document.getElementById('create-pa-form').reset();
    document.getElementById('create-pa-payload-inputs').innerHTML = '';
    document.getElementById('create-pa-modal').classList.remove('hidden');
};

window.closeCreatePAModal = () => {
    document.getElementById('create-pa-modal').classList.add('hidden');
};

window.handlePATypeChange = async () => {
    const type = document.getElementById('create-pa-type').value;
    const container = document.getElementById('create-pa-payload-inputs');
    container.innerHTML = '<p class="text-xs text-slate-400 font-medium">Đang tải dữ liệu cấu hình...</p>';

    try {
        if (type === 'promote_user_admin' || type === 'demote_admin') {
            const users = await api.apiFetchUsers(1, 1000, null);
            const targetRole = type === 'promote_user_admin' ? 'user' : 'admin';
            const targets = users.filter(u => u.role === targetRole);

            if (!targets || targets.length === 0) {
                container.innerHTML = `<p class="text-xs text-rose-500 font-medium">Không tìm thấy ${targetRole} nào để thao tác.</p>`;
                return;
            }

            let options = targets.map(u => `<option value="${u.id}">${u.display_name || u.email || u.id}</option>`).join('');
            container.innerHTML = `
                <div>
                    <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">Chọn Người dùng</label>
                    <select id="pa-input-user" required class="w-full p-2.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none text-slate-900 dark:text-slate-100 text-sm">
                        ${options}
                    </select>
                </div>
            `;
        } else if (type === 'toggle_kill_switch') {
            container.innerHTML = `
                <div>
                    <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">Trạng thái Kill Switch (Ngắt khẩn cấp)</label>
                    <select id="pa-input-killswitch" required class="w-full p-2.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none text-slate-900 dark:text-slate-100 text-sm">
                        <option value="true">BẬT (Chặn hoàn toàn API ghi của Người dùng)</option>
                        <option value="false">TẮT (Hoạt động bình thường)</option>
                    </select>
                </div>
            `;
        } else if (type === 'delete_collection_point') {
            const { data: points } = await db.from('collection_points').select('id, name');
            if (!points || points.length === 0) {
                container.innerHTML = '<p class="text-xs text-rose-500 font-medium">Không tìm thấy điểm bỏ rác nào.</p>';
                return;
            }
            let options = points.map(p => `<option value="${p.id}">${p.name}</option>`).join('');
            container.innerHTML = `
                <div>
                    <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">Chọn Điểm bỏ rác muốn xóa</label>
                    <select id="pa-input-point" required class="w-full p-2.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none text-slate-900 dark:text-slate-100 text-sm">
                        ${options}
                    </select>
                </div>
            `;
        } else {
            container.innerHTML = '';
        }
    } catch (e) {
        container.innerHTML = `<p class="text-xs text-rose-500 font-medium">Lỗi tải dữ liệu: ${escapeHTML(e.message)}</p>`;
    }
};

window.submitCreatePARequest = async () => {
    const type = document.getElementById('create-pa-type').value;
    const reason = document.getElementById('create-pa-reason').value.trim();
    const btn = document.getElementById('btn-submit-pa-request');

    if (!type || !reason) return alert('Vui lòng điền đầy đủ thông tin!');

    let payload = {};
    if (type === 'promote_user_admin' || type === 'demote_admin') {
        const select = document.getElementById('pa-input-user');
        const opt = select.options[select.selectedIndex];
        payload = { user_id: select.value, name: opt.text };
    } else if (type === 'toggle_kill_switch') {
        const val = document.getElementById('pa-input-killswitch').value === 'true';
        payload = { kill_switch: val };
    } else if (type === 'delete_collection_point') {
        const select = document.getElementById('pa-input-point');
        const opt = select.options[select.selectedIndex];
        payload = { point_id: select.value, name: opt.text };
    }

    btn.disabled = true;
    btn.innerText = 'ĐANG GỬI...';

    try {
        const { data: { session } } = await db.auth.getSession();
        const currentUserId = session?.user?.id;

        await api.apiInsertPrivilegedAction({
            actionType: type,
            payload: payload,
            requesterId: currentUserId,
            reason: reason
        });

        alert('Đã gửi yêu cầu phê duyệt thành công!');
        closeCreatePAModal();
        window.fetchPrivilegedActions(1);
    } catch (e) {
        alert('Lỗi gửi yêu cầu: ' + e.message);
    } finally {
        btn.disabled = false;
        btn.innerText = 'GỬI YÊU CẦU DUYỆT';
    }
};

// -------------------------------------------------------------
// TAB 4: SYSTEM CONFIG (SYSTEM SETTINGS)
// -------------------------------------------------------------
window.fetchSystemSettings = async () => {
    const container = document.getElementById('settings-form-container');
    const loader = document.getElementById('loader-settings');
    const statusBadge = document.getElementById('settings-status-badge');

    container.classList.add('hidden');
    loader.classList.remove('hidden');

    try {
        const data = await api.apiFetchSystemSettings();

        loader.classList.add('hidden');
        container.classList.remove('hidden');

        const maintenance = data.find(s => s.key === 'maintenance')?.value || { enabled: false, kill_switch: false, message: "" };
        const points = data.find(s => s.key === 'points')?.value || { scan_base: 10, game_correct: 5, streak_bonus_per: 1 };
        const gemini = data.find(s => s.key === 'gemini')?.value || { model: "gemini-3.8-flash" };

        document.getElementById('setting-maint-enabled').checked = !!maintenance.enabled;
        document.getElementById('setting-maint-killswitch').checked = !!maintenance.kill_switch;
        document.getElementById('setting-maint-message').value = maintenance.message || '';

        document.getElementById('setting-points-base').value = points.scan_base || 10;
        document.getElementById('setting-points-correct').value = points.game_correct || 5;
        document.getElementById('setting-points-streak').value = points.streak_bonus_per || 1;

        document.getElementById('setting-gemini-model').value = gemini.model || 'gemini-3.8-flash';

        const inputs = [
            'setting-maint-enabled', 'setting-maint-killswitch', 'setting-maint-message',
            'setting-points-base', 'setting-points-correct', 'setting-points-streak',
            'setting-gemini-model'
        ];

        if (currentUserRole !== 'super_admin') {
            inputs.forEach(id => document.getElementById(id).disabled = true);
            document.getElementById('settings-save-container').classList.add('hidden');
            statusBadge.innerHTML = '<span class="px-3.5 py-1.5 rounded-lg bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:border-amber-500/30 dark:text-amber-400 font-bold text-xs uppercase tracking-wider">Chế độ Chỉ Xem (Chỉ Super Admin được sửa)</span>';
        } else {
            inputs.forEach(id => document.getElementById(id).disabled = false);
            document.getElementById('settings-save-container').classList.remove('hidden');
            statusBadge.innerHTML = '<span class="px-3.5 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:border-emerald-500/30 dark:text-emerald-400 font-bold text-xs uppercase tracking-wider">Quyền chỉnh sửa Super Admin</span>';
        }
    } catch (e) {
        loader.classList.add('hidden');
        alert('Lỗi tải cấu hình: ' + e.message);
    }
};

window.saveSystemSettings = async () => {
    const btn = document.getElementById('btn-save-settings');
    btn.disabled = true;
    btn.innerText = 'ĐANG LƯU...';

    try {
        const { data: { session } } = await db.auth.getSession();
        const userId = session?.user?.id;

        const maintenanceVal = {
            enabled: document.getElementById('setting-maint-enabled').checked,
            kill_switch: document.getElementById('setting-maint-killswitch').checked,
            message: document.getElementById('setting-maint-message').value.trim()
        };

        const pointsVal = {
            scan_base: parseInt(document.getElementById('setting-points-base').value) || 10,
            game_correct: parseInt(document.getElementById('setting-points-correct').value) || 5,
            streak_bonus_per: parseInt(document.getElementById('setting-points-streak').value) || 1
        };

        const geminiVal = {
            model: document.getElementById('setting-gemini-model').value.trim() || 'gemini-3.8-flash'
        };

        await api.apiSaveSystemSettings({
            maintenanceVal,
            pointsVal,
            geminiVal,
            userId
        });

        alert('Lưu cấu hình hệ thống thành công!');
    } catch (e) {
        alert('Lỗi: ' + e.message);
    } finally {
        btn.disabled = false;
        btn.innerText = 'LƯU CẤU HÌNH HỆ THỐNG';
    }
};

// -------------------------------------------------------------
// TAB 5: COLLECTION POINTS MANAGEMENT
// -------------------------------------------------------------
let cpPage = 1;
const CP_LIMIT = 12;
let allCollectionPoints = [];

const POINT_TYPE_MAP = {
    'recycle': { label: 'Tái chế', color: 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30' },
    'organic': { label: 'Hữu cơ', color: 'bg-lime-50 text-lime-700 border-lime-200 dark:bg-lime-500/10 dark:text-lime-400 dark:border-lime-500/30' },
    'hazardous': { label: 'Nguy hại', color: 'bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:border-rose-500/30' },
    'general': { label: 'Rác chung', color: 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700' },
    'ewaste': { label: 'Rác điện tử', color: 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30' },
};

function getCPTypeBadge(type) {
    const info = POINT_TYPE_MAP[type] || POINT_TYPE_MAP['general'];
    return `<span class="px-2 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md border ${info.color}">${info.label}</span>`;
}

function updateCPPagination(total) {
    const btnPrev = document.getElementById('btn-cp-prev');
    const btnNext = document.getElementById('btn-cp-next');
    const info = document.getElementById('cp-page-info');

    const start = (cpPage - 1) * CP_LIMIT + 1;
    const end = Math.min(cpPage * CP_LIMIT, total);

    if (total === 0) {
        info.innerText = 'Không có dữ liệu';
        btnPrev.disabled = true;
        btnNext.disabled = true;
    } else {
        info.innerText = `Hiển thị ${start}-${end} trên ${total}`;
        btnPrev.disabled = cpPage === 1;
        btnNext.disabled = end >= total;
    }
}

window.fetchCollectionPoints = async (page = 1) => {
    cpPage = page;
    const grid = document.getElementById('grid-collection-points');
    const loader = document.getElementById('loader-collection-points');
    const verifiedFilter = document.getElementById('filter-cp-verified').value;

    grid.innerHTML = '';
    loader.classList.remove('hidden');

    const fromIndex = (cpPage - 1) * CP_LIMIT;
    const toIndex = fromIndex + CP_LIMIT - 1;

    try {
        const [pointsRes, profiles] = await Promise.all([
            api.apiFetchCollectionPoints(
                verifiedFilter === '' ? null : verifiedFilter,
                fromIndex,
                toIndex
            ),
            api.apiFetchAllProfiles().catch(() => [])
        ]);

        const profilesMap = {};
        if (Array.isArray(profiles)) {
            profiles.forEach(p => profilesMap[p.id] = p.display_name || p.id);
        }

        const { data, count } = pointsRes;
        loader.classList.add('hidden');
        allCollectionPoints = (data || []).map(pt => ({
            ...pt,
            contributor_name: pt.created_by ? (profilesMap[pt.created_by] || 'Cộng đồng') : 'Hệ thống'
        }));

        if (allCollectionPoints.length === 0) {
            grid.innerHTML = `<div class="col-span-full py-16 text-center text-slate-500 dark:text-slate-400 font-semibold text-sm">Không có điểm thu gom nào</div>`;
            updateCPPagination(0);
            return;
        }

        allCollectionPoints.forEach(point => {
            const card = document.createElement('div');
            card.className = 'glass-panel glass-panel-hover rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col shadow-sm';

            const verifiedBadge = point.is_verified
                ? '<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30">Đã duyệt</span>'
                : '<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30">Chờ duyệt</span>';

            const contributorName = point.contributor_name;
            const createdDate = point.created_at ? new Date(point.created_at).toLocaleDateString('vi-VN') : 'N/A';

            card.innerHTML = `
                <div class="h-44 bg-slate-100 dark:bg-slate-950 relative group border-b border-slate-200 dark:border-slate-800">
                    ${point.image_url
                        ? `<img src="${escapeHTML(point.image_url)}" class="w-full h-full object-cover" onerror="this.parentElement.innerHTML='<div class=\\'w-full h-full flex items-center justify-center text-slate-400 dark:text-slate-600\\'><svg class=\\'w-10 h-10\\' fill=\\'none\\' stroke=\\'currentColor\\' viewBox=\\'0 0 24 24\\'><path stroke-linecap=\\'round\\' stroke-linejoin=\\'round\\' stroke-width=\\'1.5\\' d=\\'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z\\'></path><path stroke-linecap=\\'round\\' stroke-linejoin=\\'round\\' stroke-width=\\'1.5\\' d=\\'M15 11a3 3 0 11-6 0 3 3 0 016 0z\\'></path></svg></div>'">`
                        : '<div class="w-full h-full flex items-center justify-center text-slate-400 dark:text-slate-600"><svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg></div>'
                    }
                    <div class="absolute top-3 right-3">${verifiedBadge}</div>
                </div>
                <div class="p-5 flex-1 flex flex-col justify-between">
                    <div>
                        <h3 class="font-bold text-slate-900 dark:text-white text-base truncate font-heading">${escapeHTML(point.name || 'Điểm chưa đặt tên')}</h3>
                        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1 line-clamp-2">${escapeHTML(point.address || 'Chưa có địa chỉ')}</p>
                        <div class="mt-2.5">
                            ${getCPTypeBadge(point.point_type)}
                        </div>
                    </div>
                    <div class="mt-4 pt-3.5 border-t border-slate-100 dark:border-slate-800/60">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Đóng góp bởi</span>
                            <span class="text-xs font-semibold text-emerald-700 dark:text-emerald-400 truncate max-w-[130px]">${escapeHTML(contributorName)}</span>
                        </div>
                        <div class="flex items-center justify-between mb-3.5">
                            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Ngày gửi</span>
                            <span class="text-xs font-medium text-slate-600 dark:text-slate-300">${createdDate}</span>
                        </div>
                        <div class="flex gap-2">
                            <button onclick="showCPDetail('${escapeHTML(point.id)}')" class="flex-1 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 py-2.5 rounded-xl text-xs font-bold transition">CHI TIẾT</button>
                            ${!point.is_verified ? `
                                <button onclick="approveCPDirect('${escapeHTML(point.id)}')" class="bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30 px-3.5 rounded-xl font-bold text-xs transition" title="Duyệt nhanh">✓</button>
                                <button onclick="rejectCPDirect('${escapeHTML(point.id)}')" class="bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 px-3.5 rounded-xl font-bold text-xs transition" title="Từ chối">✕</button>
                            ` : ''}
                        </div>
                    </div>
                </div>
            `;
            grid.appendChild(card);
        });

        updateCPPagination(count || allCollectionPoints.length);
    } catch (e) {
        loader.classList.add('hidden');
        grid.innerHTML = `<div class="col-span-full p-6 bg-rose-50 dark:bg-rose-950/20 border border-rose-200 dark:border-rose-900/40 text-rose-600 dark:text-rose-400 rounded-xl text-sm font-semibold">Lỗi: ${escapeHTML(e.message || 'Không xác định')}</div>`;
    }
};

window.changeCPPage = (delta) => {
    window.fetchCollectionPoints(cpPage + delta);
};

window.showCPDetail = (id) => {
    const point = allCollectionPoints.find(p => p.id === id);
    if (!point) return;

    const content = document.getElementById('cp-detail-content');
    const contributorName = point.contributor_name || (point.created_by ? 'Cộng đồng' : 'Hệ thống');
    const createdDate = point.created_at ? new Date(point.created_at).toLocaleString('vi-VN') : 'N/A';

    content.innerHTML = `
        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="bg-slate-100 dark:bg-slate-950 rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 flex items-center justify-center min-h-[180px]">
                ${point.image_url
                    ? `<img src="${escapeHTML(point.image_url)}" class="w-full h-full object-contain">`
                    : '<div class="p-8 text-center text-slate-400 dark:text-slate-600"><svg class="w-12 h-12 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg><p class="font-bold text-xs uppercase tracking-wider">KHÔNG CÓ ẢNH</p></div>'
                }
            </div>
            <div class="space-y-3">
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Tên điểm thu gom</span>
                    <p class="text-lg font-bold text-slate-900 dark:text-white mt-1 font-heading">${escapeHTML(point.name || 'Chưa đặt tên')}</p>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Loại điểm</span>
                    <div class="mt-1.5">${getCPTypeBadge(point.point_type)}</div>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trạng thái</span>
                    <div class="mt-1.5">
                        ${point.is_verified
                            ? '<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30">Đã duyệt</span>'
                            : '<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30">Chờ duyệt</span>'
                        }
                    </div>
                </div>
            </div>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Địa chỉ</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1 leading-relaxed">${escapeHTML(point.address || 'Chưa có địa chỉ')}</p>
        </div>
        ${point.description ? `
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Mô tả</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1 leading-relaxed">${escapeHTML(point.description)}</p>
        </div>
        ` : ''}
        <div class="grid grid-cols-2 gap-3">
            <div class="bg-slate-50 dark:bg-slate-900/60 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Người đóng góp</span>
                <p class="text-emerald-700 dark:text-emerald-400 font-bold text-xs sm:text-sm mt-0.5 truncate">${escapeHTML(contributorName)}</p>
            </div>
            <div class="bg-slate-50 dark:bg-slate-900/60 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Ngày gửi</span>
                <p class="text-slate-700 dark:text-slate-300 font-medium text-xs sm:text-sm mt-0.5">${createdDate}</p>
            </div>
        </div>
        ${!point.is_verified ? `
        <div class="pt-4 border-t border-slate-200 dark:border-slate-800 flex gap-3">
            <button onclick="approveCPFromModal('${escapeHTML(point.id)}')" class="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">DUYỆT ĐIỂM THU GOM</button>
            <button onclick="rejectCPFromModal('${escapeHTML(point.id)}')" class="flex-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 py-3 rounded-xl font-bold text-sm transition">TỪ CHỐI</button>
        </div>
        ` : ''}
    `;

    document.getElementById('cp-detail-modal').classList.remove('hidden');
    document.getElementById('cp-detail-modal').classList.add('flex');
};

window.closeCPDetailModal = () => {
    document.getElementById('cp-detail-modal').classList.add('hidden');
    document.getElementById('cp-detail-modal').classList.remove('flex');
};

window.approveCPDirect = async (id) => {
    if (!confirm('Duyệt điểm thu gom này? Sau khi duyệt, điểm sẽ hiển thị trên bản đồ cho tất cả người dùng.')) return;
    try {
        await api.apiApproveCollectionPoint(id);
        alert('Đã duyệt thành công! Điểm thu gom sẽ hiển thị trên bản đồ.');
        window.fetchCollectionPoints(cpPage);
    } catch (e) {
        alert('Lỗi duyệt: ' + (e.message || 'Không xác định'));
    }
};

window.rejectCPDirect = async (id) => {
    if (!confirm('Từ chối và xóa điểm thu gom này? Hành động không thể hoàn tác.')) return;
    try {
        await api.apiRejectCollectionPoint(id);
        alert('Đã từ chối và xóa điểm thu gom.');
        window.fetchCollectionPoints(cpPage);
    } catch (e) {
        alert('Lỗi: ' + (e.message || 'Không xác định'));
    }
};

window.approveCPFromModal = async (id) => {
    await window.approveCPDirect(id);
    closeCPDetailModal();
};

window.rejectCPFromModal = async (id) => {
    await window.rejectCPDirect(id);
    closeCPDetailModal();
};

// -------------------------------------------------------------
// INITIALIZATION IIFE
// -------------------------------------------------------------
(async function init() {
    try {
        const { data: { session } } = await db.auth.getSession();
        if (!session) return window.location.replace('index.html');

        const user = await checkAdminPermissions(session.user);
        const emailEl = document.getElementById('admin-email');
        if (emailEl) emailEl.innerText = user.email;
        currentUserRole = user.role || 'admin';
        document.getElementById('auth-loader').classList.add('hidden');

        window.fetchWasteGroups();
        window.fetchSubmissions();
    } catch (e) {
        alert('Phiên đăng nhập hết hạn hoặc lỗi: ' + e.message);
        window.location.replace('index.html');
    }
})();
