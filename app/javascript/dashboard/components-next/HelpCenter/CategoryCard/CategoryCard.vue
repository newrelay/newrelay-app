<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  articlesCount: {
    type: Number,
    required: true,
  },
  slug: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['click', 'action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const categoryMenuItems = computed(() => [
  {
    label: t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.EDIT'),
    action: 'edit',
    value: 'edit',
    icon: 'i-lucide-pencil',
  },
  {
    label: t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.DELETE'),
    action: 'delete',
    value: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const description = computed(() => {
  return props.description
    ? props.description
    : t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.NO_DESCRIPTION');
});

const hasDescription = computed(() => {
  return props.description.length > 0;
});

const handleClick = slug => {
  emit('click', slug);
};

const handleAction = ({ action, value }) => {
  emit('action', { action, value, id: props.id });
  toggleDropdown(false);
};
</script>

<template>
  <div
    class="group flex flex-col justify-between gap-3 rounded-xl border border-border/40 bg-card p-4 transition-all hover:border-border hover:shadow-sm sm:flex-row sm:items-center"
  >
    <div class="flex min-w-0 flex-1 items-center gap-3.5">
      <div
        class="flex size-8 shrink-0 items-center justify-center rounded-lg border border-primary/25 bg-primary/15 text-[15px] shadow-sm"
      >
        <span v-if="icon" class="text-[15px] leading-none">{{ icon }}</span>
        <span v-else class="i-lucide-folder size-4 text-primary" />
      </div>
      <div
        class="flex min-w-0 flex-1 flex-wrap items-center gap-3 sm:flex-nowrap"
      >
        <h3
          class="shrink-0 cursor-pointer truncate text-[14.5px] font-medium text-foreground hover:text-primary"
          @click="handleClick(slug)"
        >
          {{ title }}
        </h3>
        <span class="hidden text-[10px] text-muted-foreground/40 sm:inline"
          >•</span
        >
        <p
          class="min-w-0 flex-1 truncate text-[13px]"
          :class="
            hasDescription
              ? 'text-muted-foreground'
              : 'text-muted-foreground/60'
          "
        >
          {{ description }}
        </p>
      </div>
    </div>

    <div class="flex shrink-0 items-center gap-3 self-end sm:self-center">
      <span
        class="rounded border border-border/50 bg-muted px-2 py-0.5 text-[12px] font-medium text-muted-foreground"
      >
        {{
          t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_CARD.ARTICLES_COUNT', {
            count: articlesCount,
          })
        }}
      </span>
      <div v-on-clickaway="() => toggleDropdown(false)" class="relative">
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-7 border border-border text-muted-foreground hover:border-transparent hover:bg-muted hover:text-foreground"
          @click="toggleDropdown()"
        >
          <span class="i-lucide-ellipsis-vertical size-3.5" />
        </RelayButton>
        <DropdownMenu
          v-if="showActionsDropdown"
          :menu-items="categoryMenuItems"
          class="top-full z-60 mt-1 ltr:right-0 rtl:left-0 xl:ltr:left-0 xl:rtl:right-0"
          @action="handleAction"
        />
      </div>
    </div>
  </div>
</template>
