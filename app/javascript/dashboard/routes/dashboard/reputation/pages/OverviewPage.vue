<script setup>
/* eslint-disable */
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { RelayButton as Button, RelayBadge as Badge } from 'dashboard/components-next/relay';
import {
  Star, TrendingUp, TrendingDown, MessageSquare, Bot,
  ArrowRight, MessageCircle, Link, Mail, StarHalf, Share2, Info, Trophy,
  CheckCircle, Plus, ThumbsUp, ChevronRight
} from 'lucide-vue-next';

import RequestReviewsModal from '../components/RequestReviewsModal.vue';
import ShareReportModal from '../components/ShareReportModal.vue';
import FeedbackBreakdownModal from '../components/FeedbackBreakdownModal.vue';
import { isReputationDemoSurfacesEnabled } from 'dashboard/featureFlags';

const axios = window.axios;
const router = useRouter();
const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;

const showDemoSurfaces = computed(() =>
  isReputationDemoSurfacesEnabled(
    accountId,
    window.__STORE__?.getters['accounts/isFeatureEnabledonAccount']
  )
);

const isShareModalOpen = ref(false);
const isRequestModalOpen = ref(false);
const isFeedbackModalOpen = ref(false);
const loading = ref(true);
const allReviews = ref([]);
const integrations = ref([]);
const summary = ref(null);
const aiData = ref(null); // { sentiment, insights:[{title,text}] } from /ai_insights, or null

const insightColors = ['bg-emerald-500', 'bg-amber-500', 'bg-primary'];
const aiIsMock = computed(() => !(aiData.value && aiData.value.insights && aiData.value.insights.length));
const insightsList = computed(() =>
  aiIsMock.value
    ? []
    : aiData.value.insights.map((it, i) => ({
        color: insightColors[i % insightColors.length],
        title: it.title,
        text: it.text,
      }))
);

const platformSvg = {
  google: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>',
  facebook: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>',
  yelp: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>',
  trustpilot: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>',
};

const avgRating = computed(() => {
  if (!allReviews.value.length) return 0;
  const sum = allReviews.value.reduce((s, r) => s + (r.rating || 0), 0);
  return +(sum / allReviews.value.length).toFixed(1);
});

const totalReviews = computed(() => allReviews.value.length);

const positiveCount = computed(() => allReviews.value.filter(r => (r.rating || 0) >= 4).length);
const positiveValue = computed(() =>
  totalReviews.value ? Math.round((positiveCount.value / totalReviews.value) * 100) : 0
);

const pendingCount = computed(() =>
  allReviews.value.filter(r => r.status === 'pending').length
);

const recentReviews = computed(() =>
  allReviews.value.slice(0, 3).map(r => ({
    id: r.id,
    author: r.reviewer_name || 'Anonymous',
    avatar: `https://i.pravatar.cc/150?u=review${r.id}`,
    platform: (r.provider || 'google').charAt(0).toUpperCase() + (r.provider || 'google').slice(1),
    rating: r.rating || 5,
    date: formatRelativeDate(r.reviewed_at),
    content: r.body || '',
  }))
);

const platforms = computed(() => {
  const grouped = {};
  allReviews.value.forEach(r => {
    const p = r.provider || 'google';
    if (!grouped[p]) grouped[p] = { ratings: [], count: 0 };
    grouped[p].ratings.push(r.rating || 0);
    grouped[p].count++;
  });
  const trends = {};
  (summary.value && summary.value.platforms ? summary.value.platforms : []).forEach(row => {
    trends[row.provider] = row.trend_pct;
  });
  return Object.entries(grouped).map(([provider, data]) => ({
    name: provider.charAt(0).toUpperCase() + provider.slice(1),
    provider,
    rating: +(data.ratings.reduce((s, v) => s + v, 0) / data.ratings.length).toFixed(1),
    total: data.count,
    trend: Object.prototype.hasOwnProperty.call(trends, provider) ? trends[provider] : null,
    svgIcon: platformSvg[provider] || platformSvg.google,
  }));
});

