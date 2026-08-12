<script setup>
/* eslint-disable */
import { ref, onMounted, computed } from 'vue';
const axios = window.axios;

const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id || 
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const integrations = ref([]);
const reviews = ref([]);
const loading = ref(true);
const disconnectLoading = ref(null);

// AI reply drafting state
const activeReview = ref(null);
const replyBody = ref('');
const drafting = ref(false);

const connectGoogle = () => {
  const clientId = window.chatwootConfig?.reputationGoogleClientId;
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=google`;
  window.location.href =
    `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${redirect}&response_type=code&scope=https://www.googleapis.com/auth/business.manage&state=${accountId}`;
};

const connectFacebook = () => {
  const appId = window.chatwootConfig?.reputationFacebookAppId;
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=facebook`;
  window.location.href =
    `https://www.facebook.com/v18.0/dialog/oauth?client_id=${appId}&redirect_uri=${redirect}&scope=pages_show_list,pages_read_engagement&state=${accountId}`;
};

async function loadData() {
  loading.value = true;
  try {
    const [intRes, revRes] = await Promise.all([
      axios.get(`/api/v1/accounts/${accountId}/reputation/integrations`).catch(() => ({ data: [] })),
      axios.get(`/api/v1/accounts/${accountId}/reputation/reviews`).catch(() => ({ data: [] }))
    ]);
    integrations.value = intRes.data;
    reviews.value = revRes.data;
  } catch (err) {
    console.error('Failed to load reputation data', err);
  } finally {
    loading.value = false;
  }
}

async function disconnect(id) {
  if (!confirm('Are you sure you want to disconnect this platform? All cached reviews for it will be removed.')) return;
  disconnectLoading.value = id;
  try {
    await axios.delete(`/api/v1/accounts/${accountId}/reputation/integrations/${id}`);
    integrations.value = integrations.value.filter(i => i.id !== id);
    // Reload reviews to clear out deleted cached ones
    const revRes = await axios.get(`/api/v1/accounts/${accountId}/reputation/reviews`);
    reviews.value = revRes.data;
  } catch (err) {
    alert('Failed to disconnect integration');
  } finally {
    disconnectLoading.value = null;
  }
}

// Stats Calculations
const totalReviewsCount = computed(() => reviews.value.length);

const averageRating = computed(() => {
  if (reviews.value.length === 0) return 0;
  const sum = reviews.value.reduce((acc, r) => acc + r.rating, 0);
  return (sum / reviews.value.length).toFixed(1);
});

const pendingRepliesCount = computed(() => {
  return reviews.value.filter(r => r.status === 'pending').length;
});

const responseRate = computed(() => {
  if (reviews.value.length === 0) return 0;
  const replied = reviews.value.filter(r => r.status === 'replied').length;
  return Math.round((replied / reviews.value.length) * 100);
});

const starDistribution = computed(() => {
  const dist = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  reviews.value.forEach(r => {
    if (dist[r.rating] !== undefined) {
      dist[r.rating]++;
    }
  });
  return dist;
});

const isConnected = computed(() => integrations.value.length > 0);
const recentPendingReviews = computed(() => {
  return reviews.value.filter(r => r.status === 'pending').slice(0, 3);
});

// Direct reply tools
async function aiDraft(review) {
  drafting.value = true;
  activeReview.value = review;
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/ai_draft`);
    replyBody.value = data.draft;
  } catch (err) {
    replyBody.value = 'Failed to generate AI reply. Please try writing manually.';
  } finally {
    drafting.value = false;
  }
}

async function submitReply(review) {
  try {
    await axios.post(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/reply`, {
      body: replyBody.value,
      publish: true,
    });
    review.status = 'replied';
    activeReview.value = null;
    replyBody.value = '';
    // refresh data
    loadData();
  } catch (err) {
    alert('Failed to submit reply');
  }
}

