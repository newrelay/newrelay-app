<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { buildLocaleMenuItems } from 'dashboard/helper/portalHelper';

import {
  RelayButton,
  RelayActionDropdown,
} from 'dashboard/components-next/relay';

const props = defineProps({
  locale: {
    type: String,
    required: true,
  },
  isDefault: {
    type: Boolean,
    required: true,
  },
  isDraft: {
    type: Boolean,
    required: true,
  },
  localeCode: {
    type: String,
    required: true,
  },
  articleCount: {
    type: Number,
    required: true,
  },
  categoryCount: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const localeLabel = computed(() => `${props.locale} (${props.localeCode})`);

const localeMenuLabels = computed(() => ({
  'change-default': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.MAKE_DEFAULT'
  ),
  'move-to-draft': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.MOVE_TO_DRAFT'
  ),
  'publish-locale': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.PUBLISH_LOCALE'
  ),
  'customize-content': t(
    'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.CUSTOMIZE_CONTENT'
  ),
  delete: t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DROPDOWN_MENU.DELETE'),
}));

const localeMenuItems = computed(() =>
  buildLocaleMenuItems({
    isDefault: props.isDefault,
    isDraft: props.isDraft,
  }).map(item => ({
    ...item,
    label: localeMenuLabels.value[item.action],
  }))
);

const handleAction = ({ action, value }) => {
  emit('action', { action, value });
};
</script>

<template>
  <div
    class="group flex flex-col justify-between rounded-xl border border-border/40 bg-card p-4 transition-all hover:border-border hover:shadow-sm sm:flex-row sm:items-center"
  >
    <div class="flex items-center gap-3">
      <span class="text-[14px] font-medium text-foreground">
        {{ localeLabel }}
      </span>
      <span
        v-if="isDefault"
        class="rounded bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary"
      >
        {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DEFAULT') }}
      </span>
      <span
        v-else-if="isDraft"
        class="rounded bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground"
      >
        {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.DRAFT') }}
      </span>
    </div>

    <div class="mt-2 flex items-center gap-4 sm:mt-0">
      <div
        class="hidden items-center gap-2 text-[13px] text-muted-foreground sm:flex"
      >
        <span>
          {{
            $t(
              'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.ARTICLES_COUNT',
              articleCount
            )
          }}
        </span>
        <span class="text-border">|</span>
        <span>
          {{
            $t(
              'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.CATEGORIES_COUNT',
              categoryCount
            )
          }}
        </span>
      </div>
      <RelayActionDropdown
        v-if="localeMenuItems.length"
        :menu-items="localeMenuItems"
        align="end"
        content-class="min-w-[150px]"
        @action="handleAction"
      >
        <template #trigger>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 border border-border text-muted-foreground hover:border-transparent hover:bg-accent hover:text-foreground"
          >
            <span class="i-lucide-ellipsis-vertical size-4" />
          </RelayButton>
        </template>
      </RelayActionDropdown>
    </div>
  </div>
</template>