const trendBars = computed(() => {
  const now = new Date();
  const months = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push({ month: d.toLocaleString('en', { month: 'short' }), year: d.getFullYear(), m: d.getMonth() });
  }
  const counts = months.map(m => {
    const count = allReviews.value.filter(r => {
      if (!r.reviewed_at) return false;
      const rd = new Date(r.reviewed_at);
      return rd.getMonth() === m.m && rd.getFullYear() === m.year;
    }).length;
    return { month: m.month, count };
  });
  const maxCount = Math.max(...counts.map(c => c.count), 1);
  return counts.map(c => ({
    month: c.month,
    val1: c.count === 0 ? 0 : Math.round((c.count / maxCount) * 80) + 10,
  }));
});

const trendIsMock = computed(() => allReviews.value.length === 0);

const reputationScore = computed(() => (summary.value && summary.value.score != null) ? summary.value.score : 0);
const scoreDelta = computed(() => summary.value ? summary.value.score_delta : null);
const ratingDelta = computed(() => summary.value ? summary.value.rating_delta : null);
const reviewsDeltaPct = computed(() => summary.value ? summary.value.reviews_delta_pct : null);

function formatDelta(value, kind) {
  if (value == null || Number.isNaN(Number(value))) return "—";
  const n = Number(value);
  const sign = n > 0 ? "+" : "";
  if (kind === "pts") return sign + n + " pts";
  if (kind === "pct") return sign + (Number.isInteger(n) ? n : n.toFixed(1)) + "%";
  if (kind === "rating") return sign + n.toFixed(1);
  return sign + n;
}

function deltaClass(value) {
  if (value == null || value === 0) return "text-muted-foreground";
  return value > 0 ? "text-emerald-600" : "text-rose-600";
}

function formatRelativeDate(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  const weeks = Math.floor(days / 7);
  return `${weeks}w ago`;
}

async function loadData() {
  loading.value = true;
  try {
    const [reviewsRes, integrationsRes, summaryRes] = await Promise.all([
      axios.get(`${baseUrl()}/reviews`),
      axios.get(`${baseUrl()}/integrations`),
      axios.get(`${baseUrl()}/summary`).catch(() => ({ data: null })),
    ]);
    allReviews.value = reviewsRes.data || [];
    integrations.value = integrationsRes.data || [];
    summary.value = summaryRes.data || null;
  } catch (err) {
    console.error('Failed to load reputation data', err);
  } finally {
    loading.value = false;
  }
  axios
    .get(`${baseUrl()}/ai_insights`)
    .then(({ data }) => {
      aiData.value = data && data.insights ? data : null;
    })
    .catch(() => {
      aiData.value = null;
    });
}

onMounted(loadData);

const toastState = ref({ visible: false, message: '' });
let toastTimeout = null;

const showToast = (message) => {
  toastState.value.message = message;
  toastState.value.visible = true;
  if (toastTimeout) clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toastState.value.visible = false;
  }, 3000);
};

function handleShareReport() {
  isShareModalOpen.value = true;
}

function handleRequestReviews() {
  isRequestModalOpen.value = true;
}

