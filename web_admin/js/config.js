// Obfuscated configuration using Base64
export const config = {
    // URL: https://gbao86.supabase.co
    u: 'aHR0cHM6Ly9nYmFvODYuc3VwYWJhc2UuY28=',
    // Key anon eyJ...
    k: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdiYW84NiIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzc1MTIyNjU1LCJleHAiOjIwOTA2OTg2NTV9.6JYYGAsas6DJDDCT3cinkSNX24MpqnHOmQCuwsf7yUc'
};

export const getSupabaseConfig = () => ({
    url: atob(config.u),
    key: config.k
});
