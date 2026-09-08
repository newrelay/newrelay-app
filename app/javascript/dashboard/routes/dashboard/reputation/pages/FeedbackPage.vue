<script setup>
/* eslint-disable */
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { isReputationDemoSurfacesEnabled } from 'dashboard/featureFlags';
import { RelayInput } from 'dashboard/components-next/relay';
import {
  Search,
  Star,
  Inbox,
  Mail,
  MessageSquare,
  ShieldAlert,
  X,
} from 'lucide-vue-next';

const router = useRouter();
const axios = window.axios;
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;

const showDemoSurfaces = computed(() =>
  isReputationDemoSurfacesEnabled(
    accountId,
    window.__STORE__?.getters['accounts/isFeatureEnabledonAccount']
  )
);

onMounted(() => {
  if (!showDemoSurfaces.value) {
    router.replace({ name: 'reputation_overview' });
    return;
  }
  loadFeedback();
});

const mock = {
  submissions: [
    {
      id: 'mock-1',
      rating: 1,
      body: 'Waited 40 minutes and nobody followed up after the appointment.',
      reviewer_name: 'Anita Sharma',
      created_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      reputation_review_request: { id: 11, channel: 'email', status: 'completed' },
    },
    {
      id: 'mock-2',
      rating: 2,
      body: 'Staff were polite but the quote was much higher than promised.',
      reviewer_name: 'Rahul Mehta',
      created_at: new Date(Date.now() - 26 * 60 * 60 * 1000).toISOString(),
      reputation_review_request: { id: 12, channel: 'sms', status: 'completed' },
    },
    {
      id: 'mock-3',
      rating: 3,
      body: 'Okay overall. Parking was a mess and the waiting area felt cramped.',
      reviewer_name: 'Priya Nair',
      created_at: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
      reputation_review_request: { id: 13, channel: 'email', status: 'completed' },
    },
  ],
};

const loading = ref(true);
const usingMock = ref(false);
const items = ref([]);
const searchQuery = ref('');
const ratingFilter = ref('all');
const selected = ref(null);

function formatRelativeDate(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${Math.max(mins, 1)}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return `${Math.floor(days / 7)}w ago`;
}

function mapItem(row) {
  const request = row.reputation_review_request || {};
  const name = row.reviewer_name || 'Anonymous';
  return {
    id: row.id,
    rating: Number(row.rating) || 0,
    body: row.body || '',
    reviewerName: name,
    initials: name
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map(part => part[0].toUpperCase())
      .join(''),
    date: formatRelativeDate(row.created_at),
    channel: request.channel || 'email',
    requestId: request.id || null,
  };
}

async function loadFeedback() {
  loading.value = true;
  usingMock.value = false;
  try {
    const { data } = await axios.get(`${baseUrl()}/feedback`);
    const rows = Array.isArray(data) ? data : [];
    if (rows.length) {
      items.value = rows.map(mapItem);
    } else {
      usingMock.value = true;
      items.value = mock.submissions.map(mapItem);
    }
  } catch (err) {
    console.error('Failed to load feedback', err);
    usingMock.value = true;
    items.value = mock.submissions.map(mapItem);
  } finally {
    loading.value = false;
  }
}

const filtered = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  return items.value.filter(item => {
    if (ratingFilter.value !== 'all' && item.rating !== Number(ratingFilter.value)) {
      return false;
    }
    if (!q) return true;
    return (
      item.reviewerName.toLowerCase().includes(q) ||
      item.body.toLowerCase().includes(q)
    );
  });
});

const stats = computed(() => {
  const list = items.value;
  return {
    total: list.length,
    one: list.filter(i => i.rating === 1).length,
    two: list.filter(i => i.rating === 2).length,
    three: list.filter(i => i.rating === 3).length,
  };
});

function ratingLabel(rating) {
  if (rating === 1) return '1 star';
  return `${rating} stars`;
}
</script>

