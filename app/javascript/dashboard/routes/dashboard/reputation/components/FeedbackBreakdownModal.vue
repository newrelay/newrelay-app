<script setup>
/* eslint-disable */
import { computed } from 'vue';
import { X, ThumbsUp, Smile, Frown, Meh, CheckCircle2, Globe } from 'lucide-vue-next';
import { RelayButton as Button } from 'dashboard/components-next/relay';

const props = defineProps({
  open: { type: Boolean, default: false },
  reviews: { type: Array, default: () => [] },
  showDemo: { type: Boolean, default: false },
});

const emit = defineEmits(['update:open']);

const total = computed(() => props.reviews.length);
const positive = computed(() => props.reviews.filter(r => (r.rating || 0) >= 4).length);
const neutral = computed(() => props.reviews.filter(r => (r.rating || 0) === 3).length);
const negative = computed(() => props.reviews.filter(r => (r.rating || 0) > 0 && (r.rating || 0) <= 2).length);

const pct = n => (total.value ? Math.round((n / total.value) * 100) : 0);

const platforms = computed(() => {
  const grouped = {};
  props.reviews.forEach(r => {
    const p = r.provider || 'other';
    if (!grouped[p]) grouped[p] = { ratings: [], positive: 0 };
    grouped[p].ratings.push(r.rating || 0);
    if ((r.rating || 0) >= 4) grouped[p].positive++;
  });
  return Object.entries(grouped).map(([provider, d]) => ({
    name: provider.charAt(0).toUpperCase() + provider.slice(1),
    count: d.ratings.length,
    rating: (d.ratings.reduce((s, v) => s + v, 0) / d.ratings.length).toFixed(1),
    positivePercent: Math.round((d.positive / d.ratings.length) * 100),
  })).sort((a, b) => b.count - a.count);
});

// Demo-only: topic/theme analysis needs an NLP backend we don't have yet.
const positiveDrivers = [
  { topic: 'Staff Friendliness & Professionalism', score: 98 },
  { topic: 'Speed of Service & Support', score: 94 },
  { topic: 'Quality of Care / Experience', score: 96 },
  { topic: 'Transparent & Fair Pricing', score: 91 },
];
const improvementTopics = [
  { topic: 'Phone & Check-in Wait Times', mentions: 28 },
  { topic: 'Weekend Appointment Availability', mentions: 16 },
];

