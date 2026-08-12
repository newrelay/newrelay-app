<script setup>
/* eslint-disable */
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import html2canvas from 'html2canvas';
const axios = window.axios;

const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id || 
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const currentTab = ref('integrations');
const searchQuery = ref('');
const integrations = ref([]);
const templates = ref([]);
const activeTemplate = ref(null);
const loading = ref(true);

const route = useRoute();
const router = useRouter();
const saving = ref(false);
const disconnectLoading = ref(null);

// Modal states
const showConnectModal = ref(false);
const selectedPlatform = ref(null);
const listingUrl = ref('');
const listingName = ref('');

// Google Business modal
const showLocationModal = ref(false);
const googleLocations = ref([]);
const selectedLocation = ref(null);
const loadingLocations = ref(false);
const connectingLocation = ref(false);
const locationError = ref('');
const currentOauthSessionId = ref('');

// Custom platform modal
const showCustomModal = ref(false);
const customPlatformName = ref('');
const customPlatformUrl = ref('');
const customPlatformLogo = ref('link');

// 3-dots dropdown menu state
const activeMenuId = ref(null);

// Local storage simulated states
const aiEnabled = ref(localStorage.getItem('rep_ai_enabled') === 'true');
const aiMinRating = ref(localStorage.getItem('rep_ai_min_rating') || '4');
const aiInstructions = ref(localStorage.getItem('rep_ai_instructions') || 'Thank customers for their feedback, address any concerns politely, and offer support contact.');
const customSlug = ref(localStorage.getItem('rep_custom_slug') || 'my-business');
const qrTitle = ref(localStorage.getItem('rep_qr_title') || 'Scan to Review');
watch(qrTitle, (val) => localStorage.setItem('rep_qr_title', val));

const qrUrl = computed(() => {
  if (customSlug.value.startsWith('http')) return customSlug.value;
  return `${window.location.origin}/r/${customSlug.value}`;
});
const qrImgSrc = computed(() => `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(qrUrl.value)}`);

const spamMinRating = ref(localStorage.getItem('rep_spam_min_rating') || '3');

const baseApi = () => `/api/v1/accounts/${accountId}/reputation`;

const sidebarItems = [
  { id: 'integrations', label: 'Integrations' },
  { id: 'reviews_ai', label: 'Reviews AI' },
  { id: 'review_link', label: 'Review Link' },
  { id: 'sms_requests', label: 'SMS Requests' },
  { id: 'email_requests', label: 'Email Requests' },
  { id: 'whatsapp_requests', label: 'WhatsApp Requests' },
  { id: 'reviews_qr', label: 'Reviews QR' },
  { id: 'spam_reviews', label: 'Spam Reviews' }
];

const platforms = [
  { id: 'google', name: 'Google Business', logoColor: 'text-red-500 bg-red-50 dark:bg-red-950/20' },
  { id: 'facebook', name: 'Facebook Page', logoColor: 'text-blue-600 bg-blue-50 dark:bg-blue-950/20', comingSoon: true },
  { id: 'agoda', name: 'Agoda', logoColor: 'text-sky-500 bg-sky-50 dark:bg-sky-950/20', comingSoon: true },
  { id: 'airbnb', name: 'Airbnb', logoColor: 'text-rose-500 bg-rose-50 dark:bg-rose-950/20', comingSoon: true },
  { id: 'aliexpress', name: 'AliExpress', logoColor: 'text-orange-500 bg-orange-50 dark:bg-orange-950/20', comingSoon: true },
  { id: 'amazon', name: 'Amazon', logoColor: 'text-amber-600 bg-amber-50 dark:bg-amber-950/20', comingSoon: true },
  { id: 'angi', name: 'Angi', logoColor: 'text-emerald-600 bg-emerald-50 dark:bg-emerald-950/20', comingSoon: true },
  { id: 'apple_app_store', name: 'Apple App Store', logoColor: 'text-slate-700 bg-slate-100 dark:bg-slate-800/40', comingSoon: true },
  { id: 'avvo', name: 'Avvo', logoColor: 'text-indigo-600 bg-indigo-50 dark:bg-indigo-950/20', comingSoon: true }
];

const filteredPlatforms = computed(() => {
  return platforms.filter(p => p.name.toLowerCase().includes(searchQuery.value.toLowerCase()));
});

async function loadData() {
  loading.value = true;
  try {
    const [intRes, tempRes] = await Promise.all([
      axios.get(`${baseApi()}/integrations`).catch(() => ({ data: [] })),
      axios.get(`${baseApi()}/templates`).catch(() => ({ data: [] }))
    ]);
    integrations.value = intRes.data;
    templates.value = tempRes.data;
    if (tempRes.data.length > 0) {
      activeTemplate.value = { ...tempRes.data[0] };
    }
  } catch (err) {
    console.error('Failed to load settings data', err);
  } finally {
    loading.value = false;
  }
}

