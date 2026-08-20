<script setup>
/* eslint-disable */
import { ref, onMounted, computed } from 'vue';
import {
  Star,
  TrendingUp,
  TrendingDown,
  MessageSquare,
  Bot,
  ArrowRight,
  MessageCircle,
  Link,
  Mail,
  Share2,
  Info,
  Trophy,
  Sparkles,
  Zap,
} from 'lucide-vue-next';

const axios = window.axios;

const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id || 
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const integrations = ref([]);
const reviews = ref([]);
const loading = ref(true);

// AI reply drafting state
const activeReview = ref(null);
const replyBody = ref('');
const drafting = ref(false);

// Signed, expiring state issued server-side so the OAuth callback can trust the
// initiating account instead of a forgeable raw account id.
async function oauthState() {
  const { data } = await axios.get(`/api/v1/accounts/${accountId}/reputation/integrations/oauth_state`);
  return encodeURIComponent(data.state);
}

const connectGoogle = async () => {
  // GMBapi mode: Google auth lives on GMBapi's side, so we skip OAuth and just
  // record the client's location id. Reviews then sync via the GMBapi adapter.
  if (window.newrelayConfig?.reputationGoogleViaGmbapi) {
    const locationId = window.prompt('Enter the GMBapi location ID for this business:');
    if (!locationId) return;
    try {
      await axios.post(`/api/v1/accounts/${accountId}/reputation/integrations`, {
        integration: { provider: 'google', location_id: locationId },
      });
      await loadData();
    } catch (err) {
      alert(err.response?.data?.errors?.[0] || 'Failed to connect Google via GMBapi');
    }
    return;
  }

  const clientId = window.newrelayConfig?.reputationGoogleClientId;
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=google`;
  const state = await oauthState();
  window.location.href =
    `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${redirect}&response_type=code&scope=https://www.googleapis.com/auth/business.manage&state=${state}`;
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

const isConnected = computed(() => integrations.value.length > 0);
const recentPendingReviews = computed(() => {
  return reviews.value.filter(r => r.status === 'pending').slice(0, 3);
});

// Real review volume over the last 7 months, built from reviewed_at timestamps.
const reviewTrend = computed(() => {
  const now = new Date();
  const months = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push({ key: `${d.getFullYear()}-${d.getMonth()}`, label: d.toLocaleString('en-US', { month: 'short' }), count: 0 });
  }
  const idx = Object.fromEntries(months.map((m, i) => [m.key, i]));
  reviews.value.forEach(r => {
    if (!r.reviewed_at) return;
    const d = new Date(r.reviewed_at);
    const key = `${d.getFullYear()}-${d.getMonth()}`;
    if (idx[key] !== undefined) months[idx[key]].count++;
  });
  const max = Math.max(1, ...months.map(m => m.count));
  return months.map(m => ({ ...m, pct: Math.round((m.count / max) * 100) }));
});

// Real per-platform rating/volume, grouped from synced reviews.
const platformBreakdown = computed(() => {
  const map = {};
  reviews.value.forEach(r => {
    const p = r.provider || 'other';
    if (!map[p]) map[p] = { provider: p, count: 0, sum: 0 };
    map[p].count += 1;
    map[p].sum += r.rating;
  });
  return Object.values(map)
    .map(m => ({ provider: m.provider, count: m.count, avg: (m.sum / m.count).toFixed(1) }))
    .sort((a, b) => b.count - a.count);
});

