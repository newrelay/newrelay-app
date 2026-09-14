<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useFunctionGetter } from 'dashboard/composables/store';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const { captainTasksEnabled, summarizeConversation } = useCaptain();
const conversationIdRef = computed(() => props.conversationId);
const conversationLabels = useFunctionGetter(
  'conversationLabels/getConversationLabels',
  conversationIdRef
);

const isGenerating = ref(false);
const summaryText = ref('');
const lastUpdatedAt = ref(null);
const errorMessage = ref('');

const labelTakeaways = computed(() => {
  const labels = conversationLabels.value || [];
  return labels.slice(0, 4).map(title => title);
});

const summaryBullets = computed(() => {
  if (!summaryText.value) return [];
  return summaryText.value
    .split(/\n+/)
    .map(line => line.replace(/^[-•*]\s*/, '').trim())
    .filter(Boolean)
    .slice(0, 6);
});

const nextBestAction = computed(() => {
  const labels = labelTakeaways.value.map(l => l.toLowerCase());
  if (labels.some(l => l.includes('demo') || l.includes('call'))) {
    return t('CONVERSATION.AI_SUMMARY.ACTIONS.SCHEDULE_DEMO');
  }
  if (labels.some(l => l.includes('follow'))) {
    return t('CONVERSATION.AI_SUMMARY.ACTIONS.FOLLOW_UP');
  }
  if (summaryBullets.value.length) {
    return t('CONVERSATION.AI_SUMMARY.ACTIONS.REVIEW_SUMMARY');
  }
  return t('CONVERSATION.AI_SUMMARY.ACTIONS.GENERATE_FIRST');
});

const hasSummary = computed(() =>
  Boolean(summaryBullets.value.length || summaryText.value)
);

const lastUpdatedLabel = computed(() => {
  if (!lastUpdatedAt.value) {
    return t('CONVERSATION.AI_SUMMARY.NOT_GENERATED');
  }
  return t('CONVERSATION.AI_SUMMARY.LAST_UPDATED', {
    time: lastUpdatedAt.value.toLocaleString(),
  });
});

const generateSummary = async () => {
  if (!captainTasksEnabled.value || isGenerating.value) return;
  isGenerating.value = true;
  errorMessage.value = '';
  try {
    const result = await summarizeConversation();
    if (result?.message) {
      summaryText.value = result.message;
      lastUpdatedAt.value = new Date();
    } else if (result?.errorType || result?.error) {
      errorMessage.value = result.error || t('CONVERSATION.AI_SUMMARY.ERROR');
    }
  } catch {
    errorMessage.value = t('CONVERSATION.AI_SUMMARY.ERROR');
  } finally {
    isGenerating.value = false;
  }
};

watch(
  () => props.conversationId,
  () => {
    summaryText.value = '';
    lastUpdatedAt.value = null;
    errorMessage.value = '';
  }
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <p class="text-[11px] text-muted-foreground">
      {{ lastUpdatedLabel }}
    </p>

    <ul v-if="summaryBullets.length" class="flex flex-col gap-2.5">
      <li
        v-for="(bullet, index) in summaryBullets"
        :key="index"
        class="flex items-start gap-3 text-[13px] text-foreground/80 leading-snug"
      >
        <span class="size-1.5 rounded-full bg-foreground/30 mt-1.5 shrink-0" />
        <span>{{ bullet }}</span>
      </li>
    </ul>
    <p
      v-else-if="summaryText"
      class="text-[13.5px] text-foreground/90 leading-relaxed"
    >
      {{ summaryText }}
    </p>
    <p v-else class="text-[13px] text-muted-foreground">
      {{ t('CONVERSATION.AI_SUMMARY.EMPTY') }}
    </p>

    <p v-if="errorMessage" class="text-[12px] text-destructive">
      {{ errorMessage }}
    </p>

    <div
      class="mt-1 flex flex-col gap-1.5 overflow-hidden rounded-xl border border-primary/20 bg-primary/5 p-0.5"
    >
      <div v-if="hasSummary" class="flex items-center gap-3 rounded-lg p-2.5">
        <div
          class="flex size-7 shrink-0 items-center justify-center rounded-full bg-primary/10"
        >
          <span class="i-lucide-lightbulb size-4 text-primary" />
        </div>
        <div class="flex min-w-0 flex-1 flex-col">
          <span class="text-[13px] font-medium text-primary">
            {{ t('CONVERSATION.AI_SUMMARY.NEXT_BEST_ACTION') }}
          </span>
          <span class="mt-0.5 truncate text-[13px] text-foreground">
            {{ nextBestAction }}
          </span>
        </div>
        <span
          class="i-lucide-chevron-right size-4 shrink-0 text-muted-foreground"
        />
      </div>

      <div :class="hasSummary ? 'px-2 pb-2' : 'p-2'">
        <button
          type="button"
          class="flex min-h-10 w-full items-center justify-center gap-2 rounded-xl border border-primary/20 bg-background px-4 py-2.5 text-[13px] font-medium text-primary transition-colors hover:bg-primary/5 disabled:pointer-events-none disabled:opacity-60"
          :disabled="isGenerating"
          @click="generateSummary"
        >
          <span
            class="i-lucide-refresh-cw size-3.5"
            :class="isGenerating ? 'animate-spin' : ''"
          />
          {{
            isGenerating
              ? t('CONVERSATION.AI_SUMMARY.GENERATING')
              : t('CONVERSATION.AI_SUMMARY.GENERATE')
          }}
        </button>
      </div>
    </div>
  </div>
</template>