const connectFacebook = () => {
  const appId = window.chatwootConfig?.reputationFacebookAppId;
  if (!appId) {
    alert('Facebook App ID is not configured in the environment.');
    return;
  }
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=facebook`;
  window.location.href =
    `https://www.facebook.com/v18.0/dialog/oauth?client_id=${appId}&redirect_uri=${redirect}&scope=pages_show_list,pages_read_engagement&state=${accountId}`;
};

const connectGoogle = () => {
  const clientId = window.chatwootConfig?.reputationGoogleClientId;
  if (!clientId) {
    alert('Google Client ID is not configured in the environment. Please add REPUTATION_GOOGLE_CLIENT_ID to your .env file and restart the server.');
    return;
  }
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=google`;
  window.location.href =
    `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${redirect}&scope=https://www.googleapis.com/auth/business.manage&response_type=code&access_type=offline&prompt=consent&state=${accountId}`;
};

function openConnectModal(platform) {
  if (platform.id === 'google') {
    connectGoogle();
    return;
  }
  if (platform.id === 'facebook') {
    connectFacebook();
    return;
  }
  selectedPlatform.value = platform;
  listingUrl.value = '';
  listingName.value = '';
  showConnectModal.value = true;
}

async function checkGoogleOauthCallback() {
  const params = new URLSearchParams(window.location.search);
  const oauthStatus = params.get('google_oauth');

  if (oauthStatus === 'error') {
    const errorMsg = params.get('message') || 'Unknown OAuth error occurred';
    alert(`Google Authentication Failed: ${errorMsg}`);
    
    const cleanUrl = window.location.pathname;
    window.history.replaceState({}, document.title, cleanUrl);
    return;
  }

  if (oauthStatus === 'success') {
    currentOauthSessionId.value = params.get('oauth_session_id');

    const cleanUrl = window.location.pathname;
    window.history.replaceState({}, document.title, cleanUrl);

    showLocationModal.value = true;
    loadingLocations.value = true;
    locationError.value = '';
    try {
      const { data } = await axios.get(`${baseApi()}/integrations/google_locations?oauth_session_id=${currentOauthSessionId.value}`);
      googleLocations.value = data;
      if (data.length > 0) {
        selectedLocation.value = data[0];
      }
    } catch (err) {
      locationError.value = err?.response?.data?.errors?.[0] || 'Failed to fetch Google locations. Please authenticate again.';
    } finally {
      loadingLocations.value = false;
    }
  }
}

async function submitGoogleLocationConnection() {
  if (!selectedLocation.value) {
    locationError.value = 'Please select a Google Business Profile location to connect.';
    return;
  }
  connectingLocation.value = true;
  locationError.value = '';
  try {
    const { data } = await axios.post(`${baseApi()}/integrations`, {
      integration: {
        provider: 'google',
        location_id: selectedLocation.value.location_id,
        location_name: selectedLocation.value.location_name,
        oauth_session_id: currentOauthSessionId.value
      }
    });
    integrations.value.unshift(data);
    showLocationModal.value = false;
  } catch (err) {
    locationError.value = err?.response?.data?.errors?.[0] || 'Failed to connect Google Business location.';
  } finally {
    connectingLocation.value = false;
  }
}

async function submitConnection() {
  if (!listingUrl.value || !listingName.value) {
    alert('Please enter listing URL and name');
    return;
  }
  saving.value = true;
  try {
    const { data } = await axios.post(`${baseApi()}/integrations`, {
      integration: {
        provider: selectedPlatform.value.id,
        location_id: listingUrl.value,
        location_name: listingName.value
      }
    });
    integrations.value.unshift(data);
    showConnectModal.value = false;
  } catch (err) {
    alert('Failed to connect integration. Listing might already be connected.');
  } finally {
    saving.value = false;
  }
}

async function submitCustomConnection() {
  if (!customPlatformName.value || !customPlatformUrl.value) {
    alert('Please enter platform name and URL');
    return;
  }
  saving.value = true;
  try {
    const { data } = await axios.post(`${baseApi()}/integrations`, {
      integration: {
        provider: 'custom',
        location_id: customPlatformUrl.value,
        location_name: `${customPlatformName.value} - ${customPlatformLogo.value}`
      }
    });
    integrations.value.unshift(data);
    showCustomModal.value = false;
  } catch (err) {
    alert('Failed to add custom link');
  } finally {
    saving.value = false;
  }
}

async function disconnect(id) {
  if (!confirm('Are you sure you want to disconnect this platform?')) return;
  disconnectLoading.value = id;
  activeMenuId.value = null;
  try {
    await axios.delete(`${baseApi()}/integrations/${id}`);
    integrations.value = integrations.value.filter(i => i.id !== id);
  } catch (err) {
    alert('Failed to disconnect integration');
  } finally {
    disconnectLoading.value = null;
  }
}

const downloadingCard = ref(false);
async function downloadFullCard() {
  const card = document.getElementById('qr-print-card');
  if (!card) return;
  
  downloadingCard.value = true;
  try {
    const canvas = await html2canvas(card, {
      scale: 3, 
      useCORS: true,
      backgroundColor: '#ffffff'
    });
    const link = document.createElement('a');
    link.download = 'Reputation_Poster.png';
    link.href = canvas.toDataURL('image/png');
    link.click();
  } catch (err) {
    console.error('Failed to generate image', err);
    alert('Could not download image. Please use the Print Poster option instead.');
  } finally {
    downloadingCard.value = false;
  }
}