async function ignoreReview(review) {
  try {
    await axios.patch(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/ignore`);
    review.status = 'ignored';
    // refresh data
    loadData();
  } catch (err) {
    alert('Failed to ignore review');
  }
}

onMounted(loadData);
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-8">
    <!-- eslint-disable -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-20 space-y-4">
      <div class="size-10 border-4 border-woot-500 border-t-transparent rounded-full animate-spin"></div>
      <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Loading dashboard...</p>
    </div>

    <!-- Onboarding State if not connected -->
    <div v-else-if="!isConnected" class="grid lg:grid-cols-12 gap-8 items-stretch">
      <div class="lg:col-span-7 flex flex-col justify-between p-8 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm">
        <div>
          <span class="px-3 py-1 rounded-full text-xs font-bold bg-woot-50 dark:bg-woot-900/30 text-woot-600 dark:text-woot-400 uppercase tracking-wider">
            Reputation Pro
          </span>
          <h2 class="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white mt-4">
            Build and Showcase Dynamic Social Proof
          </h2>
          <p class="text-slate-500 dark:text-slate-400 mt-3 text-base leading-relaxed">
            Connect your public profiles on Google and Facebook to pull user reviews in real time, draft personalized replies instantly using smart AI recommendations, and collect video testimonials.
          </p>

          <div class="mt-8 space-y-4">
            <div class="flex gap-3">
              <div class="shrink-0 p-2 rounded-lg bg-emerald-50 dark:bg-emerald-950/30 text-emerald-600 dark:text-emerald-400 h-9 w-9 flex items-center justify-center">
                <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
              </div>
              <div>
                <h4 class="font-bold text-slate-800 dark:text-slate-200 text-sm">Boost Search Rankings</h4>
                <p class="text-xs text-slate-500 dark:text-slate-400">Drive active keyword review streams directly to your local listings.</p>
              </div>
            </div>
            <div class="flex gap-3">
              <div class="shrink-0 p-2 rounded-lg bg-indigo-50 dark:bg-indigo-950/30 text-indigo-600 dark:text-indigo-400 h-9 w-9 flex items-center justify-center">
                <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
              </div>
              <div>
                <h4 class="font-bold text-slate-800 dark:text-slate-200 text-sm">Draft Replies in Seconds</h4>
                <p class="text-xs text-slate-500 dark:text-slate-400">Generate professional, context-aware responses with one click using AI.</p>
              </div>
            </div>
            <div class="flex gap-3">
              <div class="shrink-0 p-2 rounded-lg bg-amber-50 dark:bg-amber-950/30 text-amber-600 dark:text-amber-400 h-9 w-9 flex items-center justify-center">
                <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" /></svg>
              </div>
              <div>
                <h4 class="font-bold text-slate-800 dark:text-slate-200 text-sm">Private Interceptor funnel</h4>
                <p class="text-xs text-slate-500 dark:text-slate-400">Intercept negative ratings (1-3 stars) privately to fix issues before they go public.</p>
              </div>
            </div>
          </div>
        </div>

        <p class="text-xs text-slate-400 mt-8 border-t border-slate-100 dark:border-slate-850 pt-4">
          By connecting your integrations, you authorize Newrelay to pull public review streams.
        </p>
      </div>

      <div class="lg:col-span-5 flex flex-col justify-between p-8 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
        <div>
          <h3 class="text-xl font-bold text-slate-900 dark:text-white">Connect Review Platforms</h3>
          <p class="text-xs text-slate-400 mt-1">Start syncing customer feedback instantly</p>
        </div>

        <div class="space-y-4">
          <!-- Google Profile connection -->
          <div class="p-4 rounded-xl border border-slate-100 dark:border-slate-800 hover:border-slate-200 dark:hover:border-slate-700 transition-colors flex items-center justify-between gap-4">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg bg-red-50 dark:bg-red-950/20 text-red-500">
                <svg class="size-6" viewBox="0 0 24 24" fill="currentColor"><path d="M12.24 10.285V13.4h6.887c-.275 1.565-1.88 4.604-6.887 4.604-4.33 0-7.859-3.578-7.859-8s3.53-8 7.859-8c2.46 0 4.105 1.025 5.047 1.926l2.427-2.334C17.955 2.192 15.34 1 12.24 1 5.92 1 1 5.92 1 12s4.92 11 11.24 11c6.59 0 10.97-4.63 10.97-11.16 0-.756-.08-1.333-.18-1.555H12.24z"/></svg>
              </div>
              <div>
                <h4 class="font-bold text-slate-700 dark:text-slate-200 text-sm">Google Maps Listing</h4>
                <p class="text-xs text-slate-400">Sync Google Business Profile reviews</p>
              </div>
            </div>
            <button
              class="px-4 py-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold shadow-sm transition-all"
              @click="connectGoogle"
            >
              Connect
            </button>
          </div>

          <!-- Facebook Pages connection -->
          <div class="p-4 rounded-xl border border-slate-100 dark:border-slate-800 hover:border-slate-200 dark:hover:border-slate-700 transition-colors flex items-center justify-between gap-4">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg bg-blue-50 dark:bg-blue-950/20 text-blue-600">
                <svg class="size-6" viewBox="0 0 24 24" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
              </div>
              <div>
                <h4 class="font-bold text-slate-700 dark:text-slate-200 text-sm">Facebook Page</h4>
                <p class="text-xs text-slate-400">Sync ratings & page visitor feedback</p>
              </div>
            </div>
            <button
              disabled
              class="px-4 py-2 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-400 dark:text-slate-500 text-xs font-semibold shadow-sm cursor-not-allowed"
            >
              Coming Soon
            </button>
          </div>
        </div>

        <div class="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/40 text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
          <strong>Tip:</strong> Ensure you are an administrator of the Google location or Facebook Page you intend to connect.
        </div>
      </div>
    </div>

    <!-- Professional Dashboard (Connected state) -->
    <div v-else class="space-y-8 animate-fade">
      <!-- Welcome Header -->
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 class="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Overview Dashboard</h2>
          <p class="text-xs text-slate-400 mt-0.5">Real-time health index of your public ratings and responses</p>
        </div>
        <div class="flex gap-2">
          <button
            class="px-3.5 py-2 rounded-xl bg-white dark:bg-slate-850 hover:bg-slate-50 dark:hover:bg-slate-800 text-xs font-bold shadow-sm border border-slate-200 dark:border-slate-700 transition-all flex items-center gap-1.5"
            @click="loadData"
          >
            <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 7.89M9 11l3-3 3 3m0 0l-3 3-3-3" /></svg>
            Refresh data
          </button>
          <router-link
            :to="{ name: 'reputation_requests' }"
            class="px-3.5 py-2 rounded-xl bg-woot-500 hover:bg-woot-600 text-white text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
          >
            <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
            Request reviews
          </router-link>
        </div>
      </div>

      <!-- Quick Metrics Row -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm relative overflow-hidden group">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Average Rating</p>
          <div class="flex items-baseline gap-2 mt-2">
            <span class="text-3xl font-extrabold text-slate-900 dark:text-white">{{ averageRating }}</span>
            <span class="text-xs font-semibold text-emerald-500">★ Out of 5</span>
          </div>
          <!-- Simple stars row -->
          <div class="flex gap-0.5 mt-2.5 text-yellow-400">
            <span v-for="n in 5" :key="n" class="text-sm">
              {{ n <= Math.round(averageRating) ? '★' : '☆' }}
            </span>
          </div>
        </div>

        <div class="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Reviews</p>
          <div class="flex items-baseline gap-2 mt-2">
            <span class="text-3xl font-extrabold text-slate-900 dark:text-white">{{ totalReviewsCount }}</span>
            <span class="text-xs font-semibold text-slate-400">Synced reviews</span>
          </div>
          <p class="text-xs text-slate-500 mt-2.5 flex items-center gap-1">
            <span class="size-2 rounded-full bg-emerald-500 inline-block animate-pulse"></span>
            Sync poller active
          </p>
        </div>

        <div class="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">AI Response Rate</p>
          <div class="flex items-baseline gap-2 mt-2">
            <span class="text-3xl font-extrabold text-slate-900 dark:text-white">{{ responseRate }}%</span>
            <span class="text-xs font-semibold text-woot-500">Replied</span>
          </div>
          <!-- progress bar -->
          <div class="w-full bg-slate-100 dark:bg-slate-800 h-1.5 rounded-full mt-3.5 overflow-hidden">
            <div class="bg-woot-500 h-full rounded-full transition-all duration-300" :style="{ width: `${responseRate}%` }"></div>
          </div>
        </div>

        <div class="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Pending Action</p>
          <div class="flex items-baseline gap-2 mt-2">
            <span class="text-3xl font-extrabold text-slate-900 dark:text-white">{{ pendingRepliesCount }}</span>
            <span class="text-xs font-semibold text-amber-500">Needs Reply</span>
          </div>
          <p class="text-xs text-slate-400 mt-2.5">
            Avg reply time: <strong class="text-slate-600 dark:text-slate-350">~15m</strong>
          </p>
        </div>
      </div>

      <!-- Rating Distribution & Active Integrations Section -->
      <div class="grid lg:grid-cols-12 gap-6 items-start">
        <!-- Distribution Chart Card -->
        <div class="lg:col-span-7 p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm space-y-4">
          <div>
            <h3 class="font-extrabold text-slate-950 dark:text-white text-base">Ratings Distribution</h3>
            <p class="text-xs text-slate-400">Score segmentation across synced listings</p>
          </div>

          <div class="space-y-3.5">
            <div v-for="stars in [5, 4, 3, 2, 1]" :key="stars" class="flex items-center gap-3">
              <span class="w-8 text-xs font-bold text-slate-500 flex items-center justify-end gap-1">
                {{ stars }}<span class="text-yellow-400">★</span>
              </span>
              <div class="flex-1 bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden">
                <div 
                  class="bg-gradient-to-r h-full rounded-full transition-all duration-300"
                  :class="{
                    'from-yellow-400 to-amber-500': stars >= 4,
                    'from-orange-400 to-amber-500': stars === 3,
                    'from-red-400 to-orange-500': stars <= 2
                  }"
                  :style="{ 
                    width: `${totalReviewsCount > 0 ? (starDistribution[stars] / totalReviewsCount) * 100 : 0}%` 
                  }"
                ></div>
              </div>
              <span class="w-10 text-xs font-bold text-slate-400 text-right">
                {{ starDistribution[stars] }}
              </span>
            </div>
          </div>
        </div>

        <!-- Connected platforms checklist -->
        <div class="lg:col-span-5 p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm space-y-5">
          <div>
            <h3 class="font-extrabold text-slate-950 dark:text-white text-base">Active Connections</h3>
            <p class="text-xs text-slate-400">Synching locations and active listings</p>
          </div>

          <div class="space-y-3">
            <div
              v-for="int in integrations"
              :key="int.id"
              class="p-4 rounded-xl bg-slate-50 dark:bg-slate-850 border border-slate-100 dark:border-slate-800 flex items-center justify-between gap-4"
            >
              <div class="flex items-center gap-3 min-w-0">
                <span 
                  v-if="int.provider === 'google'"
                  class="p-2 rounded-lg bg-red-100/50 dark:bg-red-950/20 text-red-500 shrink-0"
                >
                  <svg class="size-5" viewBox="0 0 24 24" fill="currentColor"><path d="M12.24 10.285V13.4h6.887c-.275 1.565-1.88 4.604-6.887 4.604-4.33 0-7.859-3.578-7.859-8s3.53-8 7.859-8c2.46 0 4.105 1.025 5.047 1.926l2.427-2.334C17.955 2.192 15.34 1 12.24 1 5.92 1 1 5.92 1 12s4.92 11 11.24 11c6.59 0 10.97-4.63 10.97-11.16 0-.756-.08-1.333-.18-1.555H12.24z"/></svg>
                </span>
                <span 
                  v-else-if="int.provider === 'facebook'"
                  class="p-2 rounded-lg bg-blue-100/50 dark:bg-blue-950/20 text-blue-600 shrink-0"
                >
                  <svg class="size-5" viewBox="0 0 24 24" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
                </span>
                <div class="min-w-0">
                  <h4 class="font-bold text-slate-800 dark:text-slate-200 text-sm truncate capitalize">
                    {{ int.provider }}
                  </h4>
                  <p class="text-xs text-slate-400 truncate mt-0.5 font-medium">
                    {{ int.location_name || 'Active location' }}
                  </p>
                </div>
              </div>

              <button
                class="text-xs text-red-500 dark:text-red-400 font-bold hover:underline shrink-0 flex items-center gap-1"
                :disabled="disconnectLoading === int.id"
                @click="disconnect(int.id)"
              >
                <svg v-if="disconnectLoading === int.id" class="size-3.5 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 7.89M9 11l3-3 3 3m0 0l-3 3-3-3" /></svg>
                Disconnect
              </button>
            </div>
            
            <!-- Connect Google & Facebook options directly if they aren't both connected -->
            <div v-if="integrations.length < 2" class="flex gap-2 pt-2">
              <button
                v-if="!integrations.some(i => i.provider === 'google')"
                class="flex-1 py-2 px-3 border border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-350 transition-colors flex items-center justify-center gap-1.5"
                @click="connectGoogle"
              >
                Connect Google
              </button>
              <button
                v-if="!integrations.some(i => i.provider === 'facebook')"
                disabled
                class="flex-1 py-2 px-3 border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/20 rounded-xl text-xs font-bold text-slate-400 dark:text-slate-500 cursor-not-allowed flex items-center justify-center gap-1.5"
              >
                Facebook (Soon)
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Action Required (Recent Pending Reviews list) -->
      <div class="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm space-y-5">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="font-extrabold text-slate-950 dark:text-white text-base">Reviews Requiring Attention</h3>
            <p class="text-xs text-slate-400">Quickly resolve recent feedback without leaving the dashboard</p>
          </div>
          <router-link
            :to="{ name: 'reputation_reviews' }"
            class="text-xs text-woot-500 font-bold hover:underline"
          >
            See all reviews →
          </router-link>
        </div>

        <div v-if="recentPendingReviews.length === 0" class="flex flex-col items-center justify-center py-10 space-y-2">
          <div class="p-3 rounded-full bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600 dark:text-emerald-400">
            <svg class="size-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" /></svg>
          </div>
          <p class="text-sm font-bold text-slate-700 dark:text-slate-300">All caught up!</p>
          <p class="text-xs text-slate-400">Every synced review has been responded to or ignored.</p>
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="review in recentPendingReviews"
            :key="review.id"
            class="p-4 rounded-xl border border-slate-100 dark:border-slate-850 hover:bg-slate-50/50 dark:hover:bg-slate-850/40 transition-colors"
          >
            <div class="flex flex-col md:flex-row md:items-start justify-between gap-4">
              <div class="space-y-1">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="text-xs font-bold text-slate-700 dark:text-slate-300">{{ review.reviewer_name }}</span>
                  <span class="size-1 bg-slate-300 rounded-full"></span>
                  <span class="text-yellow-400 font-bold text-xs">
                    {{ '★'.repeat(review.rating) }}{{ '☆'.repeat(5 - review.rating) }}
                  </span>
                  <span class="size-1 bg-slate-300 rounded-full"></span>
                  <span class="text-[10px] uppercase font-bold text-slate-400 px-2 py-0.5 bg-slate-100 dark:bg-slate-800 rounded-full capitalize">
                    {{ review.provider }}
                  </span>
                </div>
                <p class="text-sm text-slate-650 dark:text-slate-300 italic leading-relaxed">
                  "{{ review.body || '(No comments provided)' }}"
                </p>
                <p class="text-[10px] text-slate-400 font-medium">
                  Reviewed on {{ new Date(review.reviewed_at).toLocaleDateString() }}
                </p>
              </div>

              <div class="flex gap-2 self-start shrink-0">
                <button
                  class="px-3 py-1.5 text-xs font-bold text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg transition-colors"
                  @click="ignoreReview(review)"
                >
                  Ignore
                </button>
                <button
                  class="px-3 py-1.5 text-xs font-bold bg-gradient-to-tr from-woot-600 to-indigo-500 hover:from-woot-700 hover:to-indigo-600 text-white shadow-sm rounded-lg transition-colors flex items-center gap-1"
                  @click="aiDraft(review)"
                >
                  <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                  Draft with AI
                </button>
              </div>
            </div>

            <!-- Inline AI Reply panel -->
            <div v-if="activeReview?.id === review.id" class="mt-4 border-t border-slate-100 dark:border-slate-800 pt-4 space-y-3">
              <label class="block text-xs font-bold text-slate-400 uppercase tracking-wider">Compose Reply</label>
              <textarea
                v-model="replyBody"
                rows="3"
                class="w-full text-sm rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-250 p-3.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
                :placeholder="drafting ? 'Drafting response via AI assistant...' : 'Write response here...'"
              />
              <div class="flex justify-between items-center">
                <span class="text-[10px] text-slate-400">AI drafted response can be fully edited before publishing.</span>
                <div class="flex gap-2">
                  <button
                    class="px-3 py-1.5 text-xs font-bold text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg border border-slate-150 dark:border-slate-850"
                    @click="activeReview = null"
                  >
                    Cancel
                  </button>
                  <button
                    class="px-3.5 py-1.5 text-xs font-bold bg-woot-500 hover:bg-woot-600 text-white rounded-lg transition-colors"
                    :disabled="!replyBody"
                    @click="submitReply(review)"
                  >
                    Publish reply
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