const generatingReplies = ref(false);
function localDraft(review) {
  const name = (review.reviewer_name || 'there').split(' ')[0];
  if ((review.rating || 0) >= 4) {
    return `Hi ${name}, thank you for the kind review — we really appreciate you taking the time.`;
  }
  return `Hi ${name}, thank you for the feedback. We're sorry this wasn't up to standard and we'd like to make it right.`;
}
async function generateReviewReplies() {
  const pending = allReviews.value.filter(r =>
    r.status === 'pending' && !(r.reputation_review_reply && r.reputation_review_reply.body)
  );
  if (!pending.length) {
    showToast('No reviews need a reply');
    return;
  }
  generatingReplies.value = true;
  try {
    const batch = pending.slice(0, 5);
    await Promise.all(batch.map(async r => {
      let draft = '';
      try {
        const { data } = await axios.get(`${baseUrl()}/reviews/${r.id}/ai_draft`);
        draft = (data && data.draft) || '';
      } catch {
        draft = '';
      }
      await axios.post(`${baseUrl()}/reviews/${r.id}/reply`, { body: draft || localDraft(r) });
    }));
    showToast(`Drafted ${batch.length} review ${batch.length === 1 ? 'reply' : 'replies'}`);
    router.push({ name: 'reputation_reviews' });
  } catch (err) {
    showToast('Could not draft replies');
  } finally {
    generatingReplies.value = false;
  }
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full hide-scrollbar bg-background p-6 lg:p-8">
    <RequestReviewsModal v-model:open="isRequestModalOpen" />
    <ShareReportModal v-if="showDemoSurfaces" v-model:open="isShareModalOpen" />
    <FeedbackBreakdownModal v-model:open="isFeedbackModalOpen" :reviews="allReviews" :show-demo="showDemoSurfaces" />
    
    <div class="max-w-7xl mx-auto">
      <!-- Header matching AGENTS.md rule (h1 text-xl font-semibold text-foreground) -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 class="text-xl font-semibold text-foreground">Overview</h1>
          <p class="text-sm text-muted-foreground mt-1">Monitor and manage your brand's online presence across all platforms.</p>
        </div>
        <div class="flex items-center gap-3">
          <button v-if="showDemoSurfaces" @click="handleShareReport" class="h-9 gap-2 shadow-xs bg-card border border-border text-foreground hover:bg-muted text-[13px] font-semibold px-4 rounded-lg inline-flex items-center cursor-pointer">
            <Share2 class="size-4" />
            Share Report
          </button>
          <button @click="handleRequestReviews" class="h-9 gap-2 shadow-xs bg-primary hover:bg-primary/90 text-primary-foreground text-[13px] font-semibold px-4 rounded-lg inline-flex items-center cursor-pointer transition-colors">
            <Mail class="size-4" />
            Request Reviews
          </button>
        </div>
      </div>

      <div v-if="loading" class="flex flex-col items-center justify-center py-24 space-y-4">
        <div class="size-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        <p class="text-sm font-medium text-muted-foreground">Loading overview...</p>
      </div>

      <div v-else class="space-y-6">
      <!-- Section 1: Top Summary Metrics -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Reputation Score (real — /summary) -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-5 relative overflow-hidden group hover:border-primary/50 transition-colors">
          <div class="flex justify-between items-start mb-4">
            <div>
              <div class="flex items-center gap-2 mb-1">
                <p class="text-sm font-medium text-muted-foreground">Reputation Score</p>
              </div>
              <h3 class="text-3xl font-bold text-foreground">{{ reputationScore }}<span class="text-lg text-muted-foreground font-normal">/100</span></h3>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-xl text-primary">
              <Trophy class="size-5" />
            </div>
          </div>
          <div class="flex items-center text-sm font-medium gap-1" :class="deltaClass(scoreDelta)">
            <TrendingUp v-if="scoreDelta > 0" class="size-3.5" />
            <TrendingDown v-else-if="scoreDelta < 0" class="size-3.5" />
            <span>{{ formatDelta(scoreDelta, 'pts') }}</span>
            <span class="text-muted-foreground font-normal ml-1">from last month</span>
          </div>
        </div>

        <!-- Average Rating (Real) -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-5 relative overflow-hidden group hover:border-orange-500/50 transition-colors">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Average Rating</p>
              <div class="flex items-baseline gap-2">
                <h3 class="text-3xl font-bold text-foreground">{{ avgRating || '—' }}</h3>
                <div v-if="avgRating" class="flex gap-0.5 text-amber-400">
                  <Star v-for="i in Math.floor(avgRating)" :key="'full'+i" class="size-4 fill-amber-400 text-amber-400" />
                  <StarHalf v-if="avgRating % 1 >= 0.3" class="size-4 fill-amber-400 text-amber-400" />
                </div>
              </div>
            </div>
            <div class="p-2.5 bg-amber-50 text-amber-500 border border-amber-100 dark:bg-amber-900/30 dark:border-amber-800 dark:text-amber-400 rounded-xl">
              <Star class="size-5" />
            </div>
          </div>
          <div class="flex items-center text-sm font-medium gap-1" :class="deltaClass(ratingDelta)">
            <TrendingUp v-if="ratingDelta > 0" class="size-3.5" />
            <TrendingDown v-else-if="ratingDelta < 0" class="size-3.5" />
            <span>{{ formatDelta(ratingDelta, 'rating') }}</span>
            <span class="text-muted-foreground font-normal ml-1">from last month</span>
          </div>
        </div>

        <!-- Total Reviews (Real) -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-5 relative overflow-hidden group hover:border-primary/50 transition-colors">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Total Reviews</p>
              <h3 class="text-3xl font-bold text-foreground">{{ totalReviews.toLocaleString() }}</h3>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-xl text-primary">
              <MessageCircle class="size-5" />
            </div>
          </div>
          <div class="flex items-center text-sm font-medium gap-1" :class="deltaClass(reviewsDeltaPct)">
            <TrendingUp v-if="reviewsDeltaPct > 0" class="size-3.5" />
            <TrendingDown v-else-if="reviewsDeltaPct < 0" class="size-3.5" />
            <span>{{ formatDelta(reviewsDeltaPct, 'pct') }}</span>
            <span class="text-muted-foreground font-normal ml-1">vs last period</span>
          </div>
        </div>

        <!-- Overall Feedback (Real — positive share of reviews) -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-5 relative overflow-hidden group hover:border-primary/50 transition-colors cursor-pointer" @click="isFeedbackModalOpen = true">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Overall Feedback</p>
              <div class="flex items-baseline gap-1.5">
                <h3 class="text-3xl font-bold text-foreground">{{ totalReviews ? positiveValue + '%' : '—' }}</h3>
                <span v-if="totalReviews" class="text-base text-emerald-600 dark:text-emerald-400 font-semibold">Positive</span>
              </div>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-xl text-primary">
              <ThumbsUp class="size-5" />
            </div>
          </div>
          <div class="flex items-center justify-between text-sm font-medium text-muted-foreground gap-1">
            <span>{{ positiveCount.toLocaleString() }} of {{ totalReviews.toLocaleString() }} reviews</span>
            <span class="text-[11.5px] font-medium text-primary hover:underline flex items-center gap-0.5">
              View breakdown <ChevronRight class="size-3" />
            </span>
          </div>
        </div>
      </div>

      <!-- Section 2: Charts & Insights -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Review Trend (Left - 2/3 width) — real when reviews exist -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-6 flex flex-col justify-between lg:col-span-2">
          <div class="flex justify-between items-center mb-6">
            <div class="flex items-center gap-2">
              <div>
                <h3 class="text-base font-semibold text-foreground">Review Trend</h3>
                <p class="text-sm text-muted-foreground mt-0.5">Volume of new reviews over the last 7 months</p>
              </div>
              <span v-if="showDemoSurfaces && trendIsMock" class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — connect a review platform to see real data">Demo</span>
            </div>
            <div class="inline-flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-medium text-muted-foreground shrink-0">
              Last 7 Months
            </div>
          </div>

          <div class="h-[220px] w-full flex items-end justify-between gap-3 pt-6 px-2">
            <div v-for="(bar, idx) in trendBars" :key="idx" class="flex-1 flex flex-col items-center gap-2 group cursor-pointer">
              <div class="w-full h-[170px] relative flex items-end">
                <div class="w-full bg-primary group-hover:bg-primary/90 rounded-t-md transition-all" :style="{ height: `${bar.val1}%` }"></div>
              </div>
              <span class="text-xs font-medium text-muted-foreground group-hover:text-foreground transition-colors">{{ bar.month }}</span>
            </div>
          </div>
        </div>

        <div class="bg-card rounded-2xl border border-border shadow-xs p-0 flex flex-col overflow-hidden relative">
          <div class="h-1 w-full bg-primary"></div>

          <div class="p-6 flex-1 flex flex-col">
            <div class="flex items-center gap-2 mb-5">
              <div class="p-1.5 bg-primary/10 text-primary rounded-lg">
                <Bot class="size-4" />
              </div>
              <h3 class="text-base font-semibold text-foreground">Relay AI Insights</h3>
            </div>

            <div v-if="insightsList.length" class="space-y-4 flex-1">
              <div v-for="(insight, idx) in insightsList" :key="idx" class="flex gap-3 items-start p-2 rounded-lg hover:bg-muted/40 transition-colors">
                <div class="mt-1 size-2 rounded-full shrink-0" :class="insight.color"></div>
                <div>
                  <p class="text-sm font-medium text-foreground">{{ insight.title }}</p>
                  <p class="text-xs text-muted-foreground mt-0.5">{{ insight.text }}</p>
                </div>
              </div>
            </div>
            <p v-else class="flex-1 text-sm text-muted-foreground">Insights appear after reviews sync.</p>

            <button
              :disabled="generatingReplies"
              class="w-full mt-6 h-9 text-xs font-semibold gap-2 bg-primary/10 text-primary hover:bg-primary/20 rounded-lg inline-flex items-center justify-center cursor-pointer transition-colors disabled:opacity-50"
              @click="generateReviewReplies"
            >
              <Bot class="size-4" /> {{ generatingReplies ? 'Drafting replies…' : 'Generate Review Replies' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Section 3: Platform Ratings & Quick Actions -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Platform Breakdown (Real from reviews; trend from snapshots) -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-6">
          <div class="flex items-center gap-2 mb-6">
            <h3 class="text-base font-semibold text-foreground">Platform Breakdown</h3>
            <Info class="size-4 text-muted-foreground opacity-70" />
          </div>

          <div v-if="platforms.length" class="w-full">
            <div class="grid grid-cols-12 gap-2 text-xs font-medium text-muted-foreground mb-4">
              <div class="col-span-3">Platform</div>
              <div class="col-span-3 text-center">Rating</div>
              <div class="col-span-3 text-center">Reviews</div>
              <div class="col-span-3 text-center">Trend</div>
            </div>

            <div class="space-y-4">
              <div v-for="platform in platforms" :key="platform.name" class="grid grid-cols-12 gap-2 items-center text-sm py-1 border-b border-border/40 last:border-0">
                <div class="col-span-3 flex items-center gap-2.5">
                  <div v-html="platform.svgIcon" class="shrink-0 flex items-center justify-center"></div>
                  <span class="font-bold text-foreground text-[13.5px]">{{ platform.name }}</span>
                </div>

                <div class="col-span-3 flex items-center justify-center gap-1.5">
                  <span class="font-bold text-foreground">{{ platform.rating }}</span>
                  <div class="flex gap-0.5 text-amber-400">
                    <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= Math.round(platform.rating) ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'" />
                  </div>
                </div>

                <div class="col-span-3 text-center text-muted-foreground font-medium text-xs">
                  {{ platform.total }}
                </div>

                <div class="col-span-3 text-center font-medium text-xs" :class="deltaClass(platform.trend)">
                  {{ formatDelta(platform.trend, 'pct') }}
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-sm text-muted-foreground text-center py-4">
            No platforms connected yet.
          </div>

          <div class="mt-6 pt-2">
            <router-link :to="{ name: 'reputation_reviews' }" class="text-xs font-semibold text-primary flex items-center gap-1 hover:underline">
              View all platforms <ArrowRight class="size-3.5" />
            </router-link>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="bg-card rounded-2xl border border-border shadow-xs p-6">
          <h3 class="text-base font-semibold text-foreground mb-1">Quick Actions</h3>
          <p class="text-sm text-muted-foreground mb-6">Manage your reputation workflow.</p>
          
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <router-link :to="{ name: 'reputation_requests' }" class="flex items-center gap-3 p-4 border border-border rounded-xl hover:bg-muted/50 transition-colors text-left group">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <Mail class="size-5" />
              </div>
              <div>
                <p class="font-bold text-xs text-foreground">Request Reviews</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">Send email/SMS</p>
              </div>
            </router-link>

            <router-link :to="{ name: 'reputation_reviews' }" class="flex items-center gap-3 p-4 border border-border rounded-xl hover:bg-muted/50 transition-colors text-left group">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <MessageSquare class="size-5" />
              </div>
              <div>
                <p class="font-bold text-xs text-foreground">Respond to Feedback</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">{{ pendingCount }} pending items</p>
              </div>
            </router-link>

            <router-link :to="{ name: 'reputation_automation' }" class="flex items-center gap-3 p-4 border border-border rounded-xl hover:bg-muted/50 transition-colors text-left group">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <Bot class="size-5" />
              </div>
              <div>
                <p class="font-bold text-xs text-foreground">Automate Replies</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">Configure AI settings</p>
              </div>
            </router-link>

            <router-link :to="{ name: 'reputation_settings' }" class="flex items-center gap-3 p-4 border border-border rounded-xl hover:bg-muted/50 transition-colors text-left group">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <Link class="size-5" />
              </div>
              <div>
                <p class="font-bold text-xs text-foreground">Connect Platform</p>
                <p class="text-[11px] text-muted-foreground mt-0.5">Add new integration</p>
              </div>
            </router-link>
          </div>
        </div>
      </div>

      <!-- Section 4: Recent Reviews (Real) -->
      <div class="bg-card rounded-2xl border border-border shadow-xs overflow-hidden mb-8">
        <div class="p-6 border-b border-border flex justify-between items-center bg-muted/20">
          <div>
            <h3 class="text-base font-semibold text-foreground">Recent Reviews</h3>
            <p class="text-sm text-muted-foreground mt-0.5">Latest customer feedback across platforms.</p>
          </div>
          <router-link :to="{ name: 'reputation_reviews' }" class="text-xs font-semibold gap-1 text-primary hover:underline flex items-center">
            View All <ArrowRight class="size-3.5" />
          </router-link>
        </div>

        <div v-if="recentReviews.length === 0" class="p-12 text-center text-muted-foreground text-sm">No reviews yet. Connect a platform to get started.</div>
        <div v-else class="divide-y divide-border">
          <div v-for="review in recentReviews" :key="review.id" class="p-6 hover:bg-muted/30 transition-colors flex flex-col sm:flex-row gap-5">
            <div class="shrink-0">
              <img :src="review.avatar" alt="Avatar" class="size-10 rounded-full border border-border" />
            </div>

            <div class="flex-1">
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-2 mb-2">
                <div>
                  <h4 class="font-bold text-[14.5px] text-foreground">{{ review.author }}</h4>
                  <div class="flex items-center gap-2 mt-1">
                    <div class="flex gap-0.5 text-amber-400">
                      <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= review.rating ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'" />
                    </div>
                    <span class="text-xs text-muted-foreground flex items-center gap-1">
                      on <span class="font-bold text-foreground">{{ review.platform }}</span> • {{ review.date }}
                    </span>
                  </div>
                </div>
                <router-link :to="{ name: 'reputation_reviews' }" class="h-8 gap-1.5 text-xs font-semibold px-3 bg-card border border-border rounded-lg text-foreground hover:bg-muted inline-flex items-center cursor-pointer">
                  <MessageSquare class="size-3.5" />
                  Reply
                </router-link>
              </div>
              <p class="text-[13.5px] text-muted-foreground leading-relaxed">{{ review.content }}</p>
            </div>
          </div>
        </div>
      </div>
      </div>

    </div>
  </div>

  <!-- Custom Toast Notification -->
  <div 
    class="fixed bottom-6 right-6 z-50 bg-foreground text-background px-4 py-3 rounded-xl shadow-2xl font-medium text-xs transition-all duration-300 transform flex items-center gap-2"
    :class="toastState.visible ? 'translate-y-0 opacity-100' : 'translate-y-4 opacity-0 pointer-events-none'"
  >
    <CheckCircle class="size-4 text-emerald-400" />
    {{ toastState.message }}
  </div>
</template>

