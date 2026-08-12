<script setup>
/* eslint-disable */
import { ref, onMounted, computed } from 'vue';
const axios = window.axios;

const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id || 
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const reviews = ref([]);
const templates = ref([]);
const loading = ref(true);
const activeReview = ref(null);
const replyBody = ref('');
const drafting = ref(false);

// Search and Filter States
const searchQuery = ref('');
const statusFilter = ref('all');
const providerFilter = ref('all');
const ratingFilter = ref('all'); // all, positive (4-5), neutral (3), negative (1-2)

async function loadData() {
  loading.value = true;
  try {
    const [revRes, tempRes] = await Promise.all([
      axios.get(`/api/v1/accounts/${accountId}/reputation/reviews`),
      axios.get(`/api/v1/accounts/${accountId}/reputation/templates`).catch(() => ({ data: [] }))
    ]);
    reviews.value = revRes.data;
    templates.value = tempRes.data;
  } catch (err) {
    console.error('Failed to load reviews data', err);
  } finally {
    loading.value = false;
  }
}

async function aiDraft(review) {
  drafting.value = true;
  activeReview.value = review;
  replyBody.value = '';
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/ai_draft`);
    // Simple typewriter effect simulation for premium feel
    let fullText = data.draft;
    let currentIdx = 0;
    const interval = setInterval(() => {
      if (currentIdx < fullText.length) {
        replyBody.value += fullText[currentIdx];
        currentIdx++;
      } else {
        clearInterval(interval);
      }
    }, 15);
  } catch (err) {
    replyBody.value = 'Failed to generate AI reply. Please write your reply manually.';
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
    loadData();
  } catch (err) {
    alert('Failed to publish reply');
  }
}

async function ignoreReview(review) {
  try {
    await axios.patch(`/api/v1/accounts/${accountId}/reputation/reviews/${review.id}/ignore`);
    review.status = 'ignored';
    loadData();
  } catch (err) {
    alert('Failed to ignore review');
  }
}

function applyTemplate(body) {
  replyBody.value = body;
}

onMounted(loadData);

// Sentiment classification
const getSentiment = rating => {
  if (rating >= 4) return { label: 'Positive', color: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/20 dark:text-emerald-450 border border-emerald-200/50 dark:border-emerald-900/30' };
  if (rating === 3) return { label: 'Neutral', color: 'bg-amber-50 text-amber-700 dark:bg-amber-950/20 dark:text-amber-450 border border-amber-200/50 dark:border-amber-900/30' };
  return { label: 'Negative', color: 'bg-rose-50 text-rose-700 dark:bg-rose-950/20 dark:text-rose-450 border border-rose-200/50 dark:border-rose-900/30' };
};

const getAvatarBg = name => {
  const code = (name || 'Anonymous').charCodeAt(0);
  const colors = [
    'bg-indigo-500/10 text-indigo-600 dark:text-indigo-400',
    'bg-rose-500/10 text-rose-600 dark:text-rose-400',
    'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
    'bg-amber-500/10 text-amber-600 dark:text-amber-400',
    'bg-sky-500/10 text-sky-600 dark:text-sky-400'
  ];
  return colors[code % colors.length];
};

// Filtered reviews
const filteredReviews = computed(() => {
  return reviews.value.filter(r => {
    // Search query
    const text = (r.body || '').toLowerCase();
    const reviewer = (r.reviewer_name || '').toLowerCase();
    const matchSearch = text.includes(searchQuery.value.toLowerCase()) || reviewer.includes(searchQuery.value.toLowerCase());

    // Status
    const matchStatus = statusFilter.value === 'all' || r.status === statusFilter.value;

    // Provider
    const matchProvider = providerFilter.value === 'all' || r.provider === providerFilter.value;

    // Rating
    let matchRating = true;
    if (ratingFilter.value === 'positive') matchRating = r.rating >= 4;
    else if (ratingFilter.value === 'neutral') matchRating = r.rating === 3;
    else if (ratingFilter.value === 'negative') matchRating = r.rating <= 2;

    return matchSearch && matchStatus && matchProvider && matchRating;
  });
});
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- eslint-disable -->
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h2 class="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Customer Reviews</h2>
        <p class="text-xs text-slate-400 mt-0.5">Read, filter, and respond to incoming reviews</p>
      </div>
    </div>

    <!-- Filter Toolbar -->
    <div class="p-4 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <!-- Search -->
        <div class="relative">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search comment or reviewer..."
            class="w-full pl-9 pr-4 py-2 text-xs rounded-xl border border-slate-200 dark:border-slate-800 dark:bg-slate-850 focus:outline-none focus:ring-2 focus:ring-woot-500"
          />
          <span class="absolute left-3 top-2.5 text-slate-400">
            <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
          </span>
        </div>

        <!-- Rating Filter -->
        <select
          v-model="ratingFilter"
          class="px-3 py-2 text-xs rounded-xl border border-slate-200 dark:border-slate-800 dark:bg-slate-850 focus:outline-none focus:ring-2 focus:ring-woot-500"
        >
          <option value="all">All Ratings</option>
          <option value="positive">Positive (4-5 ★)</option>
          <option value="neutral">Neutral (3 ★)</option>
          <option value="negative">Negative (1-2 ★)</option>
        </select>

        <!-- Status Filter -->
        <select
          v-model="statusFilter"
          class="px-3 py-2 text-xs rounded-xl border border-slate-200 dark:border-slate-800 dark:bg-slate-850 focus:outline-none focus:ring-2 focus:ring-woot-500"
        >
          <option value="all">All Statuses</option>
          <option value="pending">Pending Reply</option>
          <option value="replied">Replied</option>
          <option value="ignored">Ignored</option>
        </select>

        <!-- Provider Filter -->
        <select
          v-model="providerFilter"
          class="px-3 py-2 text-xs rounded-xl border border-slate-200 dark:border-slate-800 dark:bg-slate-850 focus:outline-none focus:ring-2 focus:ring-woot-500"
        >
          <option value="all">All Platforms</option>
          <option value="google">Google</option>
          <option value="facebook">Facebook</option>
        </select>
      </div>
    </div>

    <!-- Reviews Grid -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-20 space-y-4">
      <div class="size-10 border-4 border-woot-500 border-t-transparent rounded-full animate-spin"></div>
      <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Loading reviews feed...</p>
    </div>

    <div v-else-if="filteredReviews.length === 0" class="flex flex-col items-center justify-center py-20 bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 rounded-2xl">
      <div class="p-3.5 rounded-full bg-slate-100 dark:bg-slate-850 text-slate-400">
        <svg class="size-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0a2 2 0 01-2 2H6a2 2 0 01-2-2m16 0V9a2 2 0 00-2-2H6a2 2 0 00-2 2v2m16 4h-2a2 2 0 00-2 2v3a2 2 0 01-2 2H6a2 2 0 01-2-2v-3a2 2 0 00-2-2H4" /></svg>
      </div>
      <h3 class="font-extrabold text-slate-800 dark:text-slate-200 mt-4">No reviews found</h3>
      <p class="text-xs text-slate-400 mt-1 max-w-sm text-center">Try adjusting your filters or search terms to find specific ratings.</p>
    </div>

    <div v-else class="space-y-4">
      <div
        v-for="review in filteredReviews"
        :key="review.id"
        class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 p-6 shadow-sm flex flex-col gap-5 transition-all"
      >
        <!-- Reviewer Details Header -->
        <div class="flex items-start justify-between gap-4">
          <div class="flex items-center gap-3">
            <!-- Initials Avatar -->
            <div 
              class="size-10 rounded-full font-bold text-xs uppercase flex items-center justify-center shrink-0 shadow-sm"
              :class="getAvatarBg(review.reviewer_name)"
            >
              {{ (review.reviewer_name || 'A').substring(0, 2) }}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h4 class="font-bold text-sm text-slate-850 dark:text-slate-200">{{ review.reviewer_name }}</h4>
                <!-- sentiment tag -->
                <span class="px-2 py-0.5 text-[9px] font-bold rounded-full uppercase" :class="getSentiment(review.rating).color">
                  {{ getSentiment(review.rating).label }}
                </span>
              </div>
              <div class="flex items-center gap-1.5 text-xs text-slate-400 mt-0.5">
                <span class="capitalize font-semibold text-woot-600 dark:text-woot-450">{{ review.provider }}</span>
                <span>·</span>
                <span>{{ new Date(review.reviewed_at).toLocaleDateString() }}</span>
              </div>
            </div>
          </div>

          <!-- Status badge & action buttons -->
          <div class="flex items-center gap-2 shrink-0">
            <span
              class="text-[10px] uppercase tracking-wider font-extrabold px-2.5 py-0.5 rounded-full"
              :class="{
                'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/20 dark:text-emerald-400': review.status === 'replied',
                'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400': review.status === 'ignored',
                'bg-amber-50 text-amber-700 dark:bg-amber-950/20 dark:text-amber-450': review.status === 'pending'
              }"
            >
              {{ review.status }}
            </span>
          </div>
        </div>

        <!-- Rating & Body -->
        <div class="space-y-2">
          <div class="flex gap-0.5 text-yellow-400">
            <span v-for="n in 5" :key="n" class="text-base">
              {{ n <= review.rating ? '★' : '☆' }}
            </span>
          </div>
          <p class="text-slate-700 dark:text-slate-300 text-sm leading-relaxed whitespace-pre-line font-medium">
            {{ review.body || '(No comments provided)' }}
          </p>
        </div>

        <!-- Reply Trigger Actions if Pending -->
        <div v-if="review.status === 'pending' && activeReview?.id !== review.id" class="flex gap-2 justify-end border-t border-slate-100 dark:border-slate-850 pt-4">
          <button
            class="px-3.5 py-1.5 rounded-xl border border-slate-200 dark:border-slate-700 text-xs font-bold text-slate-600 dark:text-slate-350 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
            @click="ignoreReview(review)"
          >
            Ignore review
          </button>
          <button
            class="px-3.5 py-1.5 rounded-xl bg-gradient-to-tr from-woot-600 to-indigo-500 hover:from-woot-700 hover:to-indigo-600 text-white text-xs font-bold shadow-sm transition-colors flex items-center gap-1.5"
            @click="aiDraft(review)"
          >
            <svg class="size-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
            Draft reply with AI
          </button>
        </div>

        <!-- Reply Editing workspace -->
        <div v-if="activeReview?.id === review.id" class="border-t border-slate-100 dark:border-slate-850 pt-5 space-y-4">
          <div class="flex items-center justify-between">
            <label class="text-xs font-bold text-slate-400 uppercase tracking-wider">Reply Composer</label>
            <!-- Quick templates select -->
            <div v-if="templates.length > 0" class="flex items-center gap-2">
              <span class="text-xs text-slate-400">Templates:</span>
              <select
                class="px-2 py-1 text-xs rounded-lg border border-slate-200 dark:border-slate-800 dark:bg-slate-850"
                @change="applyTemplate($event.target.value)"
              >
                <option value="">Choose standard reply...</option>
                <option v-for="t in templates" :key="t.id" :value="t.body">{{ t.name }}</option>
              </select>
            </div>
          </div>

          <textarea
            v-model="replyBody"
            rows="3"
            class="w-full text-sm rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 p-3.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
            :placeholder="drafting ? 'Generating AI suggestion...' : 'Type response details...'"
          />

          <div class="flex justify-between items-center flex-wrap gap-2">
            <span class="text-[11px] text-slate-400">
              Character count: <strong class="text-slate-600 dark:text-slate-350">{{ replyBody.length }}</strong>
            </span>
            <div class="flex gap-2">
              <button
                class="px-3.5 py-1.5 text-xs font-bold text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-800"
                @click="activeReview = null"
              >
                Cancel
              </button>
              <button
                class="px-4 py-1.5 text-xs font-bold bg-woot-500 hover:bg-woot-600 text-white rounded-xl transition-colors"
                :disabled="!replyBody || drafting"
                @click="submitReply(review)"
              >
                Publish response
              </button>
            </div>
          </div>
        </div>

        <!-- Existing reply timeline -->
        <div v-else-if="review.reputation_review_reply" class="bg-slate-50 dark:bg-slate-850/50 rounded-xl p-4 border border-slate-100 dark:border-slate-800/80 space-y-2">
          <div class="flex items-center gap-1.5 text-[11px] text-slate-400 font-bold uppercase tracking-wider">
            <svg class="size-3.5 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            Your response
            <span v-if="review.reputation_review_reply.published_at" class="normal-case font-normal text-slate-400">
              · published {{ new Date(review.reputation_review_reply.published_at).toLocaleDateString() }}
            </span>
          </div>
          <p class="text-sm text-slate-650 dark:text-slate-300 leading-relaxed italic">
            "{{ review.reputation_review_reply.body }}"
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