function close() {
  emit('update:open', false);
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <div class="absolute inset-0 bg-background/80 backdrop-blur-[8px]" @click="close"></div>

    <div class="relative w-full max-w-2xl max-h-[90vh] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden">
      <!-- Header -->
      <div class="px-6 py-4 border-b border-border flex items-center justify-between bg-muted/30 shrink-0">
        <div class="flex items-center gap-3">
          <div class="p-2 bg-primary/10 rounded-lg text-primary">
            <ThumbsUp class="size-5" />
          </div>
          <div>
            <h2 class="text-base font-semibold text-foreground">Overall Customer Feedback</h2>
            <p class="text-[12.5px] text-muted-foreground mt-0.5">Aggregated sentiment across all channels.</p>
          </div>
        </div>
        <Button variant="ghost" size="icon" class="text-muted-foreground border border-border hover:border-transparent" @click="close">
          <X class="size-5" />
        </Button>
      </div>

      <!-- Body -->
      <div class="flex-1 overflow-y-auto p-6 space-y-6">
        <div v-if="total === 0" class="py-12 text-center text-sm text-muted-foreground">
          No reviews yet — feedback breakdown appears once reviews arrive.
        </div>

        <template v-else>
          <!-- Sentiment Summary -->
          <div class="grid grid-cols-3 gap-3">
            <div class="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-center">
              <div class="flex items-center justify-center gap-1 text-emerald-600 dark:text-emerald-400 mb-1">
                <Smile class="size-4" />
                <span class="text-xs font-semibold uppercase tracking-wider">Positive</span>
              </div>
              <div class="text-2xl font-bold text-foreground">{{ pct(positive) }}%</div>
              <div class="text-[11px] text-muted-foreground mt-0.5">{{ positive.toLocaleString() }} reviews</div>
            </div>
            <div class="p-4 rounded-xl bg-amber-500/10 border border-amber-500/20 text-center">
              <div class="flex items-center justify-center gap-1 text-amber-600 dark:text-amber-400 mb-1">
                <Meh class="size-4" />
                <span class="text-xs font-semibold uppercase tracking-wider">Neutral</span>
              </div>
              <div class="text-2xl font-bold text-foreground">{{ pct(neutral) }}%</div>
              <div class="text-[11px] text-muted-foreground mt-0.5">{{ neutral.toLocaleString() }} reviews</div>
            </div>
            <div class="p-4 rounded-xl bg-destructive/10 border border-destructive/20 text-center">
              <div class="flex items-center justify-center gap-1 text-destructive mb-1">
                <Frown class="size-4" />
                <span class="text-xs font-semibold uppercase tracking-wider">Negative</span>
              </div>
              <div class="text-2xl font-bold text-foreground">{{ pct(negative) }}%</div>
              <div class="text-[11px] text-muted-foreground mt-0.5">{{ negative.toLocaleString() }} reviews</div>
            </div>
          </div>

          <!-- Sentiment Bar -->
          <div class="space-y-1.5">
            <div class="flex items-center justify-between text-xs text-muted-foreground">
              <span>Overall Sentiment Ratio</span>
              <span class="font-medium text-foreground">{{ total.toLocaleString() }} Total Ratings</span>
            </div>
            <div class="h-3 w-full bg-muted rounded-full overflow-hidden flex gap-0.5 p-0.5">
              <div class="bg-success rounded-l-full h-full" :style="{ width: pct(positive) + '%' }"></div>
              <div class="bg-amber-400 h-full" :style="{ width: pct(neutral) + '%' }"></div>
              <div class="bg-destructive rounded-r-full h-full" :style="{ width: pct(negative) + '%' }"></div>
            </div>
          </div>

          <!-- Platform Breakdown -->
          <div class="space-y-3 pt-2 border-t border-border">
            <h3 class="text-sm font-semibold text-foreground">Feedback by Platform</h3>
            <div class="space-y-2.5">
              <div v-for="platform in platforms" :key="platform.name" class="p-3 bg-muted/30 border border-border rounded-xl flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="p-2 bg-card rounded-lg border border-border text-foreground">
                    <Globe class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="font-medium text-sm text-foreground">{{ platform.name }}</div>
                    <div class="text-xs text-muted-foreground">{{ platform.count }} reviews · {{ platform.rating }} ★ avg</div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-sm font-semibold text-emerald-600 dark:text-emerald-400">{{ platform.positivePercent }}% Positive</div>
                  <div class="text-[11px] text-muted-foreground">Positive Sentiment</div>
                </div>
              </div>
            </div>
          </div>

          <!-- Feedback Themes (Demo — needs topic analysis backend) -->
          <div v-if="showDemo" class="space-y-3 pt-2 border-t border-border">
            <div class="flex items-center gap-2">
              <h3 class="text-sm font-semibold text-foreground">Top Customer Feedback Themes</h3>
              <span class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400">Demo</span>
            </div>
            <div class="space-y-2">
              <div class="text-xs font-medium text-muted-foreground uppercase tracking-wider">High-Performing Themes</div>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <div v-for="item in positiveDrivers" :key="item.topic" class="p-2.5 rounded-lg bg-emerald-500/5 border border-emerald-500/15 flex items-center justify-between text-xs">
                  <div class="flex items-center gap-2">
                    <CheckCircle2 class="size-3.5 text-emerald-500 shrink-0" />
                    <span class="font-medium text-foreground truncate">{{ item.topic }}</span>
                  </div>
                  <span class="text-emerald-600 dark:text-emerald-400 font-semibold shrink-0">{{ item.score }}%</span>
                </div>
              </div>
            </div>
            <div class="space-y-2 pt-2">
              <div class="text-xs font-medium text-muted-foreground uppercase tracking-wider">Improvement Areas</div>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <div v-for="item in improvementTopics" :key="item.topic" class="p-2.5 rounded-lg bg-amber-500/5 border border-amber-500/15 flex items-center justify-between text-xs">
                  <div class="flex items-center gap-2">
                    <span class="size-1.5 rounded-full bg-warning shrink-0"></span>
                    <span class="font-medium text-foreground truncate">{{ item.topic }}</span>
                  </div>
                  <span class="text-muted-foreground font-medium shrink-0">{{ item.mentions }} mentions</span>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>

      <!-- Footer -->
      <div class="px-6 py-4 border-t border-border bg-muted/10 flex items-center justify-end shrink-0">
        <Button variant="outline" class="border border-border hover:border-transparent text-sm" @click="close">
          Close
        </Button>
      </div>
    </div>
  </div>
</template>
