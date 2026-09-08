<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, onMounted, computed } from 'vue';
const axios = window.axios;

const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const widgets = ref([]);
const activeWidget = ref(null);
const loading = ref(true);
const saving = ref(false);
const isEditing = ref(false);
const copiedId = ref(null);

// Carousel slide index
const carouselIndex = ref(0);

// ponytail: mock reviews used directly for interactive preview, avoiding network load
const mockReviews = [
  {
    id: 1,
    rating: 5,
    reviewer_name: 'Sarah Connor',
    body: 'Absolutely fantastic service! The team was super helpful and resolved my query in minutes.',
    provider: 'google',
    date: '2 days ago',
  },
  {
    id: 2,
    rating: 5,
    reviewer_name: 'David Miller',
    body: 'Best customer experience I have ever had. Recommending to all my peers.',
    provider: 'facebook',
    date: '3 days ago',
  },
  {
    id: 3,
    rating: 4,
    reviewer_name: 'Elena Rostova',
    body: 'Great product and very neat onboarding. Had a minor delay but the support team handled it perfectly.',
    provider: 'google',
    date: '1 week ago',
  },
  {
    id: 4,
    rating: 4,
    reviewer_name: 'John Doe',
    body: 'Really solid tool. Very happy with the responses so far.',
    provider: 'facebook',
    date: '2 weeks ago',
  },
  {
    id: 5,
    rating: 5,
    reviewer_name: 'Marcus Aurelius',
    body: 'An exceptional framework that works seamlessly.',
    provider: 'google',
    date: '3 weeks ago',
  },
];

const baseUrl = () => `/api/v1/accounts/${accountId}/reputation/widgets`;

async function loadWidgets() {
  loading.value = true;
  try {
    const { data } = await axios.get(baseUrl());
    widgets.value = data;
    // Don't auto-set activeWidget here anymore since we start in list mode
  } catch (err) {
    console.error('Failed to load widgets', err);
  } finally {
    loading.value = false;
  }
}

async function createWidget() {
  try {
    const { data } = await axios.post(baseUrl(), {
      widget: {
        name: 'My New Widget',
        style: 'carousel',
        min_rating: 4,
        hide_watermark: false,
      },
    });
    widgets.value.unshift(data);
    activeWidget.value = { ...data };
    isEditing.value = true;
  } catch (err) {
    alert('Failed to create widget');
  }
}

async function saveWidget() {
  if (!activeWidget.value) return;
  saving.value = true;
  try {
    const { data } = await axios.patch(
      `${baseUrl()}/${activeWidget.value.id}`,
      {
        widget: {
          name: activeWidget.value.name,
          style: activeWidget.value.style,
          min_rating: activeWidget.value.min_rating,
          active: activeWidget.value.active,
          hide_watermark: activeWidget.value.hide_watermark,
        },
      }
    );
    const index = widgets.value.findIndex(w => w.id === activeWidget.value.id);
    if (index !== -1) {
      widgets.value[index] = data;
    }
  } catch (err) {
    alert('Failed to save widget configs');
  } finally {
    saving.value = false;
  }
}

async function deleteWidget(id) {
  if (!confirm('Are you sure you want to delete this widget?')) return;
  try {
    await axios.delete(`${baseUrl()}/${id}`);
    widgets.value = widgets.value.filter(w => w.id !== id);
    activeWidget.value = null;
    isEditing.value = false;
  } catch (err) {
    alert('Failed to delete widget');
  }
}

function embedCode(widget) {
  if (!widget) return '';
  return `<script src="${window.location.origin}/reputation/widget.js" data-token="${widget.token}"><\/script>`;
}

function copyEmbed(widget) {
  navigator.clipboard.writeText(embedCode(widget));
  copiedId.value = widget.id;
  setTimeout(() => {
    copiedId.value = null;
  }, 2000);
}

// Carousel Navigation
const prevSlide = max => {
  if (carouselIndex.value > 0) {
    carouselIndex.value--;
  } else {
    carouselIndex.value = max - 1;
  }
};