function getIntegrationForPlatform(platformId) {
  return integrations.value.filter(i => i.provider === platformId);
}

// Local storage simulated saves
function saveAiSettings() {
  localStorage.setItem('rep_ai_enabled', aiEnabled.value.toString());
  localStorage.setItem('rep_ai_min_rating', aiMinRating.value);
  localStorage.setItem('rep_ai_instructions', aiInstructions.value);
  alert('AI Settings saved successfully!');
}

function saveLinkSettings() {
  localStorage.setItem('rep_custom_slug', customSlug.value);
  alert('Review link settings saved successfully!');
}

function saveSpamSettings() {
  localStorage.setItem('rep_spam_min_rating', spamMinRating.value);
  localStorage.setItem('rep_spam_keywords', spamKeywords.value);
  alert('Spam filter settings saved successfully!');
}

// Templates CRUD
const activeTabTemplates = computed(() => {
  const channelMap = {
    sms_requests: 'sms',
    email_requests: 'email',
    whatsapp_requests: 'whatsapp'
  };
  const targetChannel = channelMap[currentTab.value];
  return templates.value.filter(t => t.channel === targetChannel);
});

function newTemplate() {
  const channelMap = {
    sms_requests: 'sms',
    email_requests: 'email',
    whatsapp_requests: 'whatsapp'
  };
  activeTemplate.value = {
    name: 'New Invite Template',
    channel: channelMap[currentTab.value] || 'email',
    subject: 'Share your feedback with us!',
    body: 'Hi {{contact.name}},\n\nThank you for choosing us! We would love to hear your feedback. Please share your review here:\n{{review_link}}',
    active: true,
    template_type: 'standard',
    isNew: true
  };
}

async function saveTemplate() {
  if (!activeTemplate.value) return;
  saving.value = true;
  try {
    if (activeTemplate.value.isNew) {
      const { data } = await axios.post(`${baseApi()}/templates`, {
        template: {
          name: activeTemplate.value.name,
          channel: activeTemplate.value.channel,
          template_type: activeTemplate.value.template_type,
          subject: activeTemplate.value.subject,
          body: activeTemplate.value.body,
          active: activeTemplate.value.active
        }
      });
      templates.value.unshift(data);
      activeTemplate.value = { ...data };
    } else {
      const { data } = await axios.patch(`${baseApi()}/templates/${activeTemplate.value.id}`, {
        template: {
          name: activeTemplate.value.name,
          channel: activeTemplate.value.channel,
          template_type: activeTemplate.value.template_type,
          subject: activeTemplate.value.subject,
          body: activeTemplate.value.body,
          active: activeTemplate.value.active
        }
      });
      const idx = templates.value.findIndex(t => t.id === activeTemplate.value.id);
      if (idx !== -1) {
        templates.value[idx] = data;
      }
    }
    alert('Template saved successfully!');
  } catch (err) {
    alert('Failed to save template');
  } finally {
    saving.value = false;
  }
}

async function deleteTemplate(id) {
  if (!confirm('Are you sure you want to delete this template?')) return;
  try {
    await axios.delete(`${baseApi()}/templates/${id}`);
    templates.value = templates.value.filter(t => t.id !== id);
    if (activeTabTemplates.value.length > 0) {
      activeTemplate.value = { ...activeTabTemplates.value[0] };
    } else {
      activeTemplate.value = null;
    }
  } catch (err) {
    alert('Failed to delete template');
  }
}

function selectTemplate(t) {
  activeTemplate.value = { ...t };
}

function insertPlaceholder(tag) {
  if (!activeTemplate.value) return;
  activeTemplate.value.body = (activeTemplate.value.body || '') + tag;
}

function handleTabChange(tabId) {
  currentTab.value = tabId;
  const channelMap = {
    sms_requests: 'sms',
    email_requests: 'email',
    whatsapp_requests: 'whatsapp'
  };
  const targetChannel = channelMap[tabId];
  if (targetChannel) {
    const channelTemplates = templates.value.filter(t => t.channel === targetChannel);
    activeTemplate.value = channelTemplates.length > 0 ? { ...channelTemplates[0] } : null;
  }
}

