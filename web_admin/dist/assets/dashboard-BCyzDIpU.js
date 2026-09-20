import{n as e,r as t,t as n}from"./auth-BN_Q-61b.js";async function r(t){let{data:n,error:r}=await e.from(`waste_submissions`).select(`*`).eq(`status`,t).order(`created_at`,{ascending:!1});if(r)throw r;return n||[]}async function i(t,n){let{data:r,error:i}=await e.from(`waste_submissions`).update({status:n}).eq(`id`,t);if(i)throw i;return r}async function a(){let{data:t,error:n}=await e.from(`waste_groups`).select(`id, name_vi`).order(`sort_order`);if(n)throw n;return t||[]}async function o({slug:t,nameVi:n,funFact:r,imageUrl:i,groupId:a,userId:o}){let{error:s}=await e.from(`waste_dictionary`).insert({slug:t,name_vi:n,fun_fact:r||null,image_url:i||null,waste_group_id:parseInt(a),created_by:o,is_active:!0});if(s)throw s}async function s(t,n,r){let{data:i,error:a}=await e.rpc(`admin_get_users`,{p_page:t,p_limit:n,p_search:r||null});if(a)throw a;return i||[]}async function c(t,n,r){let{error:i}=await e.rpc(`admin_ban_user`,{p_user_id:t,p_reason:r?n:null,p_is_locked:r});if(i)throw i}async function l(t){let{error:n}=await e.auth.resetPasswordForEmail(t);if(n)throw n}async function u(){let{data:t,error:n}=await e.from(`profiles`).select(`id, display_name`);if(n)throw n;return t||[]}async function d(t,n,r){let i=e.from(`privileged_action_requests`).select(`*`,{count:`exact`});t&&(i=i.eq(`state`,t));let{data:a,count:o,error:s}=await i.order(`created_at`,{ascending:!1}).range(n,r);if(s)throw s;return{data:a||[],count:o}}async function f(t){let{data:n,error:r}=await e.from(`privileged_action_approvals`).select(`*`).eq(`request_id`,t);if(r)throw r;return n||[]}async function p(t,n){let{data:r,error:i}=await e.rpc(`privileged_action_add_approval`,{p_request_id:t,p_comment:n||null});if(i)throw i;return r}async function m(t,n){let{error:r}=await e.from(`privileged_action_requests`).update({state:`rejected`,execution_note:n}).eq(`id`,t);if(r)throw r}async function h({actionType:t,payload:n,requesterId:r,reason:i}){let{error:a}=await e.from(`privileged_action_requests`).insert({action_type:t,payload:n,requester_id:r,execution_note:i});if(a)throw a}async function g(t,n){if(t===`promote_user_admin`){let{error:t}=await e.from(`profiles`).update({role:`admin`}).eq(`id`,n.user_id);if(t)throw t}else if(t===`demote_admin`){let{error:t}=await e.from(`profiles`).update({role:`user`}).eq(`id`,n.user_id);if(t)throw t}else if(t===`delete_collection_point`){let{error:t}=await e.from(`collection_points`).delete().eq(`id`,n.point_id);if(t)throw t}else if(t===`toggle_kill_switch`){let{data:t}=await e.from(`system_settings`).select(`value`).eq(`key`,`maintenance`).maybeSingle(),r=t?.value||{enabled:!1,message:``};r.kill_switch=n.kill_switch;let{error:i}=await e.from(`system_settings`).update({value:r}).eq(`key`,`maintenance`);if(i)throw i}else throw Error(`Chưa hỗ trợ thực thi tự động cho loại hành động này.`)}async function _(t,n){let{error:r}=await e.from(`privileged_action_requests`).update({state:`executed`,executed_at:new Date().toISOString(),execution_note:n}).eq(`id`,t);if(r)throw r}async function v(){let{data:t,error:n}=await e.from(`system_settings`).select(`*`);if(n)throw n;return t||[]}async function y({maintenanceVal:t,pointsVal:n,geminiVal:r,userId:i}){let{error:a}=await e.from(`system_settings`).update({value:t,updated_by:i}).eq(`key`,`maintenance`),{error:o}=await e.from(`system_settings`).update({value:n,updated_by:i}).eq(`key`,`points`),{error:s}=await e.from(`system_settings`).update({value:r,updated_by:i}).eq(`key`,`gemini`);if(a||o||s)throw Error(`Lỗi cập nhật cấu hình: `+(a?.message||o?.message||s?.message))}async function b(t,n,r){let i=e.from(`collection_points`).select(`*`,{count:`exact`});t!=null&&t!==``&&(i=i.eq(`is_verified`,t===`true`||t===!0));let{data:a,count:o,error:s}=await i.order(`created_at`,{ascending:!1}).range(n,r);if(s)throw s;return{data:a||[],count:o}}async function x(t){let{error:n}=await e.from(`collection_points`).update({is_verified:!0}).eq(`id`,t);if(n)throw n}async function S(t){let{error:n}=await e.from(`collection_points`).delete().eq(`id`,t);if(n)throw n}async function C(t,n,r,i){let a=i?`
            id,
            waste_dictionary_id,
            game_types,
            payload,
            is_active,
            created_at,
            waste_dictionary!inner (
                id,
                name_vi,
                image_url,
                fun_fact,
                waste_group_id,
                waste_groups (
                    id,
                    code,
                    name_vi
                )
            )
        `:`
            id,
            waste_dictionary_id,
            game_types,
            payload,
            is_active,
            created_at,
            waste_dictionary (
                id,
                name_vi,
                image_url,
                fun_fact,
                waste_group_id,
                waste_groups (
                    id,
                    code,
                    name_vi
                )
            )
        `,o=e.from(`game_questions`).select(a,{count:`exact`});r!=null&&r!==``&&(o=o.eq(`is_active`,r===`true`||r===!0)),i!=null&&i!==``&&(o=o.eq(`waste_dictionary.waste_group_id`,parseInt(i)));let{data:s,count:c,error:l}=await o.order(`created_at`,{ascending:!1}).range(t,n);if(l)throw l;return{data:s||[],count:c}}async function w({slug:t,nameVi:n,groupId:r,imageUrl:i,funFact:a,isActive:o,userId:s}){let c=parseInt(r),{data:l,error:u}=await e.from(`waste_dictionary`).insert({slug:t,name_vi:n,waste_group_id:c,image_url:i||null,fun_fact:a||null,created_by:s,is_active:!0}).select(`id`).single();if(u)throw u;let{error:d}=await e.from(`game_questions`).insert({waste_dictionary_id:l.id,game_types:[`quiz`],payload:{name_vi:n,waste_group_id:c,image_url:i||null,fun_fact:a||null},is_active:o});if(d)throw d}async function ee({questionId:t,dictId:n,nameVi:r,groupId:i,imageUrl:a,funFact:o,isActive:s}){let c=parseInt(i),l=n;if(!l&&t){let{data:n}=await e.from(`game_questions`).select(`waste_dictionary_id`).eq(`id`,t).single();l=n?.waste_dictionary_id}if(l){let{error:t}=await e.from(`waste_dictionary`).update({name_vi:r,waste_group_id:c,image_url:a||null,fun_fact:o||null,updated_at:new Date().toISOString()}).eq(`id`,l);if(t)throw t}let{error:u}=await e.from(`game_questions`).update({is_active:s,payload:{name_vi:r,waste_group_id:c,image_url:a||null,fun_fact:o||null},updated_at:new Date().toISOString()}).eq(`id`,t);if(u)throw u}async function te(t,n){let{error:r}=await e.from(`game_questions`).update({is_active:n,updated_at:new Date().toISOString()}).eq(`id`,t);if(r)throw r}async function ne(t,n){let{error:r}=await e.from(`game_questions`).delete().eq(`id`,t);if(r)throw r;n&&await e.from(`waste_dictionary`).delete().eq(`id`,n).catch(()=>{})}window.db=e,window.handleLogout=t,window.toggleMobileSidebar=e=>{let t=document.getElementById(`sidebar`),n=document.getElementById(`sidebar-backdrop`);if(!t)return;let r=t.classList.contains(`-translate-x-full`);(typeof e==`boolean`?e:r)?(t.classList.remove(`-translate-x-full`),n?.classList.remove(`hidden`)):(t.classList.add(`-translate-x-full`),n?.classList.add(`hidden`))},window.toggleTheme=()=>{document.documentElement.classList.contains(`dark`)?(document.documentElement.classList.remove(`dark`),localStorage.setItem(`ecosort_theme`,`light`)):(document.documentElement.classList.add(`dark`),localStorage.setItem(`ecosort_theme`,`dark`)),T()};function T(){let e=document.documentElement.classList.contains(`dark`),t=document.getElementById(`theme-toggle-btn`);t&&(t.innerHTML=e?`
            <svg class="w-4 h-4 text-amber-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
            </svg>
            <span>Chế độ Sáng</span>
        `:`
            <svg class="w-4 h-4 text-slate-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
            </svg>
            <span>Chế độ Tối</span>
        `),document.querySelectorAll(`.mobile-theme-btn`).forEach(t=>{t.innerHTML=e?`
            <svg class="w-5 h-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path>
            </svg>
        `:`
            <svg class="w-5 h-5 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path>
            </svg>
        `})}T();var E=[],D=[],O=1,k=25,A=`admin`,j=[],M=1,N=25,P={promote_user_admin:`Nâng cấp User lên Admin`,demote_admin:`Hạ cấp Admin xuống User`,toggle_kill_switch:`Ngắt khẩn cấp (Kill Switch)`,delete_collection_point:`Xóa điểm bỏ rác`,purge_user_data:`Xóa dữ liệu người dùng`,other:`Hành động khác`},F={draft:`<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-slate-100 text-slate-600 border border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700">Bản thảo</span>`,awaiting_second_approval:`<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30">Chờ duyệt lần 2</span>`,approved:`<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30">Đã duyệt (Chờ thực thi)</span>`,rejected:`<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-rose-50 text-rose-700 border border-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:border-rose-500/30">Đã từ chối</span>`,executed:`<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-teal-50 text-teal-700 border border-teal-200 dark:bg-teal-500/10 dark:text-teal-400 dark:border-teal-500/30">Đã thực thi</span>`,expired:`<span class="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-slate-100 text-slate-500 border border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700">Đã hết hạn</span>`};function I(e){return String(e).normalize(`NFKD`).replace(/[\u0300-\u036f]/g,``).trim().toLowerCase().replace(/[^a-z0-9 -]/g,``).replace(/\s+/g,`-`).replace(/-+/g,`-`)}function L(e){return e?String(e).replace(/&/g,`&amp;`).replace(/</g,`&lt;`).replace(/>/g,`&gt;`).replace(/"/g,`&quot;`).replace(/'/g,`&#039;`):``}function R(e=4){let t=new Uint8Array(e);(window.crypto||crypto).getRandomValues(t);let n=``;for(let r=0;r<e;r++)n+=`abcdefghijklmnopqrstuvwxyz0123456789`[t[r]%36];return n}window.fetchSubmissions=async()=>{let e=document.getElementById(`grid-submissions`),t=document.getElementById(`loader-submissions`),n=document.getElementById(`filter-status`).value;t.classList.remove(`hidden`),e.innerHTML=``;try{if(E=await r(n),t.classList.add(`hidden`),E.length===0){e.innerHTML=`<div class="col-span-full py-16 text-center text-slate-500 dark:text-slate-400 font-semibold text-sm">Không có báo cáo nào ở trạng thái ${L(n)}</div>`;return}E.forEach(t=>{let r=document.createElement(`div`);r.className=`glass-panel glass-panel-hover rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col justify-between shadow-sm`,r.innerHTML=`
                <div class="h-44 bg-slate-100 dark:bg-slate-950 relative group border-b border-slate-200 dark:border-slate-800">
                    ${t.scan_image_path?`<img src="${L(t.scan_image_path)}" class="w-full h-full object-cover">`:`<div class="w-full h-full flex items-center justify-center text-slate-400 dark:text-slate-600 text-xs font-semibold uppercase tracking-wider">Không có ảnh</div>`}
                </div>
                <div class="p-5 flex-1 flex flex-col justify-between">
                    <div>
                        <h3 class="font-bold text-slate-900 dark:text-white text-base truncate font-heading">${L(t.suggested_name_vi||`Yêu cầu mới`)}</h3>
                        <p class="text-xs text-emerald-600 dark:text-emerald-400 font-semibold uppercase tracking-wider mt-1 mb-5">${L(t.tflite_top_label||`AI chưa phân loại`)}</p>
                    </div>

                    <div class="flex gap-2 pt-2 border-t border-slate-100 dark:border-slate-800/60">
                        <button onclick="showDetail('${L(t.id)}')" class="flex-1 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 py-2.5 rounded-xl text-xs font-bold transition">CHI TIẾT</button>
                        ${n===`pending_review`?`
                            <button onclick="updateStatus('${L(t.id)}', 'rejected')" class="bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 px-3.5 rounded-xl font-bold text-xs transition">HỦY</button>
                        `:``}
                    </div>
                </div>
            `,e.appendChild(r)})}catch(n){t.classList.add(`hidden`),e.innerHTML=``;let r=document.createElement(`div`);r.className=`col-span-full p-6 bg-rose-50 dark:bg-rose-950/20 border border-rose-200 dark:border-rose-900/40 text-rose-600 dark:text-rose-400 rounded-xl text-sm font-semibold`,r.textContent=`Lỗi: ${n&&n.message?n.message:`Không xác định`}`,e.appendChild(r)}},window.showDetail=e=>{let t=E.find(t=>t.id===e);if(!t)return;let n=document.getElementById(`detail-content`);n.innerHTML=`
        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="bg-slate-100 dark:bg-slate-950 rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 flex items-center justify-center min-h-[180px]">
                ${t.scan_image_path?`<img src="${L(t.scan_image_path)}" class="w-full h-full object-contain">`:`<p class="p-10 text-center text-slate-400 dark:text-slate-600 font-semibold text-xs uppercase tracking-wider">KHÔNG CÓ ẢNH</p>`}
            </div>
            <div class="space-y-3">
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Tên đề xuất</span>
                    <p class="text-lg font-bold text-slate-900 dark:text-white mt-1 font-heading">${L(t.suggested_name_vi||`N/A`)}</p>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Nhãn AI (TFLite)</span>
                    <p class="font-bold text-emerald-600 dark:text-emerald-400 mt-1">${L(t.tflite_top_label||`N/A`)} (${(t.tflite_confidence*100).toFixed(1)}%)</p>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trạng thái</span>
                    <p class="font-bold text-emerald-600 dark:text-emerald-400 uppercase mt-1 text-sm">${L(t.status)}</p>
                </div>
            </div>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Phân tích Gemini</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1.5 leading-relaxed">${L(t.gemini_payload?.result_text||`Chưa có phân tích`)}</p>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Kiến thức bổ sung (Fun Fact)</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1.5">${L(t.suggested_fun_fact||`N/A`)}</p>
        </div>
        ${t.status===`pending_review`?`
            <div class="pt-4 border-t border-slate-200 dark:border-slate-800 flex gap-3">
                <button onclick="approveWithData('${L(t.id)}')" class="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">DUYỆT VÀO HỆ THỐNG</button>
                <button onclick="updateStatus('${L(t.id)}', 'rejected')" class="flex-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 py-3 rounded-xl font-bold text-sm transition">TỪ CHỐI</button>
            </div>
        `:``}
    `,document.getElementById(`detail-modal`).classList.remove(`hidden`),document.getElementById(`detail-modal`).classList.add(`flex`)},window.closeDetailModal=()=>{document.getElementById(`detail-modal`).classList.add(`hidden`),document.getElementById(`detail-modal`).classList.remove(`flex`)},window.fetchWasteGroups=async()=>{try{D=await a();let e=document.getElementById(`approve-group`);e&&(e.innerHTML=`<option value="">-- Chọn nhóm rác --</option>`,D.forEach(t=>{e.innerHTML+=`<option value="${t.id}">${t.id}: ${t.name_vi}</option>`}))}catch(e){console.error(`Lỗi tải nhóm rác:`,e)}},window.approveWithData=e=>{let t=E.find(t=>t.id===e);t&&(document.getElementById(`approve-id`).value=t.id,document.getElementById(`approve-image-url`).value=t.scan_image_path||``,document.getElementById(`approve-name`).value=t.suggested_name_vi||``,document.getElementById(`approve-funfact`).value=t.suggested_fun_fact||``,document.getElementById(`approve-group`).value=``,document.getElementById(`approve-modal`).classList.remove(`hidden`),document.getElementById(`approve-modal`).classList.add(`flex`))},window.closeApproveModal=()=>{document.getElementById(`approve-modal`).classList.add(`hidden`),document.getElementById(`approve-modal`).classList.remove(`flex`)},window.submitApproveData=async()=>{let t=document.getElementById(`btn-submit-approve`),n=document.getElementById(`approve-id`).value,r=document.getElementById(`approve-image-url`).value,a=document.getElementById(`approve-name`).value.trim(),s=document.getElementById(`approve-group`).value,c=document.getElementById(`approve-funfact`).value.trim();if(!a||!s)return alert(`Vui lòng nhập tên và chọn nhóm rác!`);let l=I(a);l+=`-`+R(4),t.disabled=!0,t.innerText=`ĐANG LƯU...`;try{let{data:{session:t}}=await e.auth.getSession(),u=t?.user?.id;await o({slug:l,nameVi:a,funFact:c,imageUrl:r,groupId:s,userId:u}),await i(n,`approved`),alert(`Đã duyệt và lưu vào từ điển thành công!`),closeApproveModal(),closeDetailModal(),window.fetchSubmissions()}catch(e){console.error(e),alert(e.message)}finally{t.disabled=!1,t.innerText=`XÁC NHẬN LƯU VÀO TỪ ĐIỂN`}},window.updateStatus=async(e,t)=>{try{await i(e,t),closeDetailModal(),window.fetchSubmissions()}catch(e){alert(e.message)}},window.switchTab=e=>{document.querySelectorAll(`.tab-content`).forEach(e=>e.classList.add(`hidden`)),document.querySelectorAll(`nav button`).forEach(e=>e.classList.remove(`sidebar-active`,`hover:bg-slate-100`,`dark:hover:bg-slate-800`));let t=document.getElementById(`tab-`+e),n=document.getElementById(`btn-`+e);t&&t.classList.remove(`hidden`),n&&n.classList.add(`sidebar-active`),document.querySelectorAll(`nav button`).forEach(e=>{e.classList.contains(`sidebar-active`)||e.classList.add(`hover:bg-slate-100`,`dark:hover:bg-slate-800`)}),window.toggleMobileSidebar(!1),e===`submissions`&&window.fetchSubmissions(),e===`users`&&window.fetchUsers(1),e===`privileged_actions`&&window.fetchPrivilegedActions(1),e===`settings`&&window.fetchSystemSettings(),e===`collection_points`&&window.fetchCollectionPoints(1),e===`game_questions`&&window.fetchGameQuestions(1)};function z(e){let t=document.getElementById(`btn-user-prev`),n=document.getElementById(`btn-user-next`),r=document.getElementById(`user-page-info`),i=(O-1)*k+1,a=Math.min(O*k,e);e===0?(r.innerText=`Không có dữ liệu`,t.disabled=!0,n.disabled=!0):(r.innerText=`Hiển thị ${i}-${a} trên ${e}`,t.disabled=O===1,n.disabled=a>=e)}window.fetchUsers=async(e=1)=>{O=e;let t=document.getElementById(`table-users`),n=document.getElementById(`loader-users`),r=document.getElementById(`filter-user-search`).value,i=document.getElementById(`filter-user-role`).value,a=document.getElementById(`filter-user-status`).value;t.innerHTML=``,n.classList.remove(`hidden`),document.getElementById(`user-page-info`).innerText=`Đang tải...`;try{let e=await s(O,k,r);n.classList.add(`hidden`);let o=e||[];if(i&&(o=o.filter(e=>e.role===i)),a){let e=a===`locked`;o=o.filter(t=>t.is_locked===e)}if(o.length===0){t.innerHTML=`<tr><td colspan="5" class="p-8 text-center text-slate-400 dark:text-slate-500 font-semibold text-sm">Không tìm thấy người dùng nào</td></tr>`,z(0);return}let c=e.length>0&&e[0].total_count?parseInt(e[0].total_count):o.length;o.forEach(e=>{let n=document.createElement(`tr`);n.className=`hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition border-b border-slate-200 dark:border-slate-800/60 last:border-none`;let r=e.role===`super_admin`?`bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-500/10 dark:border-purple-500/30 dark:text-purple-400`:e.role===`admin`?`bg-sky-50 text-sky-700 border-sky-200 dark:bg-cyan-500/10 dark:border-cyan-500/30 dark:text-cyan-400`:`bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:border-slate-700 dark:text-slate-400`,i=e.is_locked?`<span class="px-2.5 py-0.5 rounded-full bg-rose-50 dark:bg-rose-500/10 border border-rose-200 dark:border-rose-500/30 text-rose-700 dark:text-rose-400 font-bold text-[11px] uppercase tracking-wider flex items-center justify-center gap-1.5 w-max mx-auto"><div class="w-1.5 h-1.5 rounded-full bg-rose-500"></div> Bị khóa</span>`:`<span class="px-2.5 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/30 text-emerald-700 dark:text-emerald-400 font-bold text-[11px] uppercase tracking-wider flex items-center justify-center gap-1.5 w-max mx-auto"><div class="w-1.5 h-1.5 rounded-full bg-emerald-500"></div> Hoạt động</span>`,a=e.role===`super_admin`&&A!==`super_admin`;n.innerHTML=`
                <td class="p-3.5 sm:p-4">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/60 flex items-center justify-center font-bold text-emerald-600 dark:text-emerald-400 font-heading text-xs shrink-0">
                            ${(e.display_name||e.email||`?`).charAt(0).toUpperCase()}
                        </div>
                        <div class="min-w-0">
                            <p class="font-semibold text-slate-900 dark:text-white text-sm truncate font-heading">${L(e.display_name||`Chưa cập nhật`)}</p>
                            <p class="text-xs text-slate-500 dark:text-slate-400 font-normal truncate">${L(e.email||`Ẩn email`)}</p>
                        </div>
                    </div>
                </td>
                <td class="p-3.5 sm:p-4 text-center">
                    <span class="px-2.5 py-1 rounded-lg ${r} border font-bold text-[11px] uppercase tracking-wider">${e.role}</span>
                </td>
                <td class="p-3.5 sm:p-4 text-center">${i}</td>
                <td class="p-3.5 sm:p-4 text-xs text-slate-500 dark:text-slate-400 font-medium">${e.last_sign_in_at?new Date(e.last_sign_in_at).toLocaleString():`Chưa có data`}</td>
                <td class="p-3.5 sm:p-4 text-right">
                    <button onclick="openUserActionModal('${e.id}', '${e.email}', '${e.role}', ${e.is_locked})" 
                        class="px-3 py-1.5 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-300 dark:border-slate-700 rounded-lg text-xs font-semibold shadow-sm transition ${a?`opacity-40 cursor-not-allowed`:``}"
                        ${a?`disabled title="Không có quyền thao tác lên Super Admin"`:``}>
                        QUẢN LÝ
                    </button>
                </td>
            `,t.appendChild(n)}),z(c)}catch(e){n.classList.add(`hidden`),t.innerHTML=`<tr><td colspan="5" class="p-8 text-center text-rose-500 font-semibold text-sm">Lỗi: ${L(e.message)}</td></tr>`}},window.changeUserPage=e=>{window.fetchUsers(O+e)},window.openUserActionModal=(t,n,r,i)=>{if(r===`super_admin`&&A!==`super_admin`)return alert(`Từ chối truy cập: Bạn không có quyền thao tác lên tài khoản Super Admin.`);document.getElementById(`action-user-id`).value=t,document.getElementById(`action-user-locked`).value=i,document.getElementById(`user-action-email`).innerText=n!==`undefined`&&n?n:`ID: `+t,document.getElementById(`user-action-modal`).dataset.targetRole=r;let a=document.getElementById(`btn-toggle-ban`),o=document.getElementById(`ban-reason`);i?(a.innerText=`MỞ KHÓA TÀI KHOẢN (UNBAN)`,a.className=`w-full bg-emerald-600 text-white py-2.5 rounded-lg font-bold text-xs shadow-sm hover:bg-emerald-500 transition`,o.classList.add(`hidden`)):(a.innerText=`KHÓA TÀI KHOẢN (BAN)`,a.className=`w-full bg-rose-600 text-white py-2.5 rounded-lg font-bold text-xs shadow-sm hover:bg-rose-500 transition`,o.classList.remove(`hidden`),o.value=``);let s=document.getElementById(`btn-request-promote`),c=document.getElementById(`btn-request-demote`),l=document.getElementById(`user-role-actions-section`);e.auth.getUser().then(({data:{user:e}})=>{e&&e.id===t?l.classList.add(`hidden`):(l.classList.remove(`hidden`),r===`user`?(s.classList.remove(`hidden`),c.classList.add(`hidden`)):r===`admin`?(s.classList.add(`hidden`),c.classList.remove(`hidden`)):l.classList.add(`hidden`))}).catch(e=>{console.error(e)}),document.getElementById(`user-action-modal`).classList.remove(`hidden`)},window.closeUserActionModal=()=>{document.getElementById(`user-action-modal`).classList.add(`hidden`)},window.toggleBanUser=async()=>{let e=document.getElementById(`action-user-id`).value,t=document.getElementById(`action-user-locked`).value===`true`,n=document.getElementById(`ban-reason`).value.trim();if(!t&&!n)return alert(`Vui lòng nhập lý do khóa tài khoản!`);if(confirm(`Bạn chắc chắn muốn ${t?`mở khóa`:`khóa`} tài khoản này?`))try{await c(e,n,!t),alert(`Đã ${t?`mở khóa`:`khóa`} thành công!`),closeUserActionModal(),window.fetchUsers(O)}catch(e){console.error(e),alert(`Lỗi: `+e.message)}},window.resetUserPassword=async()=>{let e=document.getElementById(`user-action-email`).innerText;if(e.startsWith(`ID:`))return alert(`Không có email của user này để gửi link reset.`);if(confirm(`Gửi email đặt lại mật khẩu tới: ${e}?`))try{await l(e),alert(`Đã gửi link đặt lại mật khẩu thành công! Yêu cầu user kiểm tra hòm thư.`)}catch(e){console.error(e),alert(`Lỗi: `+e.message)}},window.viewUserAuditLogs=()=>{alert(`Tính năng xem Audit Logs đang được xây dựng (Sẽ nạp từ bảng public.audit_logs)`)},window.requestRolePromotion=async()=>{let t=document.getElementById(`action-user-id`).value,n=document.getElementById(`user-action-email`).innerText,r=prompt(`Nhập lý do đề xuất nâng quyền Admin (Bắt buộc):`);if(r)try{let{data:{session:i}}=await e.auth.getSession(),a=i?.user?.id;await h({actionType:`promote_user_admin`,payload:{user_id:t,email:n},requesterId:a,reason:r}),alert(`Đã gửi đề xuất nâng cấp quyền Admin! Yêu cầu cần một Admin/Super Admin khác phê duyệt để có hiệu lực.`),closeUserActionModal()}catch(e){alert(`Lỗi: `+e.message)}},window.requestRoleDemotion=async()=>{let t=document.getElementById(`action-user-id`).value,n=document.getElementById(`user-action-email`).innerText,r=prompt(`Nhập lý do đề xuất hạ quyền Admin xuống User (Bắt buộc):`);if(r)try{let{data:{session:i}}=await e.auth.getSession(),a=i?.user?.id;await h({actionType:`demote_admin`,payload:{user_id:t,email:n},requesterId:a,reason:r}),alert(`Đã gửi đề xuất hạ quyền Admin! Yêu cầu cần một Admin/Super Admin khác phê duyệt để có hiệu lực.`),closeUserActionModal()}catch(e){alert(`Lỗi: `+e.message)}};function B(e){let t=document.getElementById(`btn-pa-prev`),n=document.getElementById(`btn-pa-next`),r=document.getElementById(`pa-page-info`),i=(M-1)*N+1,a=Math.min(M*N,e);e===0?(r.innerText=`Không có dữ liệu`,t.disabled=!0,n.disabled=!0):(r.innerText=`Hiển thị ${i}-${a} trên ${e}`,t.disabled=M===1,n.disabled=a>=e)}window.fetchPrivilegedActions=async(e=1)=>{M=e;let t=document.getElementById(`table-privileged-actions`),n=document.getElementById(`loader-privileged-actions`),r=document.getElementById(`filter-pa-state`).value;t.innerHTML=``,n.classList.remove(`hidden`),document.getElementById(`pa-page-info`).innerText=`Đang tải...`;try{let e=await u(),i={};e.forEach(e=>i[e.id]=e.display_name||e.id);let a=(M-1)*N,{data:o,count:s}=await d(r,a,a+N-1);if(n.classList.add(`hidden`),j=o||[],j.length===0){t.innerHTML=`<tr><td colspan="5" class="p-8 text-center text-slate-400 dark:text-slate-500 font-semibold text-sm">Không có yêu cầu đặc quyền nào</td></tr>`,B(0);return}j.forEach(e=>{let n=document.createElement(`tr`);n.className=`hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition border-b border-slate-200 dark:border-slate-800/60 last:border-none`;let r=P[e.action_type]||e.action_type,a=F[e.state]||e.state,o=i[e.requester_id]||`N/A`;n.innerHTML=`
                <td class="p-3.5 sm:p-4">
                    <p class="font-bold text-slate-900 dark:text-white text-sm font-heading">${r}</p>
                    <p class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mt-0.5">ID: ${e.id}</p>
                </td>
                <td class="p-3.5 sm:p-4 text-center text-sm font-medium text-slate-700 dark:text-slate-300">${o}</td>
                <td class="p-3.5 sm:p-4 text-center">${a}</td>
                <td class="p-3.5 sm:p-4 text-xs text-slate-500 dark:text-slate-400 font-medium">${new Date(e.created_at).toLocaleString()}</td>
                <td class="p-3.5 sm:p-4 text-right">
                    <button onclick="showPADetail('${e.id}')"
                        class="px-3 py-1.5 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 border border-slate-300 dark:border-slate-700 rounded-lg text-xs font-semibold shadow-sm transition">
                        CHI TIẾT
                    </button>
                </td>
            `,t.appendChild(n)}),B(s||0)}catch(e){n.classList.add(`hidden`),t.innerHTML=`<tr><td colspan="5" class="p-8 text-center text-rose-500 font-semibold text-sm">Lỗi: ${L(e.message)}</td></tr>`}},window.changePAPage=e=>{window.fetchPrivilegedActions(M+e)},window.showPADetail=async t=>{let n=j.find(e=>e.id===t);if(!n)return;let r=document.getElementById(`pa-detail-modal`),i=document.getElementById(`pa-detail-content`);i.innerHTML=`<p class="text-slate-500 dark:text-slate-400 font-medium text-center text-sm">Đang tải chi tiết phê duyệt...</p>`,r.classList.remove(`hidden`);try{let r=await f(t),a=await u(),o={};a.forEach(e=>o[e.id]=e.display_name||e.id);let{data:{session:s}}=await e.auth.getSession(),c=s?.user?.id,l=P[n.action_type]||n.action_type,d=F[n.state]||n.state,p=o[n.requester_id]||n.requester_id,m=r&&r.some(e=>e.approver_id===c),h=n.requester_id===c,g=``;g=r&&r.length>0?r.map(e=>`
                <div class="flex justify-between items-center bg-slate-50 dark:bg-slate-900/60 p-3 rounded-xl border border-slate-200 dark:border-slate-800">
                    <div>
                        <p class="font-bold text-slate-900 dark:text-white text-sm font-heading">${o[e.approver_id]||e.approver_id}</p>
                        <p class="text-xs text-slate-600 dark:text-slate-300 mt-0.5">${e.comment||`Không có bình luận`}</p>
                    </div>
                    <span class="text-[10px] text-slate-400 font-semibold">${new Date(e.created_at).toLocaleString()}</span>
                </div>
            `).join(``):`<p class="text-xs text-slate-400 italic">Chưa có lượt phê duyệt nào.</p>`,i.innerHTML=`
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div class="space-y-3">
                    <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                        <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Loại hành động</span>
                        <p class="text-base font-bold text-slate-900 dark:text-white mt-1 font-heading">${l}</p>
                    </div>
                    <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                        <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Người yêu cầu</span>
                        <p class="font-bold text-emerald-600 dark:text-emerald-400 mt-1">${p}</p>
                    </div>
                    <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                        <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trạng thái</span>
                        <div class="mt-1.5">${d}</div>
                    </div>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-2">Dữ liệu Payload (JSON)</span>
                    <pre class="bg-white dark:bg-slate-950 text-slate-800 dark:text-emerald-400 p-3 rounded-lg text-xs font-mono overflow-auto flex-1 max-h-[160px] border border-slate-200 dark:border-slate-800">${JSON.stringify(n.payload,null,2)}</pre>
                </div>
            </div>

            <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Lý do tạo yêu cầu</span>
                <p class="text-slate-700 dark:text-slate-300 text-sm mt-1 leading-relaxed">${n.execution_note||`N/A`}</p>
            </div>

            <div class="space-y-2.5">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Danh sách phê duyệt (${r?r.length:0}/2)</span>
                <div class="space-y-2 max-h-[160px] overflow-y-auto">
                    ${g}
                </div>
            </div>

            <div class="pt-4 border-t border-slate-200 dark:border-slate-800 flex flex-wrap gap-3">
                ${n.state===`draft`||n.state===`awaiting_second_approval`?`
                    ${h?`
                        <div class="w-full p-3 bg-amber-50 dark:bg-amber-500/10 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-500/20 rounded-xl text-xs font-semibold text-center">
                            ⚠️ Bạn là người tạo yêu cầu này. Cần Admin khác phê duyệt để đảm bảo quy trình khách quan.
                        </div>
                    `:`
                        ${m?`
                            <div class="w-full p-3 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/20 rounded-xl text-xs font-semibold text-center">
                                ✓ Bạn đã phê duyệt yêu cầu này rồi.
                            </div>
                        `:`
                            <button onclick="approvePARequest('${n.id}')" class="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">PHÊ DUYỆT</button>
                            <button onclick="rejectPARequest('${n.id}')" class="flex-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 py-3 rounded-xl font-bold text-sm transition">TỪ CHỐI</button>
                        `}
                    `}
                `:``}

                ${n.state===`approved`?`
                    <button onclick="executePARequest('${n.id}')" class="w-full bg-sky-600 hover:bg-sky-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">THỰC THI HÀNH ĐỘNG</button>
                `:``}

                ${n.state===`executed`?`
                    <div class="w-full p-3.5 bg-sky-50 dark:bg-sky-950/30 text-sky-800 dark:text-sky-300 border border-sky-200 dark:border-sky-800/40 rounded-xl text-xs">
                        <p class="font-bold">✓ Đã thực thi thành công</p>
                        <p class="mt-1 font-semibold text-sky-700 dark:text-sky-400">Ghi chú: ${n.execution_note||`N/A`}</p>
                        <p class="text-[10px] text-slate-500 dark:text-slate-400 mt-1">Lúc: ${new Date(n.executed_at).toLocaleString()}</p>
                    </div>
                `:``}
            </div>
        `}catch(e){i.innerHTML=`<div class="p-8 text-rose-500 font-semibold text-sm text-center">Lỗi tải chi tiết: ${L(e.message)}</div>`}},window.closePADetailModal=()=>{document.getElementById(`pa-detail-modal`).classList.add(`hidden`)},window.approvePARequest=async e=>{let t=prompt(`Nhập ý kiến phê duyệt (Không bắt buộc):`);if(t!==null)try{let n=await p(e,t);alert(`Đã phê duyệt thành công! Trạng thái hiện tại: `+(P[n]||n)),closePADetailModal(),window.fetchPrivilegedActions(M)}catch(e){alert(`Lỗi phê duyệt: `+e.message)}},window.rejectPARequest=async t=>{let n=prompt(`Nhập lý do từ chối (Bắt buộc):`);if(n)try{let{data:{session:r}}=await e.auth.getSession();await m(t,`Bị từ chối bởi ${r?.user?.email||`Admin`}. Lý do: ${n}`),alert(`Đã từ chối yêu cầu này!`),closePADetailModal(),window.fetchPrivilegedActions(M)}catch(e){alert(`Lỗi: `+e.message)}},window.executePARequest=async t=>{let n=j.find(e=>e.id===t);if(n&&confirm(`Bạn chắc chắn muốn thực thi hành động này trực tiếp lên hệ thống?`))try{let{data:{session:r}}=await e.auth.getSession(),i=r?.user?.email||`Admin`;await g(n.action_type,n.payload),await _(t,`Thực thi thành công bởi ${i}`),alert(`Thực thi hành động thành công!`),closePADetailModal(),window.fetchPrivilegedActions(M)}catch(e){alert(`Lỗi thực thi: `+e.message)}},window.openCreatePAModal=async()=>{document.getElementById(`create-pa-form`).reset(),document.getElementById(`create-pa-payload-inputs`).innerHTML=``,document.getElementById(`create-pa-modal`).classList.remove(`hidden`)},window.closeCreatePAModal=()=>{document.getElementById(`create-pa-modal`).classList.add(`hidden`)},window.handlePATypeChange=async()=>{let t=document.getElementById(`create-pa-type`).value,n=document.getElementById(`create-pa-payload-inputs`);n.innerHTML=`<p class="text-xs text-slate-400 font-medium">Đang tải dữ liệu cấu hình...</p>`;try{if(t===`promote_user_admin`||t===`demote_admin`){let e=await s(1,1e3,null),r=t===`promote_user_admin`?`user`:`admin`,i=e.filter(e=>e.role===r);if(!i||i.length===0){n.innerHTML=`<p class="text-xs text-rose-500 font-medium">Không tìm thấy ${r} nào để thao tác.</p>`;return}n.innerHTML=`
                <div>
                    <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">Chọn Người dùng</label>
                    <select id="pa-input-user" required class="w-full p-2.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none text-slate-900 dark:text-slate-100 text-sm">
                        ${i.map(e=>`<option value="${e.id}">${e.display_name||e.email||e.id}</option>`).join(``)}
                    </select>
                </div>
            `}else if(t===`toggle_kill_switch`)n.innerHTML=`
                <div>
                    <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">Trạng thái Kill Switch (Ngắt khẩn cấp)</label>
                    <select id="pa-input-killswitch" required class="w-full p-2.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none text-slate-900 dark:text-slate-100 text-sm">
                        <option value="true">BẬT (Chặn hoàn toàn API ghi của Người dùng)</option>
                        <option value="false">TẮT (Hoạt động bình thường)</option>
                    </select>
                </div>
            `;else if(t===`delete_collection_point`){let{data:t}=await e.from(`collection_points`).select(`id, name`);if(!t||t.length===0){n.innerHTML=`<p class="text-xs text-rose-500 font-medium">Không tìm thấy điểm bỏ rác nào.</p>`;return}n.innerHTML=`
                <div>
                    <label class="block text-xs font-semibold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">Chọn Điểm bỏ rác muốn xóa</label>
                    <select id="pa-input-point" required class="w-full p-2.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none text-slate-900 dark:text-slate-100 text-sm">
                        ${t.map(e=>`<option value="${e.id}">${e.name}</option>`).join(``)}
                    </select>
                </div>
            `}else n.innerHTML=``}catch(e){n.innerHTML=`<p class="text-xs text-rose-500 font-medium">Lỗi tải dữ liệu: ${L(e.message)}</p>`}},window.submitCreatePARequest=async()=>{let t=document.getElementById(`create-pa-type`).value,n=document.getElementById(`create-pa-reason`).value.trim(),r=document.getElementById(`btn-submit-pa-request`);if(!t||!n)return alert(`Vui lòng điền đầy đủ thông tin!`);let i={};if(t===`promote_user_admin`||t===`demote_admin`){let e=document.getElementById(`pa-input-user`),t=e.options[e.selectedIndex];i={user_id:e.value,name:t.text}}else if(t===`toggle_kill_switch`)i={kill_switch:document.getElementById(`pa-input-killswitch`).value===`true`};else if(t===`delete_collection_point`){let e=document.getElementById(`pa-input-point`),t=e.options[e.selectedIndex];i={point_id:e.value,name:t.text}}r.disabled=!0,r.innerText=`ĐANG GỬI...`;try{let{data:{session:r}}=await e.auth.getSession(),a=r?.user?.id;await h({actionType:t,payload:i,requesterId:a,reason:n}),alert(`Đã gửi yêu cầu phê duyệt thành công!`),closeCreatePAModal(),window.fetchPrivilegedActions(1)}catch(e){alert(`Lỗi gửi yêu cầu: `+e.message)}finally{r.disabled=!1,r.innerText=`GỬI YÊU CẦU DUYỆT`}},window.fetchSystemSettings=async()=>{let e=document.getElementById(`settings-form-container`),t=document.getElementById(`loader-settings`),n=document.getElementById(`settings-status-badge`);e.classList.add(`hidden`),t.classList.remove(`hidden`);try{let r=await v();t.classList.add(`hidden`),e.classList.remove(`hidden`);let i=r.find(e=>e.key===`maintenance`)?.value||{enabled:!1,kill_switch:!1,message:``},a=r.find(e=>e.key===`points`)?.value||{scan_base:10,game_correct:5,streak_bonus_per:1},o=r.find(e=>e.key===`gemini`)?.value||{model:`gemini-3.8-flash`};document.getElementById(`setting-maint-enabled`).checked=!!i.enabled,document.getElementById(`setting-maint-killswitch`).checked=!!i.kill_switch,document.getElementById(`setting-maint-message`).value=i.message||``,document.getElementById(`setting-points-base`).value=a.scan_base||10,document.getElementById(`setting-points-correct`).value=a.game_correct||5,document.getElementById(`setting-points-streak`).value=a.streak_bonus_per||1,document.getElementById(`setting-gemini-model`).value=o.model||`gemini-3.8-flash`;let s=[`setting-maint-enabled`,`setting-maint-killswitch`,`setting-maint-message`,`setting-points-base`,`setting-points-correct`,`setting-points-streak`,`setting-gemini-model`];A===`super_admin`?(s.forEach(e=>document.getElementById(e).disabled=!1),document.getElementById(`settings-save-container`).classList.remove(`hidden`),n.innerHTML=`<span class="px-3.5 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:border-emerald-500/30 dark:text-emerald-400 font-bold text-xs uppercase tracking-wider">Quyền chỉnh sửa Super Admin</span>`):(s.forEach(e=>document.getElementById(e).disabled=!0),document.getElementById(`settings-save-container`).classList.add(`hidden`),n.innerHTML=`<span class="px-3.5 py-1.5 rounded-lg bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:border-amber-500/30 dark:text-amber-400 font-bold text-xs uppercase tracking-wider">Chế độ Chỉ Xem (Chỉ Super Admin được sửa)</span>`)}catch(e){t.classList.add(`hidden`),alert(`Lỗi tải cấu hình: `+e.message)}},window.saveSystemSettings=async()=>{let t=document.getElementById(`btn-save-settings`);t.disabled=!0,t.innerText=`ĐANG LƯU...`;try{let{data:{session:t}}=await e.auth.getSession(),n=t?.user?.id;await y({maintenanceVal:{enabled:document.getElementById(`setting-maint-enabled`).checked,kill_switch:document.getElementById(`setting-maint-killswitch`).checked,message:document.getElementById(`setting-maint-message`).value.trim()},pointsVal:{scan_base:parseInt(document.getElementById(`setting-points-base`).value)||10,game_correct:parseInt(document.getElementById(`setting-points-correct`).value)||5,streak_bonus_per:parseInt(document.getElementById(`setting-points-streak`).value)||1},geminiVal:{model:document.getElementById(`setting-gemini-model`).value.trim()||`gemini-3.8-flash`},userId:n}),alert(`Lưu cấu hình hệ thống thành công!`)}catch(e){alert(`Lỗi: `+e.message)}finally{t.disabled=!1,t.innerText=`LƯU CẤU HÌNH HỆ THỐNG`}};var V=1,H=12,U=[],W={recycle:{label:`Tái chế`,color:`bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30`},organic:{label:`Hữu cơ`,color:`bg-lime-50 text-lime-700 border-lime-200 dark:bg-lime-500/10 dark:text-lime-400 dark:border-lime-500/30`},hazardous:{label:`Nguy hại`,color:`bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-500/10 dark:text-rose-400 dark:border-rose-500/30`},general:{label:`Rác chung`,color:`bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700`},ewaste:{label:`Rác điện tử`,color:`bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30`}};function G(e){let t=W[e]||W.general;return`<span class="px-2 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md border ${t.color}">${t.label}</span>`}function K(e){let t=document.getElementById(`btn-cp-prev`),n=document.getElementById(`btn-cp-next`),r=document.getElementById(`cp-page-info`),i=(V-1)*H+1,a=Math.min(V*H,e);e===0?(r.innerText=`Không có dữ liệu`,t.disabled=!0,n.disabled=!0):(r.innerText=`Hiển thị ${i}-${a} trên ${e}`,t.disabled=V===1,n.disabled=a>=e)}window.fetchCollectionPoints=async(e=1)=>{V=e;let t=document.getElementById(`grid-collection-points`),n=document.getElementById(`loader-collection-points`),r=document.getElementById(`filter-cp-verified`).value;t.innerHTML=``,n.classList.remove(`hidden`);let i=(V-1)*H,a=i+H-1;try{let[e,o]=await Promise.all([b(r===``?null:r,i,a),u().catch(()=>[])]),s={};Array.isArray(o)&&o.forEach(e=>s[e.id]=e.display_name||e.id);let{data:c,count:l}=e;if(n.classList.add(`hidden`),U=(c||[]).map(e=>({...e,contributor_name:e.created_by?s[e.created_by]||`Cộng đồng`:`Hệ thống`})),U.length===0){t.innerHTML=`<div class="col-span-full py-16 text-center text-slate-500 dark:text-slate-400 font-semibold text-sm">Không có điểm thu gom nào</div>`,K(0);return}U.forEach(e=>{let n=document.createElement(`div`);n.className=`glass-panel glass-panel-hover rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col shadow-sm`;let r=e.is_verified?`<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30">Đã duyệt</span>`:`<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30">Chờ duyệt</span>`,i=e.contributor_name,a=e.created_at?new Date(e.created_at).toLocaleDateString(`vi-VN`):`N/A`;n.innerHTML=`
                <div class="h-44 bg-slate-100 dark:bg-slate-950 relative group border-b border-slate-200 dark:border-slate-800">
                    ${e.image_url?`<img src="${L(e.image_url)}" class="w-full h-full object-cover" onerror="this.parentElement.innerHTML='<div class=\\'w-full h-full flex items-center justify-center text-slate-400 dark:text-slate-600\\'><svg class=\\'w-10 h-10\\' fill=\\'none\\' stroke=\\'currentColor\\' viewBox=\\'0 0 24 24\\'><path stroke-linecap=\\'round\\' stroke-linejoin=\\'round\\' stroke-width=\\'1.5\\' d=\\'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z\\'></path><path stroke-linecap=\\'round\\' stroke-linejoin=\\'round\\' stroke-width=\\'1.5\\' d=\\'M15 11a3 3 0 11-6 0 3 3 0 016 0z\\'></path></svg></div>'">`:`<div class="w-full h-full flex items-center justify-center text-slate-400 dark:text-slate-600"><svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg></div>`}
                    <div class="absolute top-3 right-3">${r}</div>
                </div>
                <div class="p-5 flex-1 flex flex-col justify-between">
                    <div>
                        <h3 class="font-bold text-slate-900 dark:text-white text-base truncate font-heading">${L(e.name||`Điểm chưa đặt tên`)}</h3>
                        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1 line-clamp-2">${L(e.address||`Chưa có địa chỉ`)}</p>
                        <div class="mt-2.5">
                            ${G(e.point_type)}
                        </div>
                    </div>
                    <div class="mt-4 pt-3.5 border-t border-slate-100 dark:border-slate-800/60">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Đóng góp bởi</span>
                            <span class="text-xs font-semibold text-emerald-700 dark:text-emerald-400 truncate max-w-[130px]">${L(i)}</span>
                        </div>
                        <div class="flex items-center justify-between mb-3.5">
                            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Ngày gửi</span>
                            <span class="text-xs font-medium text-slate-600 dark:text-slate-300">${a}</span>
                        </div>
                        <div class="flex gap-2">
                            <button onclick="showCPDetail('${L(e.id)}')" class="flex-1 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 py-2.5 rounded-xl text-xs font-bold transition">CHI TIẾT</button>
                            ${e.is_verified?``:`
                                <button onclick="approveCPDirect('${L(e.id)}')" class="bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30 px-3.5 rounded-xl font-bold text-xs transition" title="Duyệt nhanh">✓</button>
                                <button onclick="rejectCPDirect('${L(e.id)}')" class="bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 px-3.5 rounded-xl font-bold text-xs transition" title="Từ chối">✕</button>
                            `}
                        </div>
                    </div>
                </div>
            `,t.appendChild(n)}),K(l||U.length)}catch(e){n.classList.add(`hidden`),t.innerHTML=`<div class="col-span-full p-6 bg-rose-50 dark:bg-rose-950/20 border border-rose-200 dark:border-rose-900/40 text-rose-600 dark:text-rose-400 rounded-xl text-sm font-semibold">Lỗi: ${L(e.message||`Không xác định`)}</div>`}},window.changeCPPage=e=>{window.fetchCollectionPoints(V+e)},window.showCPDetail=e=>{let t=U.find(t=>t.id===e);if(!t)return;let n=document.getElementById(`cp-detail-content`),r=t.contributor_name||(t.created_by?`Cộng đồng`:`Hệ thống`),i=t.created_at?new Date(t.created_at).toLocaleString(`vi-VN`):`N/A`;n.innerHTML=`
        <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="bg-slate-100 dark:bg-slate-950 rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 flex items-center justify-center min-h-[180px]">
                ${t.image_url?`<img src="${L(t.image_url)}" class="w-full h-full object-contain">`:`<div class="p-8 text-center text-slate-400 dark:text-slate-600"><svg class="w-12 h-12 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg><p class="font-bold text-xs uppercase tracking-wider">KHÔNG CÓ ẢNH</p></div>`}
            </div>
            <div class="space-y-3">
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Tên điểm thu gom</span>
                    <p class="text-lg font-bold text-slate-900 dark:text-white mt-1 font-heading">${L(t.name||`Chưa đặt tên`)}</p>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Loại điểm</span>
                    <div class="mt-1.5">${G(t.point_type)}</div>
                </div>
                <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
                    <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trạng thái</span>
                    <div class="mt-1.5">
                        ${t.is_verified?`<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30">Đã duyệt</span>`:`<span class="px-2.5 py-0.5 text-[11px] font-bold uppercase tracking-wider rounded-md bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/30">Chờ duyệt</span>`}
                    </div>
                </div>
            </div>
        </div>
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Địa chỉ</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1 leading-relaxed">${L(t.address||`Chưa có địa chỉ`)}</p>
        </div>
        ${t.description?`
        <div class="bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
            <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Mô tả</span>
            <p class="text-slate-700 dark:text-slate-300 text-sm mt-1 leading-relaxed">${L(t.description)}</p>
        </div>
        `:``}
        <div class="grid grid-cols-2 gap-3">
            <div class="bg-slate-50 dark:bg-slate-900/60 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Người đóng góp</span>
                <p class="text-emerald-700 dark:text-emerald-400 font-bold text-xs sm:text-sm mt-0.5 truncate">${L(r)}</p>
            </div>
            <div class="bg-slate-50 dark:bg-slate-900/60 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800">
                <span class="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Ngày gửi</span>
                <p class="text-slate-700 dark:text-slate-300 font-medium text-xs sm:text-sm mt-0.5">${i}</p>
            </div>
        </div>
        ${t.is_verified?``:`
        <div class="pt-4 border-t border-slate-200 dark:border-slate-800 flex gap-3">
            <button onclick="approveCPFromModal('${L(t.id)}')" class="flex-[2] bg-emerald-600 hover:bg-emerald-500 text-white py-3 rounded-xl font-bold text-sm transition shadow-sm">DUYỆT ĐIỂM THU GOM</button>
            <button onclick="rejectCPFromModal('${L(t.id)}')" class="flex-1 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 py-3 rounded-xl font-bold text-sm transition">TỪ CHỐI</button>
        </div>
        `}
    `,document.getElementById(`cp-detail-modal`).classList.remove(`hidden`),document.getElementById(`cp-detail-modal`).classList.add(`flex`)},window.closeCPDetailModal=()=>{document.getElementById(`cp-detail-modal`).classList.add(`hidden`),document.getElementById(`cp-detail-modal`).classList.remove(`flex`)},window.approveCPDirect=async e=>{if(confirm(`Duyệt điểm thu gom này? Sau khi duyệt, điểm sẽ hiển thị trên bản đồ cho tất cả người dùng.`))try{await x(e),alert(`Đã duyệt thành công! Điểm thu gom sẽ hiển thị trên bản đồ.`),window.fetchCollectionPoints(V)}catch(e){alert(`Lỗi duyệt: `+(e.message||`Không xác định`))}},window.rejectCPDirect=async e=>{if(confirm(`Từ chối và xóa điểm thu gom này? Hành động không thể hoàn tác.`))try{await S(e),alert(`Đã từ chối và xóa điểm thu gom.`),window.fetchCollectionPoints(V)}catch(e){alert(`Lỗi: `+(e.message||`Không xác định`))}},window.approveCPFromModal=async e=>{await window.approveCPDirect(e),closeCPDetailModal()},window.rejectCPFromModal=async e=>{await window.rejectCPDirect(e),closeCPDetailModal()};var q=1,J=12,Y=[];function X(e){let t=document.getElementById(`btn-q-prev`),n=document.getElementById(`btn-q-next`),r=document.getElementById(`q-page-info`),i=(q-1)*J+1,a=Math.min(q*J,e);e===0?(r&&(r.innerText=`Không có dữ liệu`),t&&(t.disabled=!0),n&&(n.disabled=!0)):(r&&(r.innerText=`Hiển thị ${i}-${a} trên ${e}`),t&&(t.disabled=q===1),n&&(n.disabled=a>=e))}window.changeQPage=e=>{window.fetchGameQuestions(q+e)};var Z={1:{id:1,code:`recyclable`,name:`Tái chế`,badgeClass:`bg-emerald-500/10 text-emerald-400 border-emerald-500/30`},2:{id:2,code:`organic`,name:`Hữu cơ`,badgeClass:`bg-lime-500/10 text-lime-400 border-lime-500/30`},3:{id:3,code:`hazardous`,name:`Nguy hại`,badgeClass:`bg-rose-500/10 text-rose-400 border-rose-500/30`},4:{id:4,code:`trash`,name:`Không tái chế`,badgeClass:`bg-amber-500/10 text-amber-400 border-amber-500/30`}};function Q(e){let t=Array.isArray(e.waste_dictionary)?e.waste_dictionary[0]||{}:e.waste_dictionary||{},n=t.waste_group_id??t.waste_groups?.id??e.payload?.waste_group_id;if(n!=null&&n!==``){let e=parseInt(n);if(!isNaN(e)&&e>=1&&e<=4)return e}let r=(t.waste_groups?.code||e.payload?.correctCategory||e.payload?.category||``).toLowerCase();return r===`recyclable`?1:r===`organic`?2:r===`hazardous`?3:4}window.fetchGameQuestions=async(e=1)=>{q=e;let t=document.getElementById(`grid-game-questions`),n=document.getElementById(`loader-game-questions`),r=document.getElementById(`filter-q-status`)?.value,i=document.getElementById(`filter-q-group`)?.value;if(!t)return;t.innerHTML=``,n&&n.classList.remove(`hidden`);let a=(q-1)*J,o=a+J-1;try{let{data:e,count:t}=await C(a,o,r===``?null:r,i===``?null:i);n&&n.classList.add(`hidden`),Y=e||[],$(Y),X(t||0)}catch(e){n&&n.classList.add(`hidden`),console.error(`Lỗi tải câu hỏi game:`,e),t.innerHTML=`<div class="col-span-full py-16 text-center text-rose-500 font-bold">Lỗi tải danh sách: ${L(e.message)}</div>`,X(0)}};function $(e){let t=document.getElementById(`grid-game-questions`);if(t){if(t.innerHTML=``,!e||e.length===0){t.innerHTML=`<div class="col-span-full py-20 text-center text-slate-400 font-bold">Chưa có câu hỏi nào trong hệ thống</div>`;return}e.forEach(e=>{let n=Array.isArray(e.waste_dictionary)?e.waste_dictionary[0]||{}:e.waste_dictionary||{},r=Z[Q(e)]||Z[4],i=r.name,a=n.name_vi||e.payload?.name_vi||`Chưa đặt tên`,o=n.image_url||e.payload?.image_url||``,s=n.fun_fact||e.payload?.fun_fact||``,c=e.is_active,l=e.waste_dictionary_id||n.id||``,u=document.createElement(`div`);u.className=`glass-panel rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col hover:border-emerald-500/50 transition-all duration-300 shadow-sm`,u.innerHTML=`
            <!-- Card Image (Clickable to Edit) -->
            <div onclick="window.openEditQuestionModal('${L(e.id)}')"
                class="h-44 bg-slate-100 dark:bg-slate-950 relative group overflow-hidden border-b border-slate-200 dark:border-slate-800 flex items-center justify-center cursor-pointer"
                title="Nhấp để chỉnh sửa câu hỏi này">
                ${o?`
                    <img src="${L(o)}" alt="${L(a)}"
                        class="w-full h-full object-cover transition duration-300 group-hover:scale-105"
                        onerror="this.onerror=null; this.parentElement.innerHTML='<div class=\\'flex flex-col items-center justify-center h-full text-slate-400 p-4 text-center\\'><svg class=\\'w-10 h-10 mb-2 opacity-50\\' fill=\\'none\\' stroke=\\'currentColor\\' viewBox=\\'0 0 24 24\\'><path stroke-linecap=\\'round\\' stroke-linejoin=\\'round\\' stroke-width=\\'1.5\\' d=\\'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z\\'/></svg><span class=\\'text-xs font-semibold\\'>Link ảnh lỗi / Đã gỡ</span></div>';">
                `:`
                    <div class="flex flex-col items-center justify-center h-full text-slate-400 p-4 text-center">
                        <svg class="w-10 h-10 mb-2 opacity-40" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                        </svg>
                        <span class="text-xs font-semibold">Chưa có ảnh (Bấm để thêm)</span>
                    </div>
                `}

                <!-- Waste Group Badge -->
                <div class="absolute top-3 left-3">
                    <span class="px-2.5 py-1 text-[11px] font-black rounded-lg bg-slate-900/80 backdrop-blur-sm ${r.badgeClass} border">
                        ${L(i)}
                    </span>
                </div>

                <!-- Status Badge -->
                <div class="absolute top-3 right-3">
                    ${c?`<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-emerald-500 text-white shadow-sm">Đang bật</span>`:`<span class="px-2.5 py-1 text-[10px] font-black uppercase tracking-wider rounded-lg bg-slate-700 text-slate-200 shadow-sm">Đã tắt</span>`}
                </div>

                <!-- Hover Edit Indicator -->
                <div class="absolute inset-0 bg-slate-900/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center pointer-events-none">
                    <span class="px-3 py-1.5 bg-slate-900/90 text-white rounded-lg text-xs font-bold flex items-center gap-1.5 backdrop-blur-sm shadow-md">
                        <svg class="w-3.5 h-3.5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                        </svg>
                        Bấm để chỉnh sửa
                    </span>
                </div>
            </div>

            <!-- Card Body -->
            <div class="p-4 sm:p-5 flex-1 flex flex-col justify-between">
                <div>
                    <h3 onclick="window.openEditQuestionModal('${L(e.id)}')"
                        class="text-base font-bold text-slate-900 dark:text-white line-clamp-1 font-heading mb-1.5 cursor-pointer hover:text-emerald-600 dark:hover:text-emerald-400 transition"
                        title="Bấm để chỉnh sửa: ${L(a)}">
                        ${L(a)}
                    </h3>
                    <div class="min-h-[48px] bg-slate-50 dark:bg-slate-900/50 p-2.5 rounded-xl border border-slate-100 dark:border-slate-800/60 mb-4">
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-0.5">Kiến thức / Fun Fact:</span>
                        <p class="text-xs text-slate-600 dark:text-slate-300 italic line-clamp-2">
                            ${s?L(s):`<span class="text-slate-400">Không có mẹo kiến thức đi kèm.</span>`}
                        </p>
                    </div>
                </div>

                <!-- Card Actions -->
                <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-2">
                    <!-- Quick Active Toggle -->
                    <button onclick="window.toggleQuestionActive('${L(e.id)}', ${c})"
                        class="px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${c?`bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300`:`bg-emerald-50 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30`}">
                        <span>${c?`⏸ Tạm tắt`:`▶ Kích hoạt`}</span>
                    </button>

                    <div class="flex items-center gap-2">
                        <!-- Prominent Edit Button -->
                        <button onclick="window.openEditQuestionModal('${L(e.id)}')"
                            class="px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-500/10 dark:hover:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-500/30 rounded-lg text-xs font-bold transition flex items-center gap-1.5 shadow-sm"
                            title="Chỉnh sửa câu hỏi này">
                            <svg class="w-3.5 h-3.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                            </svg>
                            <span>Sửa</span>
                        </button>

                        <!-- Delete Button -->
                        <button onclick="window.deleteGameQuestion('${L(e.id)}', '${L(l)}')"
                            class="px-2.5 py-1.5 bg-rose-50 hover:bg-rose-100 dark:bg-rose-500/10 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30 rounded-lg text-xs font-bold transition flex items-center gap-1"
                            title="Xóa câu hỏi khỏi Game">
                            <svg class="w-3.5 h-3.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                            </svg>
                            <span>Xóa</span>
                        </button>
                    </div>
                </div>
            </div>
        `,t.appendChild(u)})}}window.filterQuestionsClient=()=>{let e=(document.getElementById(`filter-q-search`)?.value||``).toLowerCase().trim(),t=document.getElementById(`filter-q-group`)?.value;$(Y.filter(n=>{let r=((Array.isArray(n.waste_dictionary)?n.waste_dictionary[0]||{}:n.waste_dictionary||{}).name_vi||n.payload?.name_vi||``).toLowerCase(),i=Q(n);return(!e||r.includes(e))&&(!t||String(i)===String(t))}))},window.updateQuestionImagePreview=e=>{let t=document.getElementById(`question-preview-box`);if(t){if(!e||!e.trim()){t.innerHTML=`<span class="text-slate-400 text-xs font-medium">Xem trước ảnh sẽ hiển thị ở đây</span>`;return}t.innerHTML=`
        <img src="${L(e.trim())}" alt="Xem trước" class="h-full w-full object-contain p-2"
            onerror="this.onerror=null; this.parentElement.innerHTML='<span class=\\'text-rose-500 text-xs font-semibold\\'>⚠️ URL ảnh không tải được hoặc link không hợp lệ</span>';">
    `}},window.openCreateQuestionModal=()=>{document.getElementById(`question-modal-title`).innerText=`+ Thêm câu hỏi mới vào Game`,document.getElementById(`question-id`).value=``,document.getElementById(`question-dict-id`).value=``,document.getElementById(`question-name`).value=``,document.getElementById(`question-group`).value=``,document.getElementById(`question-image-url`).value=``,document.getElementById(`question-funfact`).value=``,document.getElementById(`question-is-active`).checked=!0;let e=document.getElementById(`btn-save-question`);e&&(e.innerText=`LƯU CÂU HỎI VÀO CSDL`),window.updateQuestionImagePreview(``);let t=document.getElementById(`question-modal`);t.classList.remove(`hidden`),t.classList.add(`flex`)},window.openEditQuestionModal=e=>{let t=Y.find(t=>t.id===e);if(!t)return;let n=Array.isArray(t.waste_dictionary)?t.waste_dictionary[0]||{}:t.waste_dictionary||{};document.getElementById(`question-modal-title`).innerText=`✏️ Chỉnh sửa câu hỏi Game`,document.getElementById(`question-id`).value=t.id,document.getElementById(`question-dict-id`).value=t.waste_dictionary_id||n.id||``,document.getElementById(`question-name`).value=n.name_vi||t.payload?.name_vi||``;let r=Q(t);document.getElementById(`question-group`).value=String(r);let i=n.image_url||t.payload?.image_url||``;document.getElementById(`question-image-url`).value=i,document.getElementById(`question-funfact`).value=n.fun_fact||t.payload?.fun_fact||``,document.getElementById(`question-is-active`).checked=!!t.is_active;let a=document.getElementById(`btn-save-question`);a&&(a.innerText=`CẬP NHẬT & LƯU THAY ĐỔI`),window.updateQuestionImagePreview(i);let o=document.getElementById(`question-modal`);o.classList.remove(`hidden`),o.classList.add(`flex`)},window.closeQuestionModal=()=>{let e=document.getElementById(`question-modal`);e.classList.add(`hidden`),e.classList.remove(`flex`)},window.submitQuestionForm=async()=>{let t=document.getElementById(`btn-save-question`),n=document.getElementById(`question-id`).value,r=document.getElementById(`question-dict-id`).value,i=document.getElementById(`question-name`).value.trim(),a=document.getElementById(`question-group`).value,o=document.getElementById(`question-image-url`).value.trim(),s=document.getElementById(`question-funfact`).value.trim(),c=document.getElementById(`question-is-active`).checked;if(!i||!a||!o)return alert(`Vui lòng nhập tên vật phẩm, chọn nhóm phân loại và dán URL hình ảnh!`);t.disabled=!0;let l=t.innerText;t.innerText=`ĐANG XỬ LÝ...`;try{if(n)await ee({questionId:n,dictId:r,nameVi:i,groupId:a,imageUrl:o,funFact:s,isActive:c}),alert(`Cập nhật câu hỏi thành công!`);else{let t=I(i);t+=`-`+R(4);let{data:{session:n}}=await e.auth.getSession(),r=n?.user?.id;await w({slug:t,nameVi:i,groupId:a,imageUrl:o,funFact:s,isActive:c,userId:r}),alert(`Thêm câu hỏi mới vào Game thành công!`)}window.closeQuestionModal(),window.fetchGameQuestions(q)}catch(e){console.error(e),alert(`Lỗi lưu câu hỏi: `+(e.message||`Không xác định`))}finally{t.disabled=!1,t.innerText=l}},window.toggleQuestionActive=async(e,t)=>{try{await te(e,!t),window.fetchGameQuestions(q)}catch(e){alert(`Lỗi đổi trạng thái: `+(e.message||`Không xác định`))}},window.deleteGameQuestion=async(e,t)=>{if(confirm(`Bạn có chắc muốn xóa câu hỏi này khỏi Game? Thao tác này không thể hoàn tác.`))try{await ne(e,t),alert(`Đã xóa câu hỏi thành công!`),window.fetchGameQuestions(q)}catch(e){alert(`Lỗi xóa câu hỏi: `+(e.message||`Không xác định`))}},(async function(){try{let{data:{session:t}}=await e.auth.getSession();if(!t)return window.location.replace(`index.html`);let r=await n(t.user),i=document.getElementById(`admin-email`);i&&(i.innerText=r.email),A=r.role||`admin`,document.getElementById(`auth-loader`).classList.add(`hidden`),window.fetchWasteGroups(),window.fetchSubmissions()}catch(e){alert(`Phiên đăng nhập hết hạn hoặc lỗi: `+e.message),window.location.replace(`index.html`)}})();