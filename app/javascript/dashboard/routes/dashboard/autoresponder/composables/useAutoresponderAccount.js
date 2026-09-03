import { computed, ref } from 'vue';
import CommentAutomationSocialAccountsAPI from 'dashboard/api/commentAutomationSocialAccounts';

const FALLBACK_ACCOUNT = {
  id: '',
  name: '',
  handle: '—',
  platform: 'Instagram',
  followersCount: '',
};

const accounts = ref([]);
const teamMembers = ref([]);
const teams = ref([]);
const activeAccountId = ref('');
const loaded = ref(false);
let loadPromise = null;

export function platformIconClass(platform) {
  if (platform === 'Instagram') return 'i-lucide-instagram';
  if (platform === 'Facebook') return 'i-lucide-facebook';
  return 'i-lucide-globe';
}

async function fetchAccounts() {
  const response = await CommentAutomationSocialAccountsAPI.get();
  accounts.value = response.data.payload || [];
  teamMembers.value = response.data.meta?.teamMembers || [];
  teams.value = response.data.meta?.teams || [];
  if (
    !accounts.value.some(
      account => String(account.id) === String(activeAccountId.value)
    )
  ) {
    activeAccountId.value = accounts.value[0]?.id
      ? String(accounts.value[0].id)
      : '';
  }
}

export function useAutoresponderAccount() {
  function refreshAccounts() {
    if (loadPromise) return loadPromise;
    loadPromise = fetchAccounts()
      .catch(() => {
        accounts.value = [];
      })
      .finally(() => {
        loaded.value = true;
        loadPromise = null;
      });
    return loadPromise;
  }

  if (!loaded.value) refreshAccounts();

  const activeAccount = computed(
    () =>
      accounts.value.find(
        account => String(account.id) === String(activeAccountId.value)
      ) ||
      accounts.value[0] ||
      FALLBACK_ACCOUNT
  );

  function selectAccount(id) {
    activeAccountId.value = String(id);
  }

  function matchesActiveInbox(inboxOrId) {
    const activeId = activeAccount.value?.id;
    if (!activeId) return true;
    const inboxId =
      inboxOrId && typeof inboxOrId === 'object' ? inboxOrId.id : inboxOrId;
    return String(inboxId) === String(activeId);
  }

  async function updateAccount(updated) {
    const idx = accounts.value.findIndex(account => account.id === updated.id);
    if (idx !== -1) accounts.value[idx] = { ...updated };
    await CommentAutomationSocialAccountsAPI.update(updated.id, updated);
  }

  async function connectAccount(platform) {
    const response = await CommentAutomationSocialAccountsAPI.create({
      platform,
    });
    const next = response.data;
    const idx = accounts.value.findIndex(account => account.id === next.id);
    if (idx === -1) accounts.value = [...accounts.value, next];
    else accounts.value[idx] = next;
    activeAccountId.value = next.id;
    return next;
  }

  async function syncAccounts() {
    await CommentAutomationSocialAccountsAPI.sync();
    await fetchAccounts();
  }

  return {
    accounts,
    teamMembers,
    teams,
    activeAccountId,
    activeAccount,
    loaded,
    selectAccount,
    matchesActiveInbox,
    refreshAccounts,
    updateAccount,
    connectAccount,
    syncAccounts,
  };
}