onMounted(async () => {
  await loadData();
  checkGoogleOauthCallback();
});
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-8">
    <!-- eslint-disable -->
    <!-- Header -->
    <div>
      <h2 class="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Reputation Settings</h2>
      <p class="text-xs text-slate-400 mt-0.5">Manage connected listings, review triggers, and outbound channel request templates</p>
    </div>

    <div v-if="loading" class="flex flex-col items-center justify-center py-20 space-y-4">
      <div class="size-10 border-4 border-woot-500 border-t-transparent rounded-full animate-spin"></div>
      <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Loading settings panel...</p>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
      <!-- Left sidebar navigation -->
      <aside class="lg:col-span-3 bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 rounded-2xl p-4 shadow-sm space-y-1">
        <button
          v-for="item in sidebarItems"
          :key="item.id"
          class="w-full text-left px-4 py-2.5 rounded-xl transition-all duration-200 text-xs font-bold flex items-center justify-between"
          :class="currentTab === item.id
            ? 'bg-woot-500 text-white shadow-md shadow-woot-500/10'
            : 'hover:bg-slate-50 dark:hover:bg-slate-850 text-slate-700 dark:text-slate-350'"
          @click="handleTabChange(item.id)"
        >
          {{ item.label }}
          <span 
            v-if="item.id === 'integrations' && integrations.length > 0"
            class="px-2 py-0.5 text-[10px] rounded-full"
            :class="currentTab === 'integrations' ? 'bg-white/20 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-650 dark:text-slate-300'"
          >
            {{ integrations.length }}
          </span>
        </button>
      </aside>

      <!-- Right settings workspace -->
      <main class="lg:col-span-9">
        <!-- 1. Integrations View -->
        <div v-if="currentTab === 'integrations'" class="space-y-6">
          <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-6">
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <h3 class="font-extrabold text-slate-900 dark:text-white text-base">Integrations</h3>
                <p class="text-xs text-slate-400 mt-0.5">Add review platforms by entering the page link to import reviews.</p>
              </div>
              <div class="relative w-full md:w-72">
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Search platforms..."
                  class="w-full pl-9 pr-4 py-2 text-xs rounded-xl border border-slate-200 dark:border-slate-800 dark:bg-slate-850 focus:outline-none focus:ring-2 focus:ring-woot-500"
                />
                <span class="absolute left-3 top-2.5 text-slate-400">
                  <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                </span>
              </div>
            </div>

            <!-- Integrations Grid -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <!-- Custom Link Card -->
              <div class="p-5 rounded-2xl bg-slate-50/50 dark:bg-slate-850/50 border-2 border-dashed border-slate-200 dark:border-slate-800 flex flex-col items-center justify-center text-center space-y-4">
                <div class="p-3 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-500 shadow-inner">
                  <svg class="size-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
                </div>
                <div>
                  <h4 class="font-extrabold text-sm text-slate-850 dark:text-white">Custom Links</h4>
                  <p class="text-[10px] text-slate-400 mt-0.5">Connect any standard feedback url</p>
                </div>
                <button
                  class="px-4 py-1.5 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-250 border border-slate-200 dark:border-slate-700 rounded-xl text-xs font-bold shadow-sm hover:bg-slate-50 dark:hover:bg-slate-750 transition-all"
                  @click="showCustomModal = true"
                >
                  + Add page
                </button>
              </div>

              <!-- Platforms Connection Cards -->
              <div
                v-for="platform in filteredPlatforms"
                :key="platform.id"
                class="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm relative flex flex-col justify-between min-h-[190px]"
              >
                <!-- Card Header -->
                <div class="flex items-start justify-between gap-4">
                  <div class="flex items-center gap-3">
                    <div class="p-2.5 rounded-xl shrink-0 font-extrabold uppercase text-xs tracking-wider" :class="platform.logoColor">
                      {{ platform.name.substring(0, 2) }}
                    </div>
                    <div>
                      <h4 class="font-extrabold text-sm text-slate-850 dark:text-white">{{ platform.name }}</h4>
                      <span
                        class="text-[9px] uppercase tracking-wider font-extrabold"
                        :class="getIntegrationForPlatform(platform.id).length > 0 ? 'text-emerald-500' : 'text-slate-400'"
                      >
                        {{ getIntegrationForPlatform(platform.id).length > 0 ? 'Connected' : 'Not connected' }}
                      </span>
                    </div>
                  </div>

                  <!-- 3-dots Menu for active connections -->
                  <div v-if="getIntegrationForPlatform(platform.id).length > 0" class="relative">
                    <button 
                      class="p-1 rounded hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-400"
                      @click="activeMenuId = activeMenuId === platform.id ? null : platform.id"
                    >
                      <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" /></svg>
                    </button>
                    <!-- Dropdown context -->
                    <div v-if="activeMenuId === platform.id" class="absolute right-0 mt-1 w-36 bg-white dark:bg-slate-850 border border-slate-100 dark:border-slate-800 rounded-xl shadow-lg py-1.5 z-20">
                      <button
                        v-for="int in getIntegrationForPlatform(platform.id)"
                        :key="int.id"
                        class="w-full text-left px-3.5 py-1.5 text-xs text-red-500 hover:bg-slate-50 dark:hover:bg-slate-800 font-bold transition-colors"
                        @click="disconnect(int.id)"
                      >
                        Disconnect
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Card Body -->
                <div class="mt-4 flex-1">
                  <div v-if="getIntegrationForPlatform(platform.id).length > 0" class="space-y-1">
                    <p class="text-xs font-semibold text-slate-800 dark:text-slate-200 truncate">
                      {{ getIntegrationForPlatform(platform.id)[0].location_name }}
                    </p>
                    <p class="text-[10px] text-slate-450">
                      {{ getIntegrationForPlatform(platform.id).length }} Connected account
                    </p>
                  </div>
                  <div v-else class="text-[10px] text-slate-400">
                    No business page connected yet.
                  </div>
                </div>

                <!-- Card Action footer -->
                <div class="mt-4 border-t border-slate-100 dark:border-slate-850/50 pt-3">
                  <div v-if="getIntegrationForPlatform(platform.id).length > 0" class="text-xs text-emerald-500 font-bold flex items-center gap-1">
                    <span class="size-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                    Syncing Reviews
                  </div>
                  <button
                    v-else-if="platform.comingSoon"
                    disabled
                    class="w-full py-2 bg-slate-50 dark:bg-slate-850 text-slate-400 dark:text-slate-500 rounded-xl text-xs font-bold border border-slate-100 dark:border-slate-800 shadow-sm cursor-not-allowed"
                  >
                    Coming Soon
                  </button>
                  <button
                    v-else
                    class="w-full py-2 bg-slate-50 dark:bg-slate-850 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-250 rounded-xl text-xs font-bold border border-slate-150 dark:border-slate-800 shadow-sm transition-all"
                    @click="openConnectModal(platform)"
                  >
                    Connect account
                  </button>
                </div>
              </div>

              <!-- Rendered Custom Links connected -->
              <div
                v-for="customInt in getIntegrationForPlatform('custom')"
                :key="customInt.id"
                class="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm relative flex flex-col justify-between min-h-[190px]"
              >
                <div class="flex items-start justify-between gap-4">
                  <div class="flex items-center gap-3 min-w-0">
                    <div class="p-2.5 rounded-xl shrink-0 font-extrabold text-xs text-indigo-500 bg-indigo-50 dark:bg-indigo-950/20">
                      LK
                    </div>
                    <div class="min-w-0">
                      <h4 class="font-extrabold text-sm text-slate-850 dark:text-white truncate">
                        {{ customInt.location_name.split(' - ')[0] }}
                      </h4>
                      <span class="text-[9px] uppercase tracking-wider font-extrabold text-emerald-500">Connected</span>
                    </div>
                  </div>
                  <button 
                    class="p-1 rounded hover:bg-slate-50 dark:hover:bg-slate-800 text-red-500"
                    @click="disconnect(customInt.id)"
                  >
                    <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                  </button>
                </div>

                <div class="mt-4 flex-1 min-w-0">
                  <p class="text-xs font-semibold text-slate-800 dark:text-slate-200 truncate">
                    {{ customInt.location_id }}
                  </p>
                  <p class="text-[10px] text-slate-450 mt-1 capitalize">
                    Custom Channel ({{ customInt.location_name.split(' - ')[1] || 'link' }})
                  </p>
                </div>

                <div class="mt-4 border-t border-slate-100 dark:border-slate-850/50 pt-3">
                  <span class="text-[10px] font-bold text-slate-400">Custom connection</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 2. Reviews AI View -->
        <div v-else-if="currentTab === 'reviews_ai'" class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-6">
          <div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-base">Reviews AI</h3>
            <p class="text-xs text-slate-400 mt-0.5">Automate and customize review replies with AI assistance</p>
          </div>

          <div class="space-y-4">
            <div class="flex items-center justify-between p-4 rounded-xl border border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-850/30">
              <div>
                <h4 class="text-sm font-bold text-slate-800 dark:text-white">Enable Auto-Reply with AI</h4>
                <p class="text-xs text-slate-400 mt-0.5">Instantly draft and publish responses based on customer reviews</p>
              </div>
              <button
                type="button"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full p-0.5 transition-colors duration-200 ease-in-out focus:outline-none"
                :class="
                  aiEnabled
                    ? 'bg-woot-500'
                    : 'bg-slate-300 dark:bg-slate-700'
                "
                @click="aiEnabled = !aiEnabled"
              >
                <span
                  class="pointer-events-none inline-block size-5 transform rounded-full bg-white shadow transition-transform duration-200 ease-in-out"
                  :class="
                    aiEnabled ? 'translate-x-5' : 'translate-x-0'
                  "
                />
              </button>
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Minimum Rating to Auto-Reply</label>
              <select
                v-model="aiMinRating"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
              >
                <option value="5">5 Stars only</option>
                <option value="4">4 Stars & above</option>
                <option value="3">3 Stars & above</option>
              </select>
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Custom AI Instructions</label>
              <textarea
                v-model="aiInstructions"
                rows="4"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
                placeholder="Instruct the AI on tone, context, or key business details..."
              />
            </div>

            <div class="pt-4 border-t border-slate-100 dark:border-slate-850 flex justify-end">
              <button
                class="px-5 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm"
                @click="saveAiSettings"
              >
                Save AI Config
              </button>
            </div>
          </div>
        </div>

        <!-- 3. Review Link View -->
        <div v-else-if="currentTab === 'review_link'" class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-6">
          <div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-base">Review Short Link</h3>
            <p class="text-xs text-slate-400 mt-0.5">Customize the shortlink sent out to invite reviews</p>
          </div>

          <div class="space-y-4">
            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Review Invite URL</label>
              <input
                v-model="customSlug"
                type="text"
                placeholder="https://g.page/r/your-business/review"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
              />
              <p class="text-[10px] text-slate-400 font-semibold mt-1">
                Enter your own external URL (e.g. Google or Facebook review link) or a custom slug. This link is used for your QR code.
              </p>
            </div>

            <div class="pt-4 border-t border-slate-100 dark:border-slate-850 flex justify-end">
              <button
                class="px-5 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm"
                @click="saveLinkSettings"
              >
                Save Link Slug
              </button>
            </div>
          </div>
        </div>

        <!-- 4. Outbound Invite Templates (SMS, Email, WhatsApp Tabs) -->
        <div 
          v-else-if="['sms_requests', 'email_requests', 'whatsapp_requests'].includes(currentTab)"
          class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-5"
        >
          <div class="flex items-center justify-between">
            <div>
              <h3 class="font-extrabold text-slate-900 dark:text-white text-base">
                {{ currentTab === 'sms_requests' ? 'SMS' : currentTab === 'email_requests' ? 'Email' : 'WhatsApp' }} Invite Templates
              </h3>
              <p class="text-xs text-slate-400 mt-0.5">Customize outbound customer requests templates</p>
            </div>
            <button
              class="px-3.5 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-all shadow-sm"
              @click="newTemplate"
            >
              + Create Template
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-12 gap-6">
            <!-- Templates List -->
            <div class="md:col-span-4 border-r border-slate-100 dark:border-slate-850 pr-4 space-y-1 max-h-[380px] overflow-y-auto">
              <button
                v-for="t in activeTabTemplates"
                :key="t.id"
                class="w-full text-left px-3.5 py-2.5 rounded-xl transition-all flex items-center justify-between text-xs font-bold"
                :class="activeTemplate?.id === t.id
                  ? 'bg-woot-50 dark:bg-woot-950/20 text-woot-650 dark:text-woot-400'
                  : 'hover:bg-slate-50 dark:hover:bg-slate-850 text-slate-700 dark:text-slate-350'"
                @click="selectTemplate(t)"
              >
                <div class="truncate">
                  <span>{{ t.name }}</span>
                </div>
                <span v-if="!t.active" class="text-[8px] bg-slate-100 dark:bg-slate-800 px-1 py-0.5 text-slate-450 rounded uppercase">Inactive</span>
              </button>
              
              <div v-if="activeTabTemplates.length === 0" class="text-xs text-slate-450 py-10 text-center">
                No templates configured for this channel.
              </div>
            </div>

            <!-- Template Editor -->
            <div v-if="activeTemplate" class="md:col-span-8 space-y-4">
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1">
                  <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Template Name</label>
                  <input
                    v-model="activeTemplate.name"
                    type="text"
                    class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
                  />
                </div>
                <div class="space-y-1">
                  <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Channel</label>
                  <input
                    disabled
                    :value="activeTemplate.channel"
                    class="w-full text-xs rounded-xl border border-slate-150 dark:border-slate-800 dark:bg-slate-850 p-2.5 text-slate-400 capitalize cursor-not-allowed"
                  />
                </div>
              </div>

              <!-- Template Category -->
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Template Category</label>
                <select
                  v-model="activeTemplate.template_type"
                  class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
                >
                  <option value="standard">Standard Review Request</option>
                  <option value="video">Video Testimonial Request</option>
                </select>
              </div>

              <!-- Subject (Only if email) -->
              <div v-if="activeTemplate.channel === 'email'" class="space-y-1">
                <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Email Subject</label>
                <input
                  v-model="activeTemplate.subject"
                  type="text"
                  class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
                />
              </div>

              <!-- Body -->
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Message Content</label>
                <textarea
                  v-model="activeTemplate.body"
                  rows="4"
                  class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
                />
              </div>

              <!-- Tag Placeholders -->
              <div class="flex items-center gap-2 flex-wrap">
                <span class="text-[10px] text-slate-400">Insert tag:</span>
                <button
                  class="px-2 py-1 text-[9px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-650 dark:text-slate-300 rounded hover:bg-slate-200 transition-colors"
                  @click="insertPlaceholder('{{contact.name}}')"
                >
                  Contact Name
                </button>
                <button
                  class="px-2 py-1 text-[9px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-650 dark:text-slate-300 rounded hover:bg-slate-200 transition-colors"
                  @click="insertPlaceholder('{{review_link}}')"
                >
                  Review URL
                </button>
              </div>

              <!-- Actions footer -->
              <div class="flex items-center justify-between pt-4 border-t border-slate-100 dark:border-slate-850">
                <div class="flex items-center gap-2">
                  <input
                    id="t-active"
                    v-model="activeTemplate.active"
                    type="checkbox"
                    class="rounded bg-slate-200 dark:bg-slate-700 border-transparent text-woot-500 focus:ring-woot-500 size-4"
                  />
                  <label for="t-active" class="text-xs text-slate-600 dark:text-slate-300 font-medium">Template Active</label>
                </div>

                <div class="flex gap-2">
                  <button
                    v-if="!activeTemplate.isNew"
                    class="px-3.5 py-1.5 rounded-xl border border-slate-200 dark:border-slate-800 text-xs font-bold text-red-500 transition-colors"
                    @click="deleteTemplate(activeTemplate.id)"
                  >
                    Delete
                  </button>
                  <button
                    class="px-4 py-1.5 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm"
                    :disabled="saving"
                    @click="saveTemplate"
                  >
                    {{ saving ? 'Saving...' : 'Save Template' }}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 5. Reviews QR View -->
        <div v-else-if="currentTab === 'reviews_qr'" class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-6">
          <div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-base">Reviews QR Code</h3>
            <p class="text-xs text-slate-400 mt-0.5">Generate QR code for tables, counters, or physical print review invites</p>
          </div>

          <div>
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Custom Title for QR Code</label>
            <input
              v-model="qrTitle"
              type="text"
              class="w-full mt-1 text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
              placeholder="e.g. Scan to Review"
            />
          </div>

          <div class="flex flex-col items-center justify-center p-8 space-y-6 text-center w-full">
            <!-- High-fidelity QR Code Poster -->
            <div 
              id="qr-print-card" 
              class="relative bg-white rounded-3xl shadow-xl border border-slate-100 overflow-hidden w-full max-w-[340px]"
            >
              <div class="absolute top-0 left-0 w-full h-28 bg-gradient-to-br from-woot-500 to-indigo-600"></div>
              
              <div class="relative z-10 flex flex-col items-center pt-10 px-6 pb-6">
                <div class="size-[72px] bg-white rounded-full p-2 shadow-md border border-slate-50 flex items-center justify-center mb-4">
                  <svg class="size-10 text-woot-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                  </svg>
                </div>
                
                <h3 class="font-extrabold text-slate-900 text-xl text-center leading-tight">
                  {{ qrTitle || 'We value your feedback!' }}
                </h3>
                <p class="mt-2 text-slate-500 text-xs text-center font-medium">
                  Open your phone's camera and point it at the code below to leave us a review.
                </p>

                <div class="mt-6 p-4 bg-white rounded-2xl shadow-sm border border-slate-100 ring-4 ring-slate-50">
                  <img
                    :src="qrImgSrc"
                    alt="QR Code"
                    class="size-48 object-contain"
                  />
                </div>
                
                <p class="mt-5 text-[10px] text-slate-400 font-medium truncate w-full px-4">
                  {{ qrUrl }}
                </p>
              </div>
            </div>

            <div class="space-y-2">
              <h4 class="font-extrabold text-sm text-slate-800 dark:text-white">Collect Offline Feedback Instantly</h4>
              <p class="text-xs text-slate-500 max-w-sm">Place this QR code at checkout counters, tables, or product packages to let customers scan and write reviews instantly.</p>
            </div>

            <div class="flex gap-2">
              <button
                class="px-4 py-2 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold text-slate-650 dark:text-slate-300 rounded-xl shadow-sm transition-all"
                onclick="window.print()"
              >
                Print Poster (Save as PDF)
              </button>
              <button
                class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all text-center flex items-center justify-center min-w-[140px]"
                :disabled="downloadingCard"
                @click="downloadFullCard"
              >
                <svg v-if="downloadingCard" class="size-3.5 animate-spin mr-1.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 7.89M9 11l3-3 3 3m0 0l-3 3-3-3" /></svg>
                {{ downloadingCard ? 'Downloading...' : 'Download Full PNG' }}
              </button>
            </div>
          </div>
        </div>

        <!-- 6. Spam Reviews View -->
        <div v-else-if="currentTab === 'spam_reviews'" class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-6">
          <div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-base">Spam Reviews Filters</h3>
            <p class="text-xs text-slate-400 mt-0.5">Automatically identify and isolate low rating or fake feedback</p>
          </div>

          <div class="space-y-4">
            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Auto-flag ratings under</label>
              <select
                v-model="spamMinRating"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
              >
                <option value="1">1 Star only</option>
                <option value="2">2 Stars & below</option>
                <option value="3">3 Stars & below</option>
              </select>
              <p class="text-[10px] text-slate-400">Flagged reviews will be marked as isolated and pending manual validation before public publishing.</p>
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Blocklist Keywords</label>
              <input
                v-model="spamKeywords"
                type="text"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
              />
              <p class="text-[10px] text-slate-450">Comma-separated list of terms. Reviews containing these keywords are auto-marked as spam.</p>
            </div>

            <div class="pt-4 border-t border-slate-100 dark:border-slate-850 flex justify-end">
              <button
                class="px-5 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm"
                @click="saveSpamSettings"
              >
                Save Spam Config
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>

    <!-- Google Business Location Selection Modal -->
    <div
      v-if="showLocationModal"
      class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm"
    >
      <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 max-w-lg w-full shadow-2xl p-6 space-y-5">
        <!-- Header -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="p-2 rounded-xl bg-red-50 dark:bg-red-950/30 text-red-500 font-extrabold text-xs">GB</div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-base">Select Google Business Location</h3>
          </div>
          <button class="text-slate-400 hover:text-slate-650" @click="showLocationModal = false">
            <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <!-- Content -->
        <div v-if="loadingLocations" class="flex flex-col items-center justify-center py-10 space-y-3">
          <div class="size-8 border-4 border-red-500 border-t-transparent rounded-full animate-spin"></div>
          <p class="text-xs text-slate-500">Fetching locations from Google Business...</p>
        </div>

        <div v-else-if="locationError" class="text-xs text-red-500 bg-red-50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30 rounded-xl px-4 py-2.5">
          {{ locationError }}
        </div>

        <div v-else-if="googleLocations.length === 0" class="text-center py-10 space-y-2">
          <p class="text-sm font-bold text-slate-700 dark:text-slate-350">No locations found</p>
          <p class="text-xs text-slate-400">Your Google Account has no registered Google Business Profile locations.</p>
        </div>

        <div v-else class="space-y-4">
          <p class="text-xs text-slate-500">
            We found the following Google Business Profile locations. Select the location you want to link to this account:
          </p>

          <div class="space-y-2">
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Select Location</label>
            <select
              v-model="selectedLocation"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            >
              <option v-for="loc in googleLocations" :key="loc.location_id" :value="loc">
                {{ loc.location_name }}
              </option>
            </select>
          </div>
        </div>

        <!-- Footer -->
        <div class="flex justify-end gap-2 pt-1">
          <button
            class="px-4 py-2 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold text-slate-500 dark:text-slate-355 rounded-xl transition-all"
            @click="showLocationModal = false"
          >
            Cancel
          </button>
          <button
            v-if="googleLocations.length > 0 && !locationError"
            class="px-5 py-2 bg-red-500 hover:bg-red-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2 disabled:opacity-60"
            :disabled="connectingLocation || loadingLocations"
            @click="submitGoogleLocationConnection"
          >
            <svg v-if="connectingLocation" class="size-3.5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
            {{ connectingLocation ? 'Connecting...' : 'Connect Location' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Connection Modal for standard listings -->
    <div
      v-if="showConnectModal"
      class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm"
    >
      <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 max-w-md w-full shadow-2xl p-6 space-y-5 animate-fade-in">
        <div class="flex items-center justify-between">
          <h3 class="font-extrabold text-slate-900 dark:text-white text-base">
            Connect {{ selectedPlatform?.name }} Listing
          </h3>
          <button 
            class="text-slate-400 hover:text-slate-650"
            @click="showConnectModal = false"
          >
            <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div class="space-y-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Listing URL</label>
            <input
              v-model="listingUrl"
              type="url"
              placeholder="https://..."
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
            <p class="text-[10px] text-slate-400">The public page URL where consumers leave feedback for your business.</p>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Listing / Location Label</label>
            <input
              v-model="listingName"
              type="text"
              placeholder="e.g. My Business Listing"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
          </div>
        </div>

        <div class="flex justify-end gap-2 pt-2">
          <button
            class="px-4 py-2 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold text-slate-500 dark:text-slate-350 rounded-xl transition-all"
            @click="showConnectModal = false"
          >
            Cancel
          </button>
          <button
            class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all"
            :disabled="saving"
            @click="submitConnection"
          >
            {{ saving ? 'Connecting...' : 'Connect page' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Custom link creation Modal -->
    <div
      v-if="showCustomModal"
      class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm"
    >
      <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 max-w-md w-full shadow-2xl p-6 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-extrabold text-slate-900 dark:text-white text-base">
            Create Custom Link Channel
          </h3>
          <button 
            class="text-slate-400 hover:text-slate-650"
            @click="showCustomModal = false"
          >
            <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div class="space-y-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Channel Platform Name</label>
            <input
              v-model="customPlatformName"
              type="text"
              placeholder="e.g. Trustpilot"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Listing Page Link</label>
            <input
              v-model="customPlatformUrl"
              type="url"
              placeholder="https://..."
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-450 uppercase tracking-wider">Logo/Icon theme</label>
            <select
              v-model="customPlatformLogo"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-750 dark:bg-slate-850 p-2.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            >
              <option value="link">Standard link icon</option>
              <option value="star">Star rating icon</option>
              <option value="brand">Premium trust logo</option>
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-2 pt-2">
          <button
            class="px-4 py-2 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold text-slate-500 dark:text-slate-350 rounded-xl transition-all"
            @click="showCustomModal = false"
          >
            Cancel
          </button>
          <button
            class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all"
            :disabled="saving"
            @click="submitCustomConnection"
          >
            {{ saving ? 'Adding...' : 'Add Link' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
@media print {
  body * {
    visibility: hidden;
  }
  
  #qr-print-card, #qr-print-card * {
    visibility: visible;
  }
  
  #qr-print-card {
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%) scale(1.8);
    width: 340px !important;
    border: none !important;
    box-shadow: none !important;
    margin: 0;
  }
}
</style>