<template>
  <div class="relative flex h-full w-full overflow-hidden bg-background">
    <div
      class="flex-1 overflow-y-auto flex flex-col transition-all duration-300"
      :class="selected ? 'mr-[380px]' : ''"
    >
      <div class="px-6 lg:px-10 py-6 bg-card shrink-0">
        <div class="flex items-center text-sm text-muted-foreground mb-2">
          <span>Reputation</span><span class="mx-2">/</span>
          <span class="text-foreground">Feedback</span>
        </div>
        <h1 class="text-base font-medium text-foreground flex items-center gap-2">
          Feedback
          <span
            v-if="usingMock"
            class="rounded bg-warning/10 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-warning"
            title="Demo — sample intercepts until real 1–3 star submissions arrive"
          >Demo</span>
        </h1>
        <p class="text-sm text-muted-foreground mt-1">
          1–3 star ratings from review-request links stay private. They never post to Google.
        </p>
      </div>

      <div class="px-6 lg:px-10 py-6 space-y-6">
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="rounded-xl border border-border bg-card p-4">
            <div class="flex items-center gap-2 text-muted-foreground text-xs font-medium uppercase tracking-wide">
              <Inbox class="size-3.5" /> Total
            </div>
            <p class="mt-2 text-2xl font-semibold text-foreground">{{ stats.total }}</p>
            <p class="text-xs text-muted-foreground mt-1">Private intercepts</p>
          </div>
          <div class="rounded-xl border border-border bg-card p-4">
            <div class="flex items-center gap-2 text-destructive text-xs font-medium uppercase tracking-wide">
              <ShieldAlert class="size-3.5" /> 1 star
            </div>
            <p class="mt-2 text-2xl font-semibold text-foreground">{{ stats.one }}</p>
          </div>
          <div class="rounded-xl border border-border bg-card p-4">
            <div class="flex items-center gap-2 text-warning text-xs font-medium uppercase tracking-wide">
              <Star class="size-3.5" /> 2 stars
            </div>
            <p class="mt-2 text-2xl font-semibold text-foreground">{{ stats.two }}</p>
          </div>
          <div class="rounded-xl border border-border bg-card p-4">
            <div class="flex items-center gap-2 text-warning text-xs font-medium uppercase tracking-wide">
              <Star class="size-3.5" /> 3 stars
            </div>
            <p class="mt-2 text-2xl font-semibold text-foreground">{{ stats.three }}</p>
          </div>
        </div>

        <div class="flex flex-col sm:flex-row sm:items-center gap-3">
          <div class="relative flex-1 max-w-sm">
            <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <RelayInput
              v-model="searchQuery"
              type="text"
              placeholder="Search feedback..."
              class-name="pl-9 h-9"
            />
          </div>
          <div class="flex items-center gap-1.5">
            <button
              v-for="opt in [
                { id: 'all', label: 'All' },
                { id: '1', label: '1' },
                { id: '2', label: '2' },
                { id: '3', label: '3' },
              ]"
              :key="opt.id"
              class="h-9 px-3 rounded-lg border text-sm font-medium transition-colors"
              :class="
                ratingFilter === opt.id
                  ? 'bg-primary text-primary-foreground border-primary'
                  : 'bg-card text-foreground border-border hover:bg-muted'
              "
              @click="ratingFilter = opt.id"
            >
              {{ opt.label }}
            </button>
          </div>
        </div>

        <div v-if="loading" class="rounded-xl border border-border bg-card p-10 text-center text-sm text-muted-foreground">
          Loading private feedback...
        </div>

        <div
          v-else-if="!filtered.length"
          class="rounded-xl border border-dashed border-border bg-card p-10 text-center"
        >
          <Inbox class="size-8 mx-auto text-muted-foreground mb-3" />
          <p class="text-sm font-medium text-foreground">No private feedback yet</p>
          <p class="text-sm text-muted-foreground mt-1 max-w-md mx-auto">
            When a customer rates 1-3 stars on a review request, it lands here instead of going public.
          </p>
        </div>

        <div v-else class="rounded-xl border border-border bg-card divide-y divide-border">
          <button
            v-for="item in filtered"
            :key="item.id"
            type="button"
            class="w-full text-left px-4 py-4 hover:bg-muted/50 transition-colors flex gap-3"
            :class="selected && selected.id === item.id ? 'bg-muted/60' : ''"
            @click="selected = item"
          >
            <div class="size-10 shrink-0 rounded-full bg-primary/10 text-primary flex items-center justify-center text-xs font-semibold">
              {{ item.initials }}
            </div>
            <div class="min-w-0 flex-1">
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm font-medium text-foreground truncate">{{ item.reviewerName }}</p>
                <span class="text-xs text-muted-foreground shrink-0">{{ item.date }}</span>
              </div>
              <div class="flex items-center gap-2 mt-0.5">
                <span class="inline-flex items-center gap-0.5">
                  <Star
                    v-for="n in 3"
                    :key="n"
                    class="size-3.5"
                    :class="n <= item.rating ? 'fill-warning text-warning' : 'text-muted-foreground/30'"
                  />
                </span>
                <span class="text-[11px] uppercase tracking-wide text-muted-foreground">{{ item.channel }}</span>
              </div>
              <p class="text-sm text-muted-foreground mt-1 line-clamp-2">{{ item.body }}</p>
            </div>
          </button>
        </div>
      </div>
    </div>

    <aside
      v-if="selected"
      class="absolute right-0 top-0 h-full w-[380px] border-l border-border bg-card flex flex-col"
    >
      <div class="px-5 py-4 border-b border-border flex items-center justify-between">
        <h2 class="text-sm font-medium text-foreground">Private intercept</h2>
        <button
          type="button"
          class="size-8 inline-flex items-center justify-center rounded-md hover:bg-muted text-muted-foreground"
          @click="selected = null"
        >
          <X class="size-4" />
        </button>
      </div>
      <div class="flex-1 overflow-y-auto p-5 space-y-5">
        <div>
          <p class="text-base font-medium text-foreground">{{ selected.reviewerName }}</p>
          <p class="text-xs text-muted-foreground mt-1">{{ ratingLabel(selected.rating) }} · {{ selected.date }}</p>
        </div>
        <div class="flex items-center gap-3 text-sm text-muted-foreground">
          <span class="inline-flex items-center gap-1.5">
            <Mail v-if="selected.channel === 'email'" class="size-3.5" />
            <MessageSquare v-else class="size-3.5" />
            {{ selected.channel }}
          </span>
          <span v-if="selected.requestId">Request #{{ selected.requestId }}</span>
        </div>
        <p class="text-sm text-foreground leading-relaxed whitespace-pre-wrap">{{ selected.body || 'No comment left.' }}</p>
        <div class="rounded-lg border border-warning/20 bg-warning/10 px-3 py-2 text-xs text-warning">
          This rating was intercepted privately. It was not posted to a public review site.
        </div>
      </div>
    </aside>
  </div>
</template>
