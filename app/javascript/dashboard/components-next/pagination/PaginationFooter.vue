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

const pageInfo = computed(() => {
  return t(
    'PAGINATION_FOOTER.CURRENT_PAGE_INFO',
    {
      currentPage: formatFullNumber(props.currentPage),
      totalPages: formatCompactNumber(totalPages.value),
    },
    Number(totalPages.value)
  );
});

const paginationButtonClass =
  'size-7 rounded-md border border-border hover:border-transparent hover:bg-muted transition-colors disabled:opacity-40 disabled:cursor-not-allowed';
</script>

<template>
  <div
    class="mx-auto flex w-full items-center justify-between border-t border-border bg-background px-4 py-3 text-[13px] text-muted-foreground"
  >
    <span class="min-w-0 truncate">
      {{ currentPageInformation }}
    </span>
    <div class="flex items-center gap-2">
      <RelayButton
        variant="outline"
        size="icon"
        :class="paginationButtonClass"
        :disabled="isFirstPage"
        @click="changePage(1)"
      >
        <span class="i-lucide-chevrons-left size-3.5" />
      </RelayButton>
      <RelayButton
        variant="outline"
        size="icon"
        :class="paginationButtonClass"
        :disabled="isFirstPage"
        @click="changePage(currentPage - 1)"
      >
        <span class="i-lucide-chevron-left size-3.5" />
      </RelayButton>
      <span class="truncate tabular-nums">{{ pageInfo }}</span>
      <RelayButton
        variant="outline"
        size="icon"
        :class="paginationButtonClass"
        :disabled="isLastPage"
        @click="changePage(currentPage + 1)"
      >
        <span class="i-lucide-chevron-right size-3.5" />
      </RelayButton>
      <RelayButton
        variant="outline"
        size="icon"
        :class="paginationButtonClass"
        :disabled="isLastPage"
        @click="changePage(totalPages)"
      >
        <span class="i-lucide-chevrons-right size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