const nextSlide = max => {
  if (carouselIndex.value < max - 1) {
    carouselIndex.value++;
  } else {
    carouselIndex.value = 0;
  }
};

// Real reviews power the widget preview; fall back to sample data only when
// the account has no reviews yet (badged "Sample").
const realReviews = ref([]);
function relTime(dateStr) {
  if (!dateStr) return '';
  const days = Math.floor((Date.now() - new Date(dateStr).getTime()) / 86400000);
  if (days <= 0) return 'Today';
  if (days === 1) return '1 day ago';
  if (days < 7) return `${days} days ago`;
  const weeks = Math.floor(days / 7);
  return weeks === 1 ? '1 week ago' : `${weeks} weeks ago`;
}
async function loadReviews() {
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/reputation/reviews`);
    realReviews.value = (data || []).map(r => ({
      id: r.id,
      rating: r.rating || 0,
      reviewer_name: r.reviewer_name || r.author_name || 'Customer',
      body: r.body || r.content || '',
      provider: r.provider || 'google',
      date: relTime(r.reviewed_at),
    }));
  } catch (err) {
    realReviews.value = [];
  }
}

onMounted(() => {
  loadWidgets();
  loadReviews();
});

const previewIsMock = computed(() => realReviews.value.length === 0);

// Filter reviews for preview — real when available, else sample data.
const previewReviewsList = computed(() => {
  if (!activeWidget.value) return [];
  const source = previewIsMock.value ? mockReviews : realReviews.value;
  return source.filter(r => r.rating >= activeWidget.value.min_rating);
});
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- eslint-disable -->
    <!-- Header (List Mode) -->
    <div v-if="!isEditing" class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-base font-semibold tracking-tight text-foreground">Review Widgets</h1>
        <p class="text-xs text-muted-foreground mt-0.5">Embed customer ratings directly onto your landing pages.</p>
      </div>
      <button
        class="inline-flex items-center gap-2 rounded-lg bg-primary px-3.5 py-2 text-xs font-semibold text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors"
        @click="createWidget"
      >
        <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
        New Widget
      </button>
    </div>

    <div
      v-if="loading"
      class="flex flex-col items-center justify-center py-20 space-y-4"
    >
      <div
        class="size-10 border-4 border-primary border-t-transparent rounded-full animate-spin"
      />
      <p class="text-sm font-medium text-muted-foreground">
        Loading widgets list...
      </p>
    </div>

    <!-- Empty State -->
    <div
      v-else-if="widgets.length === 0"
      class="flex flex-col items-center justify-center py-20 bg-card border border-border rounded-xl shadow-sm"
    >
      <div
        class="p-3.5 rounded-full bg-muted text-muted-foreground"
      >
        <svg
          class="size-7"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6z"
          />
        </svg>
      </div>
      <h3 class="text-[20px] font-[600] text-foreground mt-4">
        No widgets defined
      </h3>
      <p class="text-[13.5px] text-muted-foreground mt-1 max-w-sm text-center leading-relaxed mb-4">
        Generate an embeddable badge or review list to showcase your positive reviews.
      </p>
      <button @click="createWidget" class="px-4 py-2 rounded-lg border border-border bg-card text-[13.5px] font-medium text-foreground hover:bg-muted transition-colors border-input hover:border-transparent cursor-pointer">
        + Create First Widget
      </button>
    </div>

    <!-- Widgets List View -->
    <div v-if="!loading && !isEditing && widgets.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="w in widgets" 
        :key="w.id"
        class="bg-card border border-border rounded-xl shadow-sm hover:border-primary/40 transition-all p-5 flex flex-col space-y-4 cursor-pointer group"
        @click="activeWidget = { ...w }; isEditing = true;"
      >
        <div class="flex items-start justify-between">
          <div>
            <h3 class="font-semibold text-foreground text-sm group-hover:text-primary transition-colors">{{ w.name }}</h3>
            <p class="text-[11px] text-muted-foreground font-normal mt-0.5 capitalize">{{ w.style }} Widget</p>
          </div>
          <span 
            class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
            :class="w.active ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400' : 'bg-muted text-muted-foreground'"
          >
            {{ w.active ? 'Active' : 'Inactive' }}
          </span>
        </div>

        <div class="flex items-center gap-4 text-xs font-medium text-muted-foreground pt-2 border-t border-border">
          <div class="flex items-center gap-1.5">
            <span class="text-amber-500 text-sm">★</span>
            <span>{{ w.min_rating }}+ Stars only</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Workspace (Edit Mode) -->
    <div v-if="isEditing" class="space-y-6">
      <!-- Edit Mode Header -->
      <div class="flex items-center gap-4 border-b border-border/60 pb-4">
        <button 
          class="p-2 -ml-2 rounded-xl hover:bg-muted text-muted-foreground transition-colors"
          @click="isEditing = false; activeWidget = null;"
        >
          <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <div>
          <h2 class="text-xl font-bold text-foreground tracking-tight flex items-center gap-2">
            Edit {{ activeWidget?.name || 'Widget' }}
          </h2>
        </div>
      </div>

      <div class="grid lg:grid-cols-12 gap-8 items-start">
        <!-- Configurator column -->
        <div class="lg:col-span-5 space-y-6">
          <!-- Customizer Config Card -->
        <div
          v-if="activeWidget"
          class="bg-card rounded-2xl border border-border/80 shadow-sm p-6 space-y-4"
        >
          <div>
            <h3 class="font-semibold text-foreground text-sm">
              Widget Configuration
            </h3>
            <p class="text-[10px] text-muted-foreground mt-0.5">
              Configure style parameters for {{ activeWidget.name }}
            </p>
          </div>

          <div class="space-y-4">
            <div class="space-y-1.5">
              <label class="block text-muted-foreground text-[13.5px] font-[500] text-foreground">Widget Name</label>
              <input
                v-model="activeWidget.name"
                type="text"
                class="w-full rounded-xl border border-border p-3 focus:outline-none focus:ring-2 focus:ring-primary text-[14px] border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 shadow-sm rounded-md"
              />
            </div>

            <div class="space-y-1.5">
              <label class="block text-muted-foreground text-[13.5px] font-[500] text-foreground">Display Style</label>
              <select
                v-model="activeWidget.style"
                class="w-full text-xs rounded-xl border border-border p-3 focus:outline-none focus:ring-2 focus:ring-primary"
              >
                <option value="carousel">Carousel (Responsive Slider)</option>
                <option value="grid">Grid (Columns layout)</option>
              </select>
            </div>

            <div class="space-y-1.5">
              <label class="block text-muted-foreground text-[13.5px] font-[500] text-foreground">Minimum Rating threshold</label>
              <select
                v-model="activeWidget.min_rating"
                class="w-full text-xs rounded-xl border border-border p-3 focus:outline-none focus:ring-2 focus:ring-primary"
              >
                <option :value="5">5 Stars only</option>
                <option :value="4">4 Stars & Above</option>
                <option :value="3">3 Stars & Above</option>
                <option :value="1">All Ratings (1-5 Stars)</option>
              </select>
            </div>

            <div class="flex items-center justify-between py-2">
              <span class="text-xs font-bold text-muted-foreground">Widget Active State</span>
              <button
                type="button"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full p-0.5 transition-colors duration-200 ease-in-out focus:outline-none"
                :class="
                  activeWidget.active
                    ? 'bg-primary'
                    : 'bg-muted '
                "
                @click="activeWidget.active = !activeWidget.active"
              >
                <span
                  class="pointer-events-none inline-block size-5 transform rounded-full bg-card shadow transition-transform duration-200 ease-in-out"
                  :class="
                    activeWidget.active ? 'translate-x-5' : 'translate-x-0'
                  "
                />
              </button>
            </div>

            <div class="flex items-center justify-between py-2">
              <span class="text-xs font-bold text-muted-foreground">Hide NewRelay watermark</span>
              <button
                type="button"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full p-0.5 transition-colors duration-200 ease-in-out focus:outline-none"
                :class="
                  activeWidget.hide_watermark
                    ? 'bg-primary'
                    : 'bg-muted '
                "
                @click="
                  activeWidget.hide_watermark = !activeWidget.hide_watermark
                "
              >
                <span
                  class="pointer-events-none inline-block size-5 transform rounded-full bg-card shadow transition-transform duration-200 ease-in-out"
                  :class="
                    activeWidget.hide_watermark
                      ? 'translate-x-5'
                      : 'translate-x-0'
                  "
                />
              </button>
            </div>
          </div>

          <div
            class="flex justify-between items-center pt-4 border-t border-border "
          >
            <button
              class="text-xs text-destructive font-bold hover:underline"
              @click="deleteWidget(activeWidget.id)"
            >
              Delete Widget
            </button>

            <button
              class="px-4 py-2 bg-card hover:bg-muted text-white rounded-xl text-xs font-bold transition-all"
              :disabled="saving"
              @click="saveWidget"
            >
              {{ saving ? 'Saving...' : 'Save Settings' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Preview column -->
      <div v-if="activeWidget" class="lg:col-span-7 space-y-6">
        <!-- Live Mock Preview -->
        <div
          class="bg-card rounded-2xl border border-border/80 shadow-sm p-6 space-y-6"
        >
          <div class="flex items-center justify-between">
            <div>
              <h3 class="font-semibold text-foreground text-sm">
                Interactive Live Preview
              </h3>
              <p class="text-[10px] text-muted-foreground mt-0.5">
                Simulated rendering of widget on web page
              </p>
            </div>
            <span
              v-if="previewIsMock"
              class="px-2 py-0.5 rounded-lg text-[10px] uppercase font-bold bg-amber-500/15 text-amber-600 dark:text-amber-400"
              title="No reviews yet — showing sample data"
            >
              Sample Data
            </span>
            <span
              v-else
              class="px-2 py-0.5 rounded-lg text-[10px] uppercase font-bold bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
            >
              Your Reviews
            </span>
          </div>

          <!-- Carousel widget style mockup -->
          <div
            v-if="activeWidget.style === 'carousel'"
            class="relative p-6 bg-background rounded-2xl border border-border min-h-[160px] flex flex-col justify-between"
          >
            <div v-if="previewReviewsList.length > 0" class="space-y-4">
              <!-- Carousel Content card -->
              <div class="space-y-2 select-none animate-fade">
                <div class="flex items-center justify-between">
                  <div class="flex gap-0.5 text-yellow-400">
                    <span v-for="n in 5" :key="n" class="text-sm">
                      {{
                        n <= previewReviewsList[carouselIndex].rating
                          ? '★'
                          : '☆'
                      }}
                    </span>
                  </div>
                  <span class="text-[10px] text-muted-foreground">{{
                    previewReviewsList[carouselIndex].date
                  }}</span>
                </div>
                <p
                  class="text-xs text-muted-foreground italic leading-relaxed"
                >
                  "{{ previewReviewsList[carouselIndex].body }}"
                </p>
                <div class="flex items-center gap-1.5 pt-1">
                  <span
                    class="text-xs font-bold text-foreground "
                  >
                    {{ previewReviewsList[carouselIndex].reviewer_name }}
                  </span>
                  <span class="size-1 bg-muted rounded-full" />
                  <span
                    class="text-[9px] uppercase font-bold px-2 py-0.5 bg-muted text-muted-foreground rounded-full capitalize"
                  >
                    {{ previewReviewsList[carouselIndex].provider }}
                  </span>
                </div>
              </div>

              <!-- Carousel nav items -->
              <div
                class="flex justify-between items-center pt-2 border-t border-border "
              >
                <div class="flex gap-1">
                  <span
                    v-for="(s, idx) in previewReviewsList"
                    :key="idx"
                    class="size-1.5 rounded-full transition-all"
                    :class="
                      carouselIndex === idx
                        ? 'bg-primary w-3.5'
                        : 'bg-muted'
                    "
                  />
                </div>
                <div class="flex gap-1.5">
                  <button
                    class="p-1 rounded-lg border border-border hover:bg-muted text-muted-foreground dark:text-muted-foreground shrink-0 shadow-sm"
                    @click="prevSlide(previewReviewsList.length)"
                  >
                    <svg
                      class="size-4.5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 19l-7-7 7-7"
                      />
                    </svg>
                  </button>
                  <button
                    class="p-1 rounded-lg border border-border hover:bg-muted text-muted-foreground dark:text-muted-foreground shrink-0 shadow-sm"
                    @click="nextSlide(previewReviewsList.length)"
                  >
                    <svg
                      class="size-4.5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </button>
                </div>
              </div>
              <!-- Watermark -->
              <div
                v-if="!activeWidget.hide_watermark"
                class="text-center pt-2 text-[10px] text-muted-foreground border-t border-border "
              >
                Powered by
                <span class="font-bold text-muted-foreground ">NewRelay</span>
              </div>
            </div>
            <div v-else class="text-xs text-muted-foreground text-center py-10">
              No reviews matching min {{ activeWidget.min_rating }}★
              filter.
            </div>
          </div>

          <!-- Grid widget style mockup -->
          <div
            v-else-if="activeWidget.style === 'grid'"
            class="p-4 bg-background rounded-2xl border border-border space-y-4"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div
                v-for="r in previewReviewsList.slice(0, 4)"
                :key="r.id"
                class="p-4 bg-card border border-border rounded-xl space-y-2 shadow-sm"
              >
                <div class="flex items-center justify-between">
                  <div class="flex gap-0.5 text-yellow-400">
                    <span v-for="n in 5" :key="n" class="text-[10px]">
                      {{ n <= r.rating ? '★' : '☆' }}
                    </span>
                  </div>
                  <span class="text-[10px] text-muted-foreground">{{ r.date }}</span>
                </div>
                <p
                  class="text-[11px] text-muted-foreground italic line-clamp-3"
                >
                  "{{ r.body }}"
                </p>
                <div class="flex items-center gap-1.5">
                  <span
                    class="text-xs font-bold text-foreground truncate"
                  >
                    {{ r.reviewer_name }}
                  </span>
                  <span
                    class="text-[9px] font-bold text-muted-foreground uppercase shrink-0 capitalize"
                  >
                    {{ r.provider }}
                  </span>
                </div>
              </div>
            </div>
            <!-- Watermark -->
            <div
              v-if="!activeWidget.hide_watermark"
              class="text-center pt-2 text-[10px] text-muted-foreground border-t border-border "
            >
              Powered by
              <span class="font-bold text-muted-foreground ">NewRelay</span>
            </div>
            <div
              v-if="previewReviewsList.length === 0"
              class="text-xs text-muted-foreground text-center py-10"
            >
              No reviews matching min {{ activeWidget.min_rating }}★
              filter.
            </div>
          </div>
        </div>

        <!-- HTML Code Embed Block -->
        <div
          class="bg-card rounded-2xl border border-border/80 shadow-sm p-6 space-y-4"
        >
          <div>
            <h3 class="font-semibold text-foreground text-sm">
              HTML Embed Script
            </h3>
            <p class="text-[10px] text-muted-foreground mt-0.5">
              Copy and paste this script tag into your website body where you
              want ratings to display
            </p>
          </div>

          <div
            class="relative bg-card text-muted-foreground font-mono text-xs rounded-xl p-4 border border-border break-all select-all"
          >
            {{ embedCode(activeWidget) }}
          </div>

          <div class="flex justify-end pt-1">
            <button
              class="px-4 py-2 rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
              :class="
                copiedId === activeWidget.id
                  ? 'bg-success text-success-foreground'
                  : 'bg-primary/10 hover:bg-primary/10 text-primary '
              "
              @click="copyEmbed(activeWidget)"
            >
              <svg
                v-if="copiedId === activeWidget.id"
                class="size-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="3"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M5 13l4 4L19 7"
                />
              </svg>
              {{
                copiedId === activeWidget.id
                  ? 'Copied script!'
                  : 'Copy code snippet'
              }}
            </button>
          </div>
        </div>
      </div>
      </div>
    </div>
  </div>
</template>
