import { db } from './auth.js';

/**
 * Fetch waste submissions filtered by status.
 */
export async function apiFetchSubmissions(status) {
    const { data, error } = await db.from('waste_submissions')
        .select('*')
        .eq('status', status)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
}

/**
 * Update the review status of a waste submission.
 */
export async function apiUpdateSubmissionStatus(id, newStatus) {
    const { data, error } = await db.from('waste_submissions')
        .update({ status: newStatus })
        .eq('id', id);

    if (error) throw error;
    return data;
}

/**
 * Fetch all waste groups ordered by sort_order.
 */
export async function apiFetchWasteGroups() {
    const { data, error } = await db.from('waste_groups')
        .select('id, name_vi')
        .order('sort_order');

    if (error) throw error;
    return data || [];
}

/**
 * Insert a new entry into the waste dictionary.
 */
export async function apiInsertWasteDictionary({ slug, nameVi, funFact, imageUrl, groupId, userId }) {
    const { error } = await db.from('waste_dictionary').insert({
        slug: slug,
        name_vi: nameVi,
        fun_fact: funFact || null,
        image_url: imageUrl || null,
        waste_group_id: parseInt(groupId),
        created_by: userId,
        is_active: true
    });

    if (error) throw error;
}

/**
 * Fetch profiles/users list with pagination and search.
 */
export async function apiFetchUsers(page, limit, search) {
    const { data, error } = await db.rpc('admin_get_users', {
        p_page: page,
        p_limit: limit,
        p_search: search || null
    });

    if (error) throw error;
    return data || [];
}

/**
 * Ban or unban a user.
 */
export async function apiBanUser(userId, reason, isLocked) {
    const { error } = await db.rpc('admin_ban_user', {
        p_user_id: userId,
        p_reason: isLocked ? reason : null,
        p_is_locked: isLocked
    });

    if (error) throw error;
}

/**
 * Reset user password (trigger reset link).
 */
export async function apiResetUserPassword(email) {
    const { error } = await db.auth.resetPasswordForEmail(email);
    if (error) throw error;
}

/**
 * Fetch all profiles to map display names.
 */
export async function apiFetchAllProfiles() {
    const { data, error } = await db.from('profiles').select('id, display_name');
    if (error) throw error;
    return data || [];
}

/**
 * Fetch privileged action requests with pagination and optional state filter.
 */
export async function apiFetchPrivilegedActions(stateFilter, fromIndex, toIndex) {
    let query = db.from('privileged_action_requests')
        .select('*', { count: 'exact' });

    if (stateFilter) {
        query = query.eq('state', stateFilter);
    }

    const { data, count, error } = await query
        .order('created_at', { ascending: false })
        .range(fromIndex, toIndex);

    if (error) throw error;
    return { data: data || [], count };
}

/**
 * Fetch approvals for a given privileged action request.
 */
export async function apiFetchApprovals(requestId) {
    const { data, error } = await db.from('privileged_action_approvals')
        .select('*')
        .eq('request_id', requestId);

    if (error) throw error;
    return data || [];
}

/**
 * Add approval to a privileged action request.
 */
export async function apiApprovePrivilegedAction(requestId, comment) {
    const { data, error } = await db.rpc('privileged_action_add_approval', {
        p_request_id: requestId,
        p_comment: comment || null
    });

    if (error) throw error;
    return data;
}

/**
 * Reject a privileged action request.
 */
export async function apiRejectPrivilegedAction(id, rejectionNote) {
    const { error } = await db.from('privileged_action_requests').update({
        state: 'rejected',
        execution_note: rejectionNote
    }).eq('id', id);

    if (error) throw error;
}

/**
 * Insert a new privileged action request.
 */
export async function apiInsertPrivilegedAction({ actionType, payload, requesterId, reason }) {
    const { error } = await db.from('privileged_action_requests').insert({
        action_type: actionType,
        payload: payload,
        requester_id: requesterId,
        execution_note: reason
    });

    if (error) throw error;
}

/**
 * Execute privileged action: business logic for specific requests.
 */
export async function apiExecuteAction(actionType, payload) {
    if (actionType === 'promote_user_admin') {
        const { error } = await db.from('profiles').update({ role: 'admin' }).eq('id', payload.user_id);
        if (error) throw error;
    } else if (actionType === 'demote_admin') {
        const { error } = await db.from('profiles').update({ role: 'user' }).eq('id', payload.user_id);
        if (error) throw error;
    } else if (actionType === 'delete_collection_point') {
        const { error } = await db.from('collection_points').delete().eq('id', payload.point_id);
        if (error) throw error;
    } else if (actionType === 'toggle_kill_switch') {
        // Fetch current maintenance settings
        const { data: currentMaint } = await db.from('system_settings').select('value').eq('key', 'maintenance').maybeSingle();
        const updatedVal = currentMaint?.value || { enabled: false, message: "" };
        updatedVal.kill_switch = payload.kill_switch;

        const { error } = await db.from('system_settings').update({ value: updatedVal }).eq('key', 'maintenance');
        if (error) throw error;
    } else {
        throw new Error('Chưa hỗ trợ thực thi tự động cho loại hành động này.');
    }
}

/**
 * Update request state to 'executed'.
 */
export async function apiMarkActionExecuted(id, note) {
    const { error } = await db.from('privileged_action_requests').update({
        state: 'executed',
        executed_at: new Date().toISOString(),
        execution_note: note
    }).eq('id', id);

    if (error) throw error;
}

/**
 * Fetch system settings.
 */
export async function apiFetchSystemSettings() {
    const { data, error } = await db.from('system_settings').select('*');
    if (error) throw error;
    return data || [];
}

/**
 * Save system settings.
 */
export async function apiSaveSystemSettings({ maintenanceVal, pointsVal, geminiVal, userId }) {
    const { error: err1 } = await db.from('system_settings').update({ value: maintenanceVal, updated_by: userId }).eq('key', 'maintenance');
    const { error: err2 } = await db.from('system_settings').update({ value: pointsVal, updated_by: userId }).eq('key', 'points');
    const { error: err3 } = await db.from('system_settings').update({ value: geminiVal, updated_by: userId }).eq('key', 'gemini');

    if (err1 || err2 || err3) {
        throw new Error('Lỗi cập nhật cấu hình: ' + (err1?.message || err2?.message || err3?.message));
    }
}
