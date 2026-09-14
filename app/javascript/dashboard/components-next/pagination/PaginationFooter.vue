<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useNumberFormatter } from 'shared/composables/useNumberFormatter';

import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  currentPage: {
    type: Number,
    required: true,
  },
  totalItems: {
    type: Number,
    required: true,
  },
  itemsPerPage: {
    type: Number,
    default: 16,
  },
  currentPageInfo: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['update:currentPage']);
const { t } = useI18n();
const { formatCompactNumber, formatFullNumber } = useNumberFormatter();
const ELLIPSIS = '…';

const totalPages = computed(() =>
  Math.ceil(props.totalItems / props.itemsPerPage)
);
const startItem = computed(
  () => (props.currentPage - 1) * props.itemsPerPage + 1
);
const endItem = computed(() =>
  Math.min(startItem.value + props.itemsPerPage - 1, props.totalItems)
);
const isFirstPage = computed(() => props.currentPage === 1);
const isLastPage = computed(() => props.currentPage === totalPages.value);

const changePage = newPage => {
  if (newPage >= 1 && newPage <= totalPages.value) {
    emit('update:currentPage', newPage);
  }
};

const currentPageInformation = computed(() => {
  const translationKey = props.currentPageInfo || 'PAGINATION_FOOTER.SHOWING';
  return t(
    translationKey,
    {
      startItem: formatFullNumber(startItem.value),
      endItem: formatFullNumber(endItem.value),
      totalItems: formatCompactNumber(props.totalItems),
    },
    Number(props.totalItems)
  );
});

// Build the list of page-number tokens to render.
// Returns numbers and '...' ellipsis strings.
// ponytail: simple O(totalPages) scan; fine for ≤ a few thousand pages.
const pageTokens = computed(() => {
  const total = totalPages.value;
  const current = props.currentPage;
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);

  // Always show first, last, and a window of ±1 around current.
  const visible = new Set(
    [1, total, current - 1, current, current + 1].filter(
      p => p >= 1 && p <= total
    )
  );
  const sorted = [...visible].sort((a, b) => a - b);

  const tokens = [];
  for (let i = 0; i < sorted.length; i += 1) {
    if (i > 0 && sorted[i] - sorted[i - 1] > 1) tokens.push(ELLIPSIS);
    tokens.push(sorted[i]);
  }
  return tokens;
});
</script>

<template>
  <div
    class="mx-auto flex w-full items-center justify-between border-t border-border bg-background px-4 py-3 text-[14px] text-muted-foreground"
  >
    <span class="min-w-0 truncate">
      {{ currentPageInformation }}
    </span>
    <div class="flex items-center gap-1.5">
      <RelayButton
        variant="outline"
        size="icon"
        class="!size-8 shadow-none transition-colors disabled:cursor-not-allowed disabled:opacity-40"
        :disabled="isFirstPage"
        @click="changePage(currentPage - 1)"
      >
        <span class="i-lucide-chevron-left size-4" />
      </RelayButton>

      <template v-for="(token, index) in pageTokens" :key="index">
        <span
          v-if="token === ELLIPSIS"
          class="flex size-8 items-center justify-center text-[14px] text-muted-foreground"
        >
          {{ ELLIPSIS }}
        </span>
        <RelayButton
          v-else
          variant="outline"
          size="icon"
          class="!size-8 shadow-none transition-colors"
          :class="
            token === currentPage
              ? 'bg-primary text-primary-foreground border-primary hover:bg-primary/90'
              : 'hover:bg-accent'
          "
          @click="changePage(token)"
        >
          {{ token }}
        </RelayButton>
      </template>

      <RelayButton
        variant="outline"
        size="icon"
        class="!size-8 shadow-none transition-colors disabled:cursor-not-allowed disabled:opacity-40"
        :disabled="isLastPage"
        @click="changePage(currentPage + 1)"
      >
        <span class="i-lucide-chevron-right size-4" />
      </RelayButton>
    </div>
  </div>
</template>
