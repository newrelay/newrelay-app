<script setup>
import { useI18n } from 'vue-i18n';

import {
  RelayButton,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import InboxDisplayMenu from './InboxDisplayMenu.vue';

const emit = defineEmits(['redirect', 'filter', 'optionClick']);

const { t } = useI18n();

const onFilterChange = option => {
  emit('filter', option);
  emit('redirect');
};

const onOptionClick = key => {
  emit('optionClick', key);
};
</script>

<template>
  <div
    class="flex h-14 w-full shrink-0 items-center justify-between gap-1 border-b border-border/60 bg-card px-4"
  >
    <div class="flex min-w-0 flex-1 items-center">
      <h1 class="min-w-0 truncate text-[16px] font-[500] text-foreground">
        {{ t('INBOX.LIST.TITLE') }}
      </h1>
    </div>
    <div class="relative flex items-center gap-2">
      <RelayDropdownMenu>
        <RelayDropdownMenuTrigger as-child>
          <RelayButton variant="outline" size="sm" class="h-8 gap-1 px-3">
            {{ t('INBOX.LIST.DISPLAY_DROPDOWN') }}
            <span class="i-lucide-chevron-down size-3.5" />
          </RelayButton>
        </RelayDropdownMenuTrigger>
        <RelayDropdownMenuContent align="start" class="w-56 p-2">
          <InboxDisplayMenu @filter="onFilterChange" />
        </RelayDropdownMenuContent>
      </RelayDropdownMenu>
      <RelayDropdownMenu>
        <RelayDropdownMenuTrigger as-child>
          <RelayButton
            variant="outline"
            size="icon"
            class="size-8"
            :aria-label="t('INBOX.LIST.MORE_OPTIONS')"
          >
            <span
              class="i-lucide-sliders-horizontal size-[18px] text-muted-foreground"
            />
          </RelayButton>
        </RelayDropdownMenuTrigger>
        <RelayDropdownMenuContent align="start" class="w-40">
          <RelayDropdownMenuItem
            class="text-xs"
            @click="onOptionClick('mark_all_read')"
          >
            {{ t('INBOX.MENU_ITEM.MARK_ALL_READ') }}
          </RelayDropdownMenuItem>
        </RelayDropdownMenuContent>
      </RelayDropdownMenu>
    </div>
  </div>
</template>