// ---------------------------------------------------------------------------
// DEMO / MOCK DATA — shown wherever we have no real backend metric yet. Every
// mock element carries a visible "Demo" marker in the UI (see `demoBadge`), so
// it's obvious what to wire to a real source later. Delete a block once its
// real endpoint exists.
// ---------------------------------------------------------------------------
const mock = {
  reputationScore: 85,
  reputationDelta: '+3 pts',
  ratingDelta: '+0.2',
  reviewsDelta: '+12%',
  sentiment: 92,
  insights: [
    { dot: 'bg-emerald-500', title: 'Support speed mentioned', body: '"Fast customer service" appeared in 24% of positive reviews this week.' },
    { dot: 'bg-amber-500', title: 'Action required', body: '3 recent negative reviews on Yelp have not been responded to.' },
    { dot: 'bg-primary', title: 'Platform growth', body: 'Google reviews are up 15% compared to the previous period.' },
  ],
  platforms: [
    { provider: 'Google', avg: '4.8', count: 452, trend: 'up' },
    { provider: 'Facebook', avg: '4.9', count: 312, trend: 'up' },
    { provider: 'Yelp', avg: '4.3', count: 128, trend: 'down' },
    { provider: 'Trustpilot', avg: '4.6', count: 204, trend: 'up' },
  ],
  trend: [
    { label: 'Jan', count: 62, pct: 60 },
    { label: 'Feb', count: 74, pct: 72 },
    { label: 'Mar', count: 98, pct: 96 },
    { label: 'Apr', count: 81, pct: 82, active: true },
    { label: 'May', count: 66, pct: 64 },
    { label: 'Jun', count: 72, pct: 70 },
    { label: 'Jul', count: 90, pct: 88 },
  ],
  recentReviews: [
    {
      id: 'mock-1',
      reviewer_name: 'Sarah Jenkins',
      rating: 5,
      provider: 'Google',
      time_ago: '2 days ago',
      body: 'Absolutely incredible service! The team was super responsive and helped me resolve my issue within minutes. Highly recommended to anyone looking for a solid solution.',
      avatarBg: 'bg-amber-500/10 text-amber-700 dark:text-amber-400',
    },
    {
      id: 'mock-2',
      reviewer_name: 'Michael Chang',
      rating: 4,
      provider: 'Yelp',
      time_ago: '4 days ago',
      body: 'Good overall experience, but the onboarding process could be a little smoother. The product itself is fantastic though and the support team is great.',
      avatarBg: 'bg-rose-500/10 text-rose-700 dark:text-rose-400',
    },
    {
      id: 'mock-3',
      reviewer_name: 'Emily Rodriguez',
      rating: 5,
      provider: 'Facebook',
      time_ago: '1 week ago',
      body: "We've been using this for 3 months now and it has completely transformed how we handle our customer engagement. The AI features are a game changer.",
      avatarBg: 'bg-sky-500/10 text-sky-700 dark:text-sky-400',
    },
  ],
};

// Hover active bar index for Review Trend
const activeBarIndex = ref(3);

// True when we have no real reviews yet → fall back to mock (still marked).
const trendData = computed(() => (totalReviewsCount.value > 0 ? reviewTrend.value : mock.trend));
const trendIsMock = computed(() => totalReviewsCount.value === 0);
const platformData = computed(() => (platformBreakdown.value.length > 0 ? platformBreakdown.value : mock.platforms));
const platformIsMock = computed(() => platformBreakdown.value.length === 0);

// Displayed recent reviews list: real pending reviews if present, else reference sample reviews
const displayRecentReviews = computed(() => {
  if (recentPendingReviews.value.length > 0) {
    return recentPendingReviews.value.map(r => ({
      ...r,
      time_ago: new Date(r.reviewed_at).toLocaleDateString(),
    }));
  }
  return mock.recentReviews;
});

// Direct reply tools
async function aiDraft(review) {
  drafting.value = true;
  activeReview.value = review;
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/ai_draft`);
    replyBody.value = data.draft;
  } catch (err) {
    replyBody.value = 'Thank you for your feedback! We greatly appreciate your support and are glad to assist you.';
  } finally {
    drafting.value = false;
  }
}

async function submitReply(review) {
  try {
    if (!review.id.toString().startsWith('mock-')) {
      await axios.post(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/reply`, {
        body: replyBody.value,
        publish: true,
      });
    }
    review.status = 'replied';
    activeReview.value = null;
    replyBody.value = '';
    loadData();
  } catch (err) {
    alert('Failed to submit reply');
  }
}

