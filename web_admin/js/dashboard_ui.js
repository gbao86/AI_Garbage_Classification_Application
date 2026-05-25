import { db, handleLogout, checkAdminPermissions } from './auth.js';
import * as api from './dashboard_api.js';

// Expose core variables/functions
window.db = db;
window.handleLogout = handleLogout;

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
    'draft': '<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-slate-100 text-slate-600">Bản thảo</span>',
    'awaiting_second_approval': '<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-amber-100 text-amber-700 animate-pulse">Chờ duyệt lần 2</span>',
    'approved': '<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-green-100 text-green-700">Đã duyệt (Chờ thực thi)</span>',
    'rejected': '<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-red-100 text-red-700">Đã từ chối</span>',
    'executed': '<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-blue-100 text-blue-700">Đã thực thi</span>',
    'expired': '<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-gray-200 text-gray-500">Đã hết hạn</span>'
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
            grid.innerHTML = `<div class="col-span-full py-20 text-center text-slate-300 font-bold">Không có báo cáo nào ở trạng thái ${escapeHTML(status)}</div>`;
            return;
        }

        allSubmissions.forEach(item => {
            const card = document.createElement('div');
            card.className = 'bg-white rounded-[2.5rem] shadow-sm border border-slate-100 overflow-hidden hover:shadow-xl transition-all duration-300';
            card.innerHTML = `
                <div class="h-44 bg-slate-50 relative group">
                    ${item.scan_image_path ? `<img src="${escapeHTML(item.scan_image_path)}" class="w-full h-full object-cover">` : '<div class="w-full h-full flex items-center justify-center text-slate-300 text-[10px] font-bold">NO IMAGE</div>'}
                </div>
                <div class="p-8">
                    <h3 class="font-black text-slate-800 text-lg truncate">${escapeHTML(item.suggested_name_vi || 'Yêu cầu mới')}</h3>
                    <p class="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1 mb-6 italic">${escapeHTML(item.tflite_top_label || 'AI chưa phân loại')}</p>

                    <div class="flex gap-2">
                        <button onclick="showDetail('${escapeHTML(item.id)}')" class="flex-1 bg-slate-800 text-white py-3 rounded-2xl text-xs font-black hover:bg-slate-900 transition">CHI TIẾT</button>
                        ${status === 'pending_review' ? `
                            <button onclick="updateStatus('${escapeHTML(item.id)}', 'rejected')" class="bg-red-50 text-red-500 px-4 rounded-2xl font-bold text-xs hover:bg-red-100 transition">HỦY</button>
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
        errorDiv.className = 'col-span-full p-10 bg-red-50 text-red-500 rounded-3xl text-sm font-bold';
        errorDiv.textContent = `Lỗi: ${e && e.message ? e.message : 'Không xác định'}`;
        grid.appendChild(errorDiv);
    }
};

