window.CK_API_BASE_URL = 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/api';

window.ckApiFetch = (path, options = {}) => fetch(`${window.CK_API_BASE_URL}${path}`, {
  ...options,
  credentials: 'include'
});
