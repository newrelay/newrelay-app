<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import {
  RelayButton,
  RelayActionDropdown,
} from 'dashboard/components-next/relay';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  updatedAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);
const { checkPermissions } = usePolicy();

const { t } = useI18n();

const menuItems = computed(() => {
  const allOptions = [
    {
      label: t('CAPTAIN.ASSISTANTS.OPTIONS.VIEW_CONNECTED_INBOXES'),
      value: 'viewConnectedInboxes',
      action: 'viewConnectedInboxes',
      icon: 'i-lucide-link',
    },
  ];

  if (checkPermissions(['administrator'])) {
    allOptions.push(
      {
        label: t('CAPTAIN.ASSISTANTS.OPTIONS.EDIT_ASSISTANT'),
        value: 'edit',
        action: 'edit',
        icon: 'i-lucide-pencil-line',
      },
      {
        label: t('CAPTAIN.ASSISTANTS.OPTIONS.DELETE_ASSISTANT'),
        value: 'delete',
        action: 'delete',
        icon: 'i-lucide-trash',
      }
    );
  }

  return allOptions;
});

const lastUpdatedAt = computed(() => dynamicTime(props.updatedAt));

const handleAction = ({ action, value }) => {
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <h6
        class="text-base font-normal text-foreground line-clamp-1 hover:underline transition-colors"
      >
        {{ name }}
      </h6>
      <div class="flex items-center gap-2">
        <RelayActionDropdown
          :menu-items="menuItems"
          align="end"
          @action="handleAction($event)"
        >
          <template #trigger>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md text-muted-foreground hover:bg-accent border border-border hover:border-transparent"
            >
              <span class="i-lucide-ellipsis-vertical size-4" />
            </RelayButton>
          </template>
        </RelayActionDropdown>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span class="text-sm truncate text-muted-foreground">
        {{ description || 'Description not available' }}
      </span>
      <span class="text-sm text-muted-foreground line-clamp-1 shrink-0">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