window.showDetail = (id) => {
    const item = allSubmissions.find(s => s.id === id);
    if (!item) return;

    const content = document.getElementById('detail-content');
    content.innerHTML = `
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="bg-slate-50 rounded-[2rem] overflow-hidden border border-slate-100">
                ${item.scan_image_path ? `<img src="${escapeHTML(item.scan_image_path)}" class="w-full h-full object-contain">` : '<p class="p-20 text-center text-slate-300 font-bold">KHÔNG CÓ ẢNH</p>'}
            </div>
            <div class="space-y-4">
                <div class="bg-slate-50 p-6 rounded-3xl">
                    <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Tên đề xuất</span>
                    <p class="text-xl font-black text-slate-800">${escapeHTML(item.suggested_name_vi || 'N/A')}</p>
                </div>
                <div class="bg-slate-50 p-6 rounded-3xl">
                    <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Nhãn AI (TFLite)</span>
                    <p class="font-bold text-slate-800">${escapeHTML(item.tflite_top_label || 'N/A')} (${(item.tflite_confidence * 100).toFixed(1)}%)</p>
                </div>
                 <div class="bg-slate-50 p-6 rounded-3xl">
                    <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Trạng thái</span>
                    <p class="font-bold text-green-600 uppercase">${escapeHTML(item.status)}</p>
                </div>
            </div>
        </div>
        <div class="bg-slate-50 p-6 rounded-3xl">
            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Phân tích Gemini</span>
            <p class="text-slate-600 text-sm mt-2 leading-relaxed">${escapeHTML(item.gemini_payload?.result_text || 'Chưa có phân tích')}</p>
        </div>
        <div class="bg-slate-50 p-6 rounded-3xl">
            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Kiến thức bổ sung (Fun Fact)</span>
            <p class="text-slate-600 text-sm mt-2">${escapeHTML(item.suggested_fun_fact || 'N/A')}</p>
        </div>
        ${item.status === 'pending_review' ? `
            <div class="pt-6 border-t border-slate-100 flex gap-4">
                <button onclick="approveWithData('${escapeHTML(item.id)}')" class="flex-[2] bg-green-600 text-white py-4 rounded-2xl font-black shadow-lg shadow-green-100 hover:bg-green-700 transition">DUYỆT VÀO HỆ THỐNG</button>
                <button onclick="updateStatus('${escapeHTML(item.id)}', 'rejected')" class="flex-1 bg-red-50 text-red-500 py-4 rounded-2xl font-bold hover:bg-red-100 transition">TỪ CHỐI</button>
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
    // Append secure random string to prevent duplication
    slug += '-' + generateSecureRandomString(4);

    btn.disabled = true;
    btn.innerText = 'ĐANG LƯU...';

    try {
        const { data: { session } } = await db.auth.getSession();
        const userId = session?.user?.id;

        // 1. Thêm vào waste_dictionary và cập nhật trạng thái báo cáo
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
    document.querySelectorAll('nav button').forEach(el => el.classList.remove('sidebar-active', 'hover:bg-slate-50'));
    document.getElementById('tab-' + tab).classList.remove('hidden');
    document.getElementById('btn-' + tab).classList.add('sidebar-active');
    
    // Đảm bảo các button khác có hover
    document.querySelectorAll('nav button').forEach(btn => {
        if (!btn.classList.contains('sidebar-active')) {
            btn.classList.add('hover:bg-slate-50');
        }
    });

    if (tab === 'submissions') window.fetchSubmissions();
    if (tab === 'users') window.fetchUsers(1);
    if (tab === 'privileged_actions') window.fetchPrivilegedActions(1);
    if (tab === 'settings') window.fetchSystemSettings();
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

        // Client-side filtering cho role và status
        let filteredData = data || [];
        if (roleFilter) filteredData = filteredData.filter(u => u.role === roleFilter);
        if (statusFilter) {
            const isLocked = statusFilter === 'locked';
            filteredData = filteredData.filter(u => u.is_locked === isLocked);
        }

        if (filteredData.length === 0) {
            tbody.innerHTML = `<tr><td colspan="5" class="p-10 text-center text-slate-400 font-bold">Không tìm thấy người dùng nào</td></tr>`;
            updateUserPagination(0);
            return;
        }

        const totalCount = data.length > 0 && data[0].total_count ? parseInt(data[0].total_count) : filteredData.length;

        filteredData.forEach(u => {
            const tr = document.createElement('tr');
            tr.className = 'hover:bg-slate-50 transition border-b border-slate-50 last:border-none';

            const roleColor = u.role === 'super_admin' ? 'bg-purple-100 text-purple-700' :
                u.role === 'admin' ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-600';

            const statusHtml = u.is_locked
                ? '<span class="px-3 py-1 rounded-full bg-red-100 text-red-600 font-bold text-[10px] uppercase tracking-wider flex items-center justify-center gap-1 w-max mx-auto"><div class="w-1.5 h-1.5 rounded-full bg-red-500"></div> Bị khóa</span>'
                : '<span class="px-3 py-1 rounded-full bg-green-100 text-green-600 font-bold text-[10px] uppercase tracking-wider flex items-center justify-center gap-1 w-max mx-auto"><div class="w-1.5 h-1.5 rounded-full bg-green-500"></div> Hoạt động</span>';

            const isProtected = u.role === 'super_admin' && currentUserRole !== 'super_admin';

            tr.innerHTML = `
                <td class="p-4">
                    <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center font-black text-slate-400">
                            ${(u.display_name || u.email || '?').charAt(0).toUpperCase()}
                        </div>
                        <div>
                            <p class="font-bold text-slate-800 text-sm">${u.display_name || 'Chưa cập nhật'}</p>
                            <p class="text-xs text-slate-500 font-medium">${u.email || 'Ẩn email (Cần RPC)'}</p>
                        </div>
                    </div>
                </td>
                <td class="p-4 text-center">
                    <span class="px-3 py-1 rounded-lg ${roleColor} font-black text-[10px] uppercase tracking-widest">${u.role}</span>
                </td>
                <td class="p-4 text-center">${statusHtml}</td>
                <td class="p-4 text-xs text-slate-500 font-bold">${u.last_sign_in_at ? new Date(u.last_sign_in_at).toLocaleString() : 'Chưa có data'}</td>
                <td class="p-4 text-right">
                    <button onclick="openUserActionModal('${u.id}', '${u.email}', '${u.role}', ${u.is_locked})" 
                        class="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl text-xs font-bold hover:bg-slate-200 transition ${isProtected ? 'opacity-50 cursor-not-allowed' : ''}"
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
        tbody.innerHTML = `<tr><td colspan="5" class="p-10 text-center bg-red-50 text-red-500 font-bold rounded-2xl">Lỗi: ${escapeHTML(e.message)}</td></tr>`;
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
        btnBan.className = 'w-full bg-green-600 text-white py-4 rounded-xl font-black shadow-lg shadow-green-200 hover:bg-green-700 transition';
        inputReason.classList.add('hidden');
    } else {
        btnBan.innerText = 'KHÓA TÀI KHOẢN (BAN)';
        btnBan.className = 'w-full bg-red-600 text-white py-4 rounded-xl font-black shadow-lg shadow-red-200 hover:bg-red-700 transition';
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
            tbody.innerHTML = '<tr><td colspan="5" class="p-10 text-center text-slate-400 font-bold">Không có yêu cầu đặc quyền nào</td></tr>';
            updatePAPagination(0);
            return;
        }

        privilegedActions.forEach(item => {
            const tr = document.createElement('tr');
            tr.className = 'hover:bg-slate-50 transition border-b border-slate-50 last:border-none';

            const actionName = ACTION_TYPE_MAP[item.action_type] || item.action_type;
            const stateHtml = STATE_BADGE_MAP[item.state] || item.state;
            const requesterName = profilesMap[item.requester_id] || 'N/A';

            tr.innerHTML = `
                <td class="p-6">
                    <p class="font-bold text-slate-800 text-sm">${actionName}</p>
                    <p class="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">ID: ${item.id}</p>
                </td>
                <td class="p-6 text-center text-sm font-semibold text-slate-600">${requesterName}</td>
                <td class="p-6 text-center">${stateHtml}</td>
                <td class="p-6 text-xs text-slate-500 font-semibold">${new Date(item.created_at).toLocaleString()}</td>
                <td class="p-6 text-right">
                    <button onclick="showPADetail('${item.id}')"
                        class="px-4 py-2 bg-slate-800 text-white rounded-xl text-xs font-black hover:bg-slate-900 transition shadow-sm">
                        CHI TIẾT
                    </button>
                </td>
            `;
            tbody.appendChild(tr);
        });

        updatePAPagination(count || 0);
    } catch (e) {
        loader.classList.add('hidden');
        tbody.innerHTML = `<tr><td colspan="5" class="p-10 text-center bg-red-50 text-red-500 font-bold rounded-2xl">Lỗi: ${escapeHTML(e.message)}</td></tr>`;
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
    content.innerHTML = '<p class="text-slate-400 font-bold text-center">Đang tải chi tiết phê duyệt...</p>';
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
                <div class="flex justify-between items-center bg-slate-50 p-4 rounded-xl border border-slate-100">
                    <div>
                        <p class="font-bold text-slate-800 text-sm">${profilesMap[a.approver_id] || a.approver_id}</p>
                        <p class="text-xs text-slate-500 mt-0.5">${a.comment || 'Không có bình luận'}</p>
                    </div>
                    <span class="text-[10px] text-slate-400 font-bold">${new Date(a.created_at).toLocaleString()}</span>
                </div>
            `).join('');
        } else {
            approvalsHtml = '<p class="text-xs text-slate-400 italic">Chưa có lượt phê duyệt nào.</p>';
        }

        const payloadStr = JSON.stringify(item.payload, null, 2);

        content.innerHTML = `
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-4">
                    <div class="bg-slate-50 p-6 rounded-3xl">
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Loại hành động</span>
                        <p class="text-lg font-black text-slate-800 mt-1">${actionName}</p>
                    </div>
                    <div class="bg-slate-50 p-6 rounded-3xl">
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Người yêu cầu</span>
                        <p class="font-bold text-slate-800 mt-1">${requesterName}</p>
                    </div>
                    <div class="bg-slate-50 p-6 rounded-3xl">
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Trạng thái</span>
                        <div class="mt-2">${stateHtml}</div>
                    </div>
                </div>
                <div class="bg-slate-50 p-6 rounded-3xl flex flex-col">
                    <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Dữ liệu Payload (JSON)</span>
                    <pre class="bg-slate-800 text-green-400 p-4 rounded-xl text-xs font-mono overflow-auto flex-1 max-h-[160px]">${payloadStr}</pre>
                </div>
            </div>

            <div class="bg-slate-50 p-6 rounded-3xl">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Lý do tạo yêu cầu</span>
                <p class="text-slate-600 text-sm mt-2 leading-relaxed">${item.execution_note || 'N/A'}</p>
            </div>

            <div class="space-y-3">
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Danh sách phê duyệt (${approvals ? approvals.length : 0}/2)</span>
                <div class="space-y-2 max-h-[180px] overflow-y-auto">
                    ${approvalsHtml}
                </div>
            </div>

            <div class="pt-6 border-t border-slate-100 flex flex-wrap gap-4">
                ${(item.state === 'draft' || item.state === 'awaiting_second_approval') ? `
                    ${isRequester ? `
                        <div class="w-full p-4 bg-yellow-50 text-yellow-800 border border-yellow-100 rounded-xl text-xs font-semibold text-center">
                            ⚠️ Bạn là người tạo yêu cầu này. Hãy nhờ Admin khác phê duyệt để đảm bảo quy trình.
                        </div>
                    ` : `
                        ${hasApproved ? `
                            <div class="w-full p-4 bg-green-50 text-green-800 border border-green-100 rounded-xl text-xs font-semibold text-center">
                                ✓ Bạn đã phê duyệt yêu cầu này rồi.
                            </div>
                        ` : `
                            <button onclick="approvePARequest('${item.id}')" class="flex-[2] bg-green-600 text-white py-4 rounded-2xl font-black shadow-lg shadow-green-100 hover:bg-green-700 transition">PHÊ DUYỆT</button>
                            <button onclick="rejectPARequest('${item.id}')" class="flex-1 bg-red-50 text-red-500 py-4 rounded-2xl font-bold hover:bg-red-100 transition">TỪ CHỐI</button>
                        `}
                    `}
                ` : ''}

                ${item.state === 'approved' ? `
                    <button onclick="executePARequest('${item.id}')" class="w-full bg-blue-600 text-white py-4 rounded-2xl font-black shadow-lg shadow-blue-100 hover:bg-blue-700 transition">THỰC THI HÀNG ĐỘNG</button>
                ` : ''}

                ${item.state === 'executed' ? `
                    <div class="w-full p-5 bg-blue-50/50 text-blue-800 border border-blue-100 rounded-2xl text-xs">
                        <p class="font-bold">✓ Đã thực thi thành công</p>
                        <p class="mt-1 font-semibold text-blue-600">Ghi chú: ${item.execution_note || 'N/A'}</p>
                        <p class="text-[10px] text-slate-400 mt-1 font-bold">Lúc: ${new Date(item.executed_at).toLocaleString()}</p>
                    </div>
                ` : ''}
            </div>
        `;
    } catch (e) {
        content.innerHTML = `<div class="p-10 bg-red-50 text-red-500 rounded-3xl text-sm font-bold text-center">Lỗi tải chi tiết: ${escapeHTML(e.message)}</div>`;
    }
};

