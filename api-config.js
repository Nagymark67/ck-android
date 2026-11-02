window.CK_API_BASE_URL = 'https://ljxoykuwidoirscbdfaf.supabase.co/functions/v1/api';

window.ckApiFetch = (path, options = {}) => fetch(`${window.CK_API_BASE_URL}${path}`, {
  ...options,
  credentials: 'include'
});

const INACTIVITY_TIMEOUT_MS = 2 * 60 * 1000;
let inactivityTimer = null;
let inactivityLogoutInProgress = false;

const redirectToLoginAfterInactivity = () => {
  const loginUrl = new URL('login.html', document.baseURI);
  loginUrl.searchParams.set('reason', 'inactivity');
  window.location.replace(loginUrl.href);
};

const logoutAfterInactivity = async () => {
  if (inactivityLogoutInProgress) return;
  inactivityLogoutInProgress = true;
  try {
    await window.ckApiFetch('/logout', { method: 'POST', keepalive: true });
  } catch (error) {
    console.warn('Automatic logout request failed', error);
  } finally {
    redirectToLoginAfterInactivity();
  }
};

const resetInactivityTimer = () => {
  if (inactivityLogoutInProgress) return;
  window.clearTimeout(inactivityTimer);
  inactivityTimer = window.setTimeout(logoutAfterInactivity, INACTIVITY_TIMEOUT_MS);
};

const startInactivityTimer = () => {
  ['pointerdown', 'keydown', 'scroll', 'touchstart'].forEach((eventName) => {
    window.addEventListener(eventName, resetInactivityTimer, { passive: true });
  });
  resetInactivityTimer();
};

window.ckApiFetch('/me')
  .then((response) => {
    if (response.ok) startInactivityTimer();
  })
  .catch((error) => console.warn('Could not check session for inactivity timer', error));