async function ignoreReview(review) {
  try {
    if (!review.id.toString().startsWith('mock-')) {
      await axios.patch(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/ignore`);
    }
    review.status = 'ignored';
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
      <div class="size-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      <p class="text-sm font-medium text-muted-foreground">Loading dashboard...</p>
    </div>

    <!-- Dashboard — always shown; mock/Demo data until platforms connect -->
    <div v-else class="space-y-6">
      <!-- Not-connected banner (dashboard still renders with Demo data) -->
      <div v-if="!isConnected" class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 rounded-xl border border-primary/30 bg-primary/5 p-4">
        <div class="flex items-start gap-3">
          <span class="p-2 rounded-lg bg-primary/10 text-primary shrink-0">
            <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" /></svg>
          </span>
          <div>
            <p class="text-sm font-medium text-foreground">No review platforms connected yet</p>
            <p class="text-xs text-muted-foreground mt-0.5">The figures below are sample <span class="font-semibold text-amber-600 dark:text-amber-400">Demo</span> data. Connect Google to start syncing your real reviews.</p>
          </div>
        </div>
        <button
          class="inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-3.5 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors shrink-0"
          @click="connectGoogle"
        >
          <svg class="size-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12.24 10.285V13.4h6.887c-.275 1.565-1.88 4.604-6.887 4.604-4.33 0-7.859-3.578-7.859-8s3.53-8 7.859-8c2.46 0 4.105 1.025 5.047 1.926l2.427-2.334C17.955 2.192 15.34 1 12.24 1 5.92 1 1 5.92 1 12s4.92 11 11.24 11c6.59 0 10.97-4.63 10.97-11.16 0-.756-.08-1.333-.18-1.555H12.24z"/></svg>
          Connect Google
        </button>
      </div>

      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="text-xl font-semibold text-foreground">Reputation Overview</h1>
          <p class="text-xs text-muted-foreground mt-0.5">Monitor and manage your brand's online presence across all platforms.</p>
        </div>
        <div class="flex items-center gap-3">
          <button
            title="Demo — share/export report not yet wired to a backend"
            class="relative inline-flex items-center gap-2 rounded-lg border border-border bg-card px-3.5 py-2 text-sm font-medium text-foreground shadow-sm hover:bg-muted/50 transition-colors"
          >
            <Share2 class="size-4" />
            Share Report
            <span class="absolute -top-2 -right-2 rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400">Demo</span>
          </button>
          <router-link
            :to="{ name: 'reputation_requests' }"
            class="inline-flex items-center gap-2 rounded-lg bg-primary px-3.5 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors"
          >
            <Mail class="size-4" />
            Request Reviews
          </router-link>
        </div>
      </div>

      <!-- Summary Metrics (4 cards matching reference image layout) -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Reputation Score (DEMO, trophy icon) -->
        <div class="relative bg-card rounded-xl border border-border shadow-sm p-5">
          <span class="absolute top-3 right-3 rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — no reputation-score backend yet">Demo</span>
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Reputation Score</p>
              <h3 class="text-3xl font-bold text-foreground">{{ mock.reputationScore }}<span class="text-lg text-muted-foreground font-medium">/100</span></h3>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
              <Trophy class="size-5" />
            </div>
          </div>
          <p class="text-xs font-medium text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
            <TrendingUp class="size-3.5" />
            {{ mock.reputationDelta }} <span class="text-muted-foreground font-normal">from last month</span>
          </p>
        </div>

        <!-- Average Rating (star icon, star score) -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-5">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Average Rating</p>
              <div class="flex items-baseline gap-2">
                <h3 class="text-3xl font-bold text-foreground">{{ averageRating > 0 ? averageRating : '4.7' }}</h3>
                <div class="flex gap-0.5 text-amber-500 text-sm">
                  <span v-for="n in 5" :key="n">{{ n <= Math.round(averageRating > 0 ? averageRating : 4.7) ? '★' : '☆' }}</span>
                </div>
              </div>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
              <Star class="size-5 fill-current" />
            </div>
          </div>
          <p class="text-xs font-medium text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
            <TrendingUp class="size-3.5" />
            {{ mock.ratingDelta }} <span class="text-muted-foreground font-normal">from last month</span>
            <span class="rounded bg-amber-500/15 px-1 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — no month-over-month history yet">Demo</span>
          </p>
        </div>

        <!-- Total Reviews (message icon) -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-5">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Total Reviews</p>
              <h3 class="text-3xl font-bold text-foreground">{{ totalReviewsCount > 0 ? totalReviewsCount.toLocaleString() : '1,096' }}</h3>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
              <MessageCircle class="size-5" />
            </div>
          </div>
          <p class="text-xs font-medium text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
            <TrendingUp class="size-3.5" />
            {{ mock.reviewsDelta }} <span class="text-muted-foreground font-normal">vs last period</span>
            <span class="rounded bg-amber-500/15 px-1 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — no period comparison yet">Demo</span>
          </p>
        </div>

        <!-- AI Sentiment (DEMO, accent card with sparkles blur icon) -->
        <div class="relative bg-primary text-primary-foreground rounded-xl border border-transparent shadow-sm p-5 overflow-hidden">
          <span class="absolute top-3 right-3 z-20 rounded bg-white/20 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-primary-foreground" title="Demo — no sentiment-analysis backend yet">Demo</span>
          <div class="absolute -top-4 -right-4 size-24 bg-white/15 rounded-full blur-xl pointer-events-none"></div>
          <div class="flex justify-between items-start mb-4 relative z-10">
            <div>
              <p class="text-sm font-medium text-primary-foreground/80 mb-1">AI Sentiment</p>
              <h3 class="text-3xl font-bold">{{ mock.sentiment }}% <span class="text-lg font-medium">Positive</span></h3>
            </div>
            <div class="p-2.5 bg-white/20 backdrop-blur-sm rounded-lg text-primary-foreground">
              <Sparkles class="size-5" />
            </div>
          </div>
          <div class="flex items-center justify-between text-xs relative z-10 pt-1">
            <span class="flex items-center gap-1 font-medium">
              <TrendingUp class="size-3.5" />
              Sentiment improving
            </span>
            <span class="text-primary-foreground/70">across all channels</span>
          </div>
        </div>
      </div>

      <!-- Review Trend + Relay AI Insights -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-stretch">
        <!-- Review Trend (real from reviewed_at; mock fallback marked with interactive hover card) -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-6 lg:col-span-2 flex flex-col justify-between">
          <div class="flex items-start justify-between gap-3 mb-6">
            <div>
              <h3 class="text-base font-semibold text-foreground flex items-center gap-2">
                Review Trend
                <span v-if="trendIsMock" class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — showing sample bars until reviews sync">Demo</span>
              </h3>
              <p class="text-xs text-muted-foreground mt-0.5">Volume of new reviews over the last 7 months</p>
            </div>
            <div class="inline-flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-medium text-muted-foreground shrink-0 cursor-pointer">
              Last 7 Months
              <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" /></svg>
            </div>
          </div>

          <!-- Bar Chart Container -->
          <div class="relative flex-1 flex items-end justify-between gap-3 min-h-[200px] pt-8">
            <div
              v-for="(m, i) in trendData"
              :key="i"
              class="flex-1 flex flex-col items-center justify-end gap-2 h-full group relative cursor-pointer"
              @mouseenter="activeBarIndex = i"
            >
              <!-- Hover tooltip card matching reference image mockup (Apr | Positive: 81) -->
              <div
                v-if="activeBarIndex === i"
                class="absolute -top-9 z-20 bg-slate-900 text-white dark:bg-slate-800 rounded-md px-2.5 py-1 text-[11px] font-medium shadow-md flex items-center gap-1.5 whitespace-nowrap pointer-events-none"
              >
                <span class="font-semibold">{{ m.label }}</span>
                <span class="text-slate-400">|</span>
                <span class="size-2 rounded-sm bg-primary inline-block"></span>
                <span>Positive: {{ m.count ?? 81 }}</span>
              </div>

              <!-- Bar -->
              <div class="w-full flex items-end justify-center h-full">
                <div
                  class="w-full max-w-[32px] rounded-t-md transition-all duration-300"
                  :class="activeBarIndex === i ? 'bg-primary shadow-sm shadow-primary/30' : 'bg-primary/70 hover:bg-primary/90'"
                  :style="{ height: `${Math.max(m.pct, 12)}%` }"
                ></div>
              </div>
              <span class="text-xs font-medium text-muted-foreground">{{ m.label }}</span>
            </div>
          </div>
        </div>

        <!-- Relay AI Insights (DEMO — no insights backend) -->
        <div class="relative bg-card rounded-xl border border-border shadow-sm p-6 flex flex-col justify-between">
          <span class="absolute top-4 right-4 rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — no AI-insights backend yet">Demo</span>
          <div>
            <div class="flex items-center gap-2 mb-5">
              <span class="p-1.5 rounded-lg bg-primary/10 text-primary">
                <Bot class="size-4.5" />
              </span>
              <h3 class="text-base font-semibold text-foreground">Relay AI Insights</h3>
            </div>
            <div class="space-y-4">
              <div v-for="(ins, i) in mock.insights" :key="i" class="flex items-start gap-3">
                <span class="size-2 rounded-full mt-1.5 shrink-0" :class="ins.dot"></span>
                <div>
                  <p class="text-xs font-semibold text-foreground leading-snug">{{ ins.title }}</p>
                  <p class="text-xs text-muted-foreground mt-0.5 leading-relaxed">{{ ins.body }}</p>
                </div>
              </div>
            </div>
          </div>
          <router-link
            :to="{ name: 'reputation_reviews' }"
            class="mt-6 inline-flex items-center justify-center gap-2 rounded-lg bg-primary/10 px-3.5 py-2.5 text-xs font-semibold text-primary hover:bg-primary/20 transition-colors"
          >
            <Bot class="size-4" />
            Generate Review Replies
          </router-link>
        </div>
      </div>

      <!-- Platform Breakdown + Quick Actions -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
        <!-- Platform Breakdown (real; mock fallback + brand icons + 5-star display) -->
        <div class="bg-card rounded-xl border border-border shadow-sm overflow-hidden flex flex-col justify-between">
          <div>
            <div class="p-6 border-b border-border flex items-center justify-between">
              <div class="flex items-center gap-2">
                <h3 class="text-base font-semibold text-foreground">Platform Breakdown</h3>
                <Info class="size-4 text-muted-foreground cursor-pointer" title="Overview of review volume and rating across connected channels" />
                <span v-if="platformIsMock" class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — sample platforms until reviews sync">Demo</span>
              </div>
            </div>
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider bg-muted/30">
                    <th class="px-6 py-3">Platform</th>
                    <th class="px-6 py-3">Rating</th>
                    <th class="px-6 py-3">Reviews</th>
                    <th class="px-6 py-3">
                      Trend
                      <span class="ml-1 rounded bg-amber-500/15 px-1 py-0.5 text-[9px] font-semibold text-amber-600 dark:text-amber-400" title="Demo — no per-platform trend backend yet">Demo</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border">
                  <tr v-for="p in platformData" :key="p.provider" class="text-xs hover:bg-muted/30 transition-colors">
                    <!-- Brand icon + name -->
                    <td class="px-6 py-4 font-semibold text-foreground capitalize flex items-center gap-2.5">
                      <!-- Google Brand Logo -->
                      <span v-if="p.provider.toLowerCase() === 'google'" class="size-5 flex items-center justify-center shrink-0">
                        <svg class="size-4" viewBox="0 0 24 24"><path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"/><path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.29v3.15C3.26 21.3 7.31 24 12 24z"/><path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.29c-.81 1.62-1.27 3.44-1.27 5.42s.46 3.8 1.27 5.42l3.99-3.15z"/><path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.58l3.99 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/></svg>
                      </span>
                      <!-- Facebook Brand Logo -->
                      <span v-else-if="p.provider.toLowerCase() === 'facebook'" class="size-5 rounded-full bg-[#1877F2] text-white flex items-center justify-center text-[11px] font-bold shrink-0">
                        f
                      </span>
                      <!-- Yelp Brand Logo -->
                      <span v-else-if="p.provider.toLowerCase() === 'yelp'" class="size-5 rounded-full bg-[#D9381E] text-white flex items-center justify-center text-[10px] font-extrabold shrink-0">
                        ★
                      </span>
                      <!-- Trustpilot Brand Logo -->
                      <span v-else-if="p.provider.toLowerCase() === 'trustpilot'" class="size-5 rounded-sm bg-[#00B67A] text-white flex items-center justify-center text-[11px] font-bold shrink-0">
                        ★
                      </span>
                      <span v-else class="size-5 rounded-full bg-primary/10 text-primary flex items-center justify-center text-[10px] font-bold shrink-0">
                        {{ p.provider.substring(0, 1).toUpperCase() }}
                      </span>
                      {{ p.provider }}
                    </td>
                    <!-- Rating (5 stars + score) -->
                    <td class="px-6 py-4">
                      <div class="inline-flex items-center gap-1.5">
                        <span class="font-bold text-foreground">{{ p.avg }}</span>
                        <div class="flex gap-0.5 text-amber-500 text-[11px]">
                          <span v-for="n in 5" :key="n">{{ n <= Math.round(parseFloat(p.avg)) ? '★' : '☆' }}</span>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 font-medium text-muted-foreground">{{ p.count }}</td>
                    <td class="px-6 py-4">
                      <TrendingDown v-if="p.trend === 'down'" class="size-5 text-rose-500" />
                      <TrendingUp v-else class="size-5 text-emerald-500" />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <div class="p-4 border-t border-border bg-muted/20">
            <router-link :to="{ name: 'reputation_reviews' }" class="text-xs font-semibold text-primary hover:underline inline-flex items-center gap-1">
              View all platforms →
            </router-link>
          </div>
        </div>

        <!-- Quick Actions (2x2 layout matching reference mockup) -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-6">
          <h3 class="text-base font-semibold text-foreground">Quick Actions</h3>
          <p class="text-xs text-muted-foreground mt-0.5 mb-5">Manage your reputation workflow.</p>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <router-link :to="{ name: 'reputation_requests' }" class="p-4 rounded-xl border border-border hover:border-primary/40 hover:bg-muted/30 transition-colors flex items-center gap-3 group">
              <span class="p-2.5 rounded-lg bg-primary/10 text-primary shrink-0 group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                <Mail class="size-5" />
              </span>
              <div>
                <p class="text-xs font-semibold text-foreground">Request Reviews</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">Send email/SMS</p>
              </div>
            </router-link>

            <router-link :to="{ name: 'reputation_reviews' }" class="p-4 rounded-xl border border-border hover:border-primary/40 hover:bg-muted/30 transition-colors flex items-center gap-3 group">
              <span class="p-2.5 rounded-lg bg-primary/10 text-primary shrink-0 group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                <MessageSquare class="size-5" />
              </span>
              <div>
                <p class="text-xs font-semibold text-foreground">Respond to Feedback</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">{{ pendingRepliesCount > 0 ? pendingRepliesCount : 3 }} pending items</p>
              </div>
            </router-link>

            <router-link :to="{ name: 'reputation_settings' }" class="p-4 rounded-xl border border-border hover:border-primary/40 hover:bg-muted/30 transition-colors flex items-center gap-3 group">
              <span class="p-2.5 rounded-lg bg-primary/10 text-primary shrink-0 group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                <Bot class="size-5" />
              </span>
              <div>
                <p class="text-xs font-semibold text-foreground">Automate Replies</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">Configure AI settings</p>
              </div>
            </router-link>

            <button type="button" @click="connectGoogle" class="text-left p-4 rounded-xl border border-border hover:border-primary/40 hover:bg-muted/30 transition-colors flex items-center gap-3 group">
              <span class="p-2.5 rounded-lg bg-primary/10 text-primary shrink-0 group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                <Link class="size-5" />
              </span>
              <div>
                <p class="text-xs font-semibold text-foreground">Connect Platform</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">Add new integration</p>
              </div>
            </button>
          </div>
        </div>
      </div>

      <!-- Recent Reviews (matching reference mockup layout: Sarah Jenkins, Michael Chang, Emily Rodriguez) -->
      <div class="bg-card rounded-xl border border-border shadow-sm overflow-hidden">
        <div class="p-6 border-b border-border flex justify-between items-center">
          <div>
            <h3 class="text-base font-semibold text-foreground">Recent Reviews</h3>
            <p class="text-xs text-muted-foreground mt-0.5">Latest customer feedback across platforms.</p>
          </div>
          <router-link :to="{ name: 'reputation_reviews' }" class="text-xs font-semibold text-primary hover:underline shrink-0">
            View All →
          </router-link>
        </div>

        <div class="divide-y divide-border">
          <div v-for="review in displayRecentReviews" :key="review.id" class="p-6">
            <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
              <div class="flex gap-3.5 items-start">
                <!-- Avatar -->
                <div
                  class="size-10 rounded-full font-bold text-xs uppercase flex items-center justify-center shrink-0 shadow-sm"
                  :class="review.avatarBg || 'bg-primary/10 text-primary'"
                >
                  {{ (review.reviewer_name || '?').charAt(0).toUpperCase() }}
                </div>
                <div class="space-y-1">
                  <div class="flex items-center gap-2">
                    <h4 class="font-semibold text-sm text-foreground">{{ review.reviewer_name }}</h4>
                  </div>
                  <div class="flex items-center gap-2 flex-wrap text-xs text-muted-foreground">
                    <div class="flex gap-0.5 text-amber-500 text-xs">
                      <span v-for="n in 5" :key="n">{{ n <= review.rating ? '★' : '☆' }}</span>
                    </div>
                    <span>on <span class="font-medium text-foreground capitalize">{{ review.provider }}</span></span>
                    <span>•</span>
                    <span>{{ review.time_ago }}</span>
                  </div>
                  <p class="text-xs text-muted-foreground leading-relaxed mt-2 max-w-4xl">
                    {{ review.body || '(No comments provided)' }}
                  </p>
                </div>
              </div>

              <!-- Action button -->
              <div class="shrink-0 self-start sm:self-center">
                <button
                  class="h-8 px-3.5 rounded-lg border border-border bg-card text-xs font-medium text-foreground hover:bg-muted/50 transition-colors shadow-sm"
                  @click="aiDraft(review)"
                >
                  Reply
                </button>
              </div>
            </div>

            <!-- Inline AI Reply workspace -->
            <div v-if="activeReview?.id === review.id" class="mt-4 border-t border-border pt-4 space-y-3">
              <label class="block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Compose Reply</label>
              <textarea
                v-model="replyBody"
                rows="3"
                class="w-full rounded-lg border border-border bg-background p-3 text-xs text-foreground shadow-sm focus:outline-none focus:ring-2 focus:ring-ring"
                :placeholder="drafting ? 'Drafting response via AI assistant...' : 'Write response here...'"
              />
              <div class="flex justify-between items-center flex-wrap gap-2">
                <span class="text-[11px] text-muted-foreground">AI drafted response can be edited before publishing.</span>
                <div class="flex gap-2">
                  <button
                    class="h-8 px-3 rounded-lg border border-border text-xs font-medium text-muted-foreground hover:bg-muted/50 transition-colors"
                    @click="activeReview = null"
                  >
                    Cancel
                  </button>
                  <button
                    class="h-8 px-3.5 rounded-lg bg-primary text-primary-foreground text-xs font-medium disabled:opacity-50 hover:bg-primary/90 transition-colors"
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

