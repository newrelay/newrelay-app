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

onMounted(loadWidgets);

// Filter mock reviews for preview
const previewReviewsList = computed(() => {
  if (!activeWidget.value) return [];
  return mockReviews.filter(r => r.rating >= activeWidget.value.min_rating);
});
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- eslint-disable -->
    <!-- Header (List Mode) -->
    <div v-if="!isEditing" class="flex items-center justify-between">
      <div>
        <h2
          class="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight"
        >
          Review Widgets
        </h2>
        <p class="text-xs text-slate-400 mt-0.5">
          Embed customer ratings directly onto your landing pages
        </p>
      </div>
      <button
        class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
        @click="createWidget"
      >
        <svg
          class="size-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 4v16m8-8H4"
          />
        </svg>
        New Widget
      </button>
    </div>

    <div
      v-if="loading"
      class="flex flex-col items-center justify-center py-20 space-y-4"
    >
      <div
        class="size-10 border-4 border-woot-500 border-t-transparent rounded-full animate-spin"
      />
      <p class="text-sm font-medium text-slate-500 dark:text-slate-400">
        Loading widgets list...
      </p>
    </div>

    <!-- Empty State -->
    <div
      v-else-if="widgets.length === 0"
      class="flex flex-col items-center justify-center py-20 bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 rounded-2xl"
    >
      <div
        class="p-3.5 rounded-full bg-slate-100 dark:bg-slate-850 text-slate-400"
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
      <h3 class="font-extrabold text-slate-800 dark:text-slate-200 mt-4">
        No widgets defined
      </h3>
      <p class="text-xs text-slate-400 mt-1 max-w-sm text-center">
        Generate an embeddable badge or review list to showcase your positive
        reviews.
      </p>
    </div>

    <!-- Widgets List View -->
    <div v-if="!loading && !isEditing && widgets.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="w in widgets" 
        :key="w.id"
        class="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 rounded-2xl shadow-sm hover:shadow-md transition-all p-5 flex flex-col space-y-4 cursor-pointer group"
        @click="activeWidget = { ...w }; isEditing = true;"
      >
        <div class="flex items-start justify-between">
          <div>
            <h3 class="font-extrabold text-slate-800 dark:text-slate-100 text-sm group-hover:text-woot-500 transition-colors">{{ w.name }}</h3>
            <p class="text-[10px] text-slate-400 font-normal mt-0.5 capitalize">{{ w.style }} Widget</p>
          </div>
          <span 
            class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider"
            :class="w.active ? 'bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600' : 'bg-slate-100 dark:bg-slate-800 text-slate-500'"
          >
            {{ w.active ? 'Active' : 'Inactive' }}
          </span>
        </div>

        <div class="flex items-center gap-4 text-xs font-medium text-slate-500 pt-2 border-t border-slate-100 dark:border-slate-800/80">
          <div class="flex items-center gap-1.5">
            <span class="text-yellow-400 text-sm">★</span>
            <span>{{ w.min_rating }}+ Stars only</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Workspace (Edit Mode) -->
    <div v-if="isEditing" class="space-y-6">
      <!-- Edit Mode Header -->
      <div class="flex items-center gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-4">
        <button 
          class="p-2 -ml-2 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 transition-colors"
          @click="isEditing = false; activeWidget = null;"
        >
          <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <div>
          <h2 class="text-xl font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
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
          class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-4"
        >
          <div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-sm">
              Widget Configuration
            </h3>
            <p class="text-[10px] text-slate-450 mt-0.5">
              Configure style parameters for {{ activeWidget.name }}
            </p>
          </div>

          <div class="space-y-4">
            <div class="space-y-1.5">
              <label class="block text-xs font-bold text-slate-450">Widget Name</label>
              <input
                v-model="activeWidget.name"
                type="text"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
              />
            </div>

            <div class="space-y-1.5">
              <label class="block text-xs font-bold text-slate-450">Display Style</label>
              <select
                v-model="activeWidget.style"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
              >
                <option value="carousel">Carousel (Responsive Slider)</option>
                <option value="grid">Grid (Columns layout)</option>
              </select>
            </div>

            <div class="space-y-1.5">
              <label class="block text-xs font-bold text-slate-450">Minimum Rating threshold</label>
              <select
                v-model="activeWidget.min_rating"
                class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
              >
                <option :value="5">5 Stars only</option>
                <option :value="4">4 Stars & Above</option>
                <option :value="3">3 Stars & Above</option>
                <option :value="1">All Ratings (1-5 Stars)</option>
              </select>
            </div>

            <div class="flex items-center justify-between py-2">
              <span class="text-xs font-bold text-slate-450">Widget Active State</span>
              <button
                type="button"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full p-0.5 transition-colors duration-200 ease-in-out focus:outline-none"
                :class="
                  activeWidget.active
                    ? 'bg-woot-500'
                    : 'bg-slate-200 dark:bg-slate-700'
                "
                @click="activeWidget.active = !activeWidget.active"
              >
                <span
                  class="pointer-events-none inline-block size-5 transform rounded-full bg-white shadow transition-transform duration-200 ease-in-out"
                  :class="
                    activeWidget.active ? 'translate-x-5' : 'translate-x-0'
                  "
                />
              </button>
            </div>

            <div class="flex items-center justify-between py-2">
              <span class="text-xs font-bold text-slate-450">Hide NewRelay watermark</span>
              <button
                type="button"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full p-0.5 transition-colors duration-200 ease-in-out focus:outline-none"
                :class="
                  activeWidget.hide_watermark
                    ? 'bg-woot-500'
                    : 'bg-slate-200 dark:bg-slate-700'
                "
                @click="
                  activeWidget.hide_watermark = !activeWidget.hide_watermark
                "
              >
                <span
                  class="pointer-events-none inline-block size-5 transform rounded-full bg-white shadow transition-transform duration-200 ease-in-out"
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
            class="flex justify-between items-center pt-4 border-t border-slate-100 dark:border-slate-850"
          >
            <button
              class="text-xs text-red-500 dark:text-red-400 font-bold hover:underline"
              @click="deleteWidget(activeWidget.id)"
            >
              Delete Widget
            </button>

            <button
              class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-all"
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
          class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-6"
        >
          <div class="flex items-center justify-between">
            <div>
              <h3 class="font-extrabold text-slate-900 dark:text-white text-sm">
                Interactive Live Preview
              </h3>
              <p class="text-[10px] text-slate-450 mt-0.5">
                Simulated rendering of widget on web page
              </p>
            </div>
            <span
              class="px-2 py-0.5 rounded-lg text-[10px] uppercase font-bold bg-slate-100 dark:bg-slate-800 text-slate-500"
            >
              Live Mockup
            </span>
          </div>

          <!-- Carousel widget style mockup -->
          <div
            v-if="activeWidget.style === 'carousel'"
            class="relative p-6 bg-slate-50 dark:bg-slate-850/40 rounded-2xl border border-slate-150 dark:border-slate-800 min-h-[160px] flex flex-col justify-between"
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
                  <span class="text-[10px] text-slate-400">{{
                    previewReviewsList[carouselIndex].date
                  }}</span>
                </div>
                <p
                  class="text-xs text-slate-650 dark:text-slate-300 italic leading-relaxed"
                >
                  "{{ previewReviewsList[carouselIndex].body }}"
                </p>
                <div class="flex items-center gap-1.5 pt-1">
                  <span
                    class="text-xs font-bold text-slate-800 dark:text-slate-200"
                  >
                    {{ previewReviewsList[carouselIndex].reviewer_name }}
                  </span>
                  <span class="size-1 bg-slate-300 rounded-full" />
                  <span
                    class="text-[9px] uppercase font-bold px-2 py-0.5 bg-slate-100 dark:bg-slate-800 text-slate-400 rounded-full capitalize"
                  >
                    {{ previewReviewsList[carouselIndex].provider }}
                  </span>
                </div>
              </div>

              <!-- Carousel nav items -->
              <div
                class="flex justify-between items-center pt-2 border-t border-slate-100 dark:border-slate-800/80"
              >
                <div class="flex gap-1">
                  <span
                    v-for="(s, idx) in previewReviewsList"
                    :key="idx"
                    class="size-1.5 rounded-full transition-all"
                    :class="
                      carouselIndex === idx
                        ? 'bg-woot-500 w-3.5'
                        : 'bg-slate-300'
                    "
                  />
                </div>
                <div class="flex gap-1.5">
                  <button
                    class="p-1 rounded-lg border border-slate-200 dark:border-slate-750 hover:bg-white dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 shrink-0 shadow-sm"
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
                    class="p-1 rounded-lg border border-slate-200 dark:border-slate-750 hover:bg-white dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 shrink-0 shadow-sm"
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
                class="text-center pt-2 text-[10px] text-slate-400 border-t border-slate-100 dark:border-slate-800/80"
              >
                Powered by
                <span class="font-bold text-slate-650 dark:text-slate-350">NewRelay</span>
              </div>
            </div>
            <div v-else class="text-xs text-slate-400 text-center py-10">
              No mockup reviews matching min {{ activeWidget.min_rating }}★
              filter.
            </div>
          </div>

          <!-- Grid widget style mockup -->
          <div
            v-else-if="activeWidget.style === 'grid'"
            class="p-4 bg-slate-50 dark:bg-slate-850/40 rounded-2xl border border-slate-150 dark:border-slate-800 space-y-4"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div
                v-for="r in previewReviewsList.slice(0, 4)"
                :key="r.id"
                class="p-4 bg-white dark:bg-slate-900 border border-slate-150 dark:border-slate-800/80 rounded-xl space-y-2 shadow-sm"
              >
                <div class="flex items-center justify-between">
                  <div class="flex gap-0.5 text-yellow-400">
                    <span v-for="n in 5" :key="n" class="text-[10px]">
                      {{ n <= r.rating ? '★' : '☆' }}
                    </span>
                  </div>
                  <span class="text-[10px] text-slate-400">{{ r.date }}</span>
                </div>
                <p
                  class="text-[11px] text-slate-600 dark:text-slate-350 italic line-clamp-3"
                >
                  "{{ r.body }}"
                </p>
                <div class="flex items-center gap-1.5">
                  <span
                    class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate"
                  >
                    {{ r.reviewer_name }}
                  </span>
                  <span
                    class="text-[9px] font-bold text-slate-400 uppercase shrink-0 capitalize"
                  >
                    {{ r.provider }}
                  </span>
                </div>
              </div>
            </div>
            <!-- Watermark -->
            <div
              v-if="!activeWidget.hide_watermark"
              class="text-center pt-2 text-[10px] text-slate-400 border-t border-slate-100 dark:border-slate-800/80"
            >
              Powered by
              <span class="font-bold text-slate-650 dark:text-slate-350">NewRelay</span>
            </div>
            <div
              v-if="previewReviewsList.length === 0"
              class="text-xs text-slate-400 text-center py-10"
            >
              No mockup reviews matching min {{ activeWidget.min_rating }}★
              filter.
            </div>
          </div>
        </div>

        <!-- HTML Code Embed Block -->
        <div
          class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm p-6 space-y-4"
        >
          <div>
            <h3 class="font-extrabold text-slate-900 dark:text-white text-sm">
              HTML Embed Script
            </h3>
            <p class="text-[10px] text-slate-450 mt-0.5">
              Copy and paste this script tag into your website body where you
              want ratings to display
            </p>
          </div>

          <div
            class="relative bg-slate-950 text-slate-300 font-mono text-xs rounded-xl p-4 border border-slate-900 break-all select-all"
          >
            {{ embedCode(activeWidget) }}
          </div>

          <div class="flex justify-end pt-1">
            <button
              class="px-4 py-2 rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
              :class="
                copiedId === activeWidget.id
                  ? 'bg-emerald-500 text-white'
                  : 'bg-woot-50 hover:bg-woot-100 text-woot-650 dark:bg-slate-800 dark:hover:bg-slate-750 dark:text-woot-400'
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