window.closePADetailModal = () => {
    document.getElementById('pa-detail-modal').classList.add('hidden');
};

window.approvePARequest = async (id) => {
    const comment = prompt('Nhập ý kiến phê duyệt (Không bắt buộc):');
    if (comment === null) return; // Cancel

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

        // 1. Thực thi nghiệp vụ trên cơ sở dữ liệu
        await api.apiExecuteAction(item.action_type, item.payload);

        // 2. Đánh dấu trạng thái yêu cầu là đã thực thi
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
    container.innerHTML = '<p class="text-xs text-slate-400 font-bold">Đang tải dữ liệu cấu hình...</p>';

    try {
        if (type === 'promote_user_admin' || type === 'demote_admin') {
            const users = await api.apiFetchUsers(1, 1000, null);
            const targetRole = type === 'promote_user_admin' ? 'user' : 'admin';
            const targets = users.filter(u => u.role === targetRole);

            if (!targets || targets.length === 0) {
                container.innerHTML = `<p class="text-xs text-red-500 font-bold">Không tìm thấy ${targetRole} nào để thao tác.</p>`;
                return;
            }

            let options = targets.map(u => `<option value="${u.id}">${u.display_name || u.email || u.id}</option>`).join('');
            container.innerHTML = `
                <div>
                    <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Chọn Người dùng</label>
                    <select id="pa-input-user" required class="w-full p-4 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none text-slate-800">
                        ${options}
                    </select>
                </div>
            `;
        } else if (type === 'toggle_kill_switch') {
            container.innerHTML = `
                <div>
                    <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Trạng thái Kill Switch (Ngắt khẩn cấp)</label>
                    <select id="pa-input-killswitch" required class="w-full p-4 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none text-slate-800">
                        <option value="true">BẬT (Chỉ cho phép Super Admin thao tác, chặn hoàn toàn API User)</option>
                        <option value="false">TẮT (Hoạt động bình thường)</option>
                    </select>
                </div>
            `;
        } else if (type === 'delete_collection_point') {
            const { data: points } = await db.from('collection_points').select('id, name');
            if (!points || points.length === 0) {
                container.innerHTML = '<p class="text-xs text-red-500 font-bold">Không tìm thấy điểm bỏ rác nào.</p>';
                return;
            }
            let options = points.map(p => `<option value="${p.id}">${p.name}</option>`).join('');
            container.innerHTML = `
                <div>
                    <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Chọn Điểm bỏ rác muốn xóa</label>
                    <select id="pa-input-point" required class="w-full p-4 bg-slate-50 border-2 border-slate-100 rounded-2xl outline-none text-slate-800">
                        ${options}
                    </select>
                </div>
            `;
        } else {
            container.innerHTML = '';
        }
    } catch (e) {
        container.innerHTML = `<p class="text-xs text-red-500 font-bold">Lỗi tải dữ liệu: ${escapeHTML(e.message)}</p>`;
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

        // Map config values
        const maintenance = data.find(s => s.key === 'maintenance')?.value || { enabled: false, kill_switch: false, message: "" };
        const points = data.find(s => s.key === 'points')?.value || { scan_base: 10, game_correct: 5, streak_bonus_per: 1 };
        const gemini = data.find(s => s.key === 'gemini')?.value || { model: "gemini-flash-latest" };

        document.getElementById('setting-maint-enabled').checked = !!maintenance.enabled;
        document.getElementById('setting-maint-killswitch').checked = !!maintenance.kill_switch;
        document.getElementById('setting-maint-message').value = maintenance.message || '';

        document.getElementById('setting-points-base').value = points.scan_base || 10;
        document.getElementById('setting-points-correct').value = points.game_correct || 5;
        document.getElementById('setting-points-streak').value = points.streak_bonus_per || 1;

        document.getElementById('setting-gemini-model').value = gemini.model || 'gemini-flash-latest';

        const inputs = [
            'setting-maint-enabled', 'setting-maint-killswitch', 'setting-maint-message',
            'setting-points-base', 'setting-points-correct', 'setting-points-streak',
            'setting-gemini-model'
        ];

        if (currentUserRole !== 'super_admin') {
            inputs.forEach(id => document.getElementById(id).disabled = true);
            document.getElementById('settings-save-container').classList.add('hidden');
            statusBadge.innerHTML = '<span class="px-4 py-2 rounded-xl bg-amber-100 text-amber-800 font-bold text-xs uppercase tracking-widest shadow-sm">Chế độ Chỉ Xem (Chỉ Super Admin được sửa)</span>';
        } else {
            inputs.forEach(id => document.getElementById(id).disabled = false);
            document.getElementById('settings-save-container').classList.remove('hidden');
            statusBadge.innerHTML = '<span class="px-4 py-2 rounded-xl bg-green-100 text-green-800 font-bold text-xs uppercase tracking-widest shadow-sm border border-green-200">Quyền chỉnh sửa Super Admin</span>';
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
            model: document.getElementById('setting-gemini-model').value.trim() || 'gemini-flash-latest'
        };

        await api.apiSaveSystemSettings({
            maintenanceVal,
            pointsVal,
            geminiVal,
            userId
        });

        alert('Đã cập nhật cấu hình hệ thống thành công!');
        window.fetchSystemSettings();
    } catch (e) {
        alert('Lỗi lưu cấu hình: ' + e.message);
    } finally {
        btn.disabled = false;
        btn.innerText = 'LƯU CẤU HÌNH HỆ THỐNG';
    }
};

// -------------------------------------------------------------
// INITIALIZATION IIFE
// -------------------------------------------------------------
(async function init() {
    try {
        const { data: { session } } = await db.auth.getSession();
        if (!session) return window.location.replace('index.html');

        const user = await checkAdminPermissions(session.user);
        document.getElementById('admin-email').innerText = user.email;
        currentUserRole = user.role || 'admin';
        document.getElementById('auth-loader').classList.add('hidden');

        window.fetchWasteGroups();
        window.fetchSubmissions();
    } catch (e) {
        alert('Phiên đăng nhập hết hạn hoặc lỗi: ' + e.message);
        window.location.replace('index.html');
    }
})();
