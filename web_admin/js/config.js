// web_admin/js/config.js — KHÔNG commit key thật lên Git. Nên copy thành config.local.js (đã ignore) hoặc biến môi trường build.
export const config = {
    // URL của bạn
    u: 'https://nabkjjxkaudsyudhnkdp.supabase.co',
    // Anon Key của bạn (Dán mã eyJ... vào đây)
    k: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hYmtqanhrYXVkc3l1ZGhua2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMjI2NTUsImV4cCI6MjA5MDY5ODY1NX0.6JYYGAsas6DJDDCT3cinkSNX24MpqnHOmQCuwsf7yUc'
};

export const getSupabaseConfig = () => ({
    url: config.u,
    key: config.k
});