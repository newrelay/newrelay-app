<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayBadge, RelayButton } from 'dashboard/components-next/relay';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  endpointUrl: {
    type: String,
    default: '',
  },
  httpMethod: {
    type: String,
    default: 'GET',
  },
  authType: {
    type: String,
    default: 'none',
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.CUSTOM_TOOLS.OPTIONS.EDIT_TOOL'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.CUSTOM_TOOLS.OPTIONS.DELETE_TOOL'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const authTypeLabel = computed(() => {
  return t(
    `CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.${props.authType.toUpperCase()}`
  );
});
</script>

<template>
  <div
    class="group flex items-center justify-between rounded-2xl border border-border bg-card p-5 transition-all hover:shadow-sm"
  >
    <div class="min-w-0 space-y-1">
      <div class="flex items-center gap-2.5">
        <RelayBadge
          variant="secondary"
          class="shrink-0 border-primary/20 bg-primary/10 font-bold uppercase text-primary"
        >
          {{ httpMethod }}
        </RelayBadge>
        <h3 class="truncate text-base font-semibold text-foreground">
          {{ title }}
        </h3>
      </div>
      <p v-if="description" class="text-[13.5px] text-muted-foreground">
        {{ description }}
      </p>
      <code
        v-if="endpointUrl"
        class="inline-block truncate rounded-md bg-muted/50 px-2 py-0.5 font-mono text-[12px] text-muted-foreground/80"
      >
        {{ endpointUrl }}
      </code>
      <div
        class="flex items-center gap-3 pt-1 text-[12px] text-muted-foreground/70"
      >
        <span v-if="authType !== 'none'" class="inline-flex items-center gap-1">
          <span class="i-lucide-lock size-3.5" />
          {{ authTypeLabel }}
        </span>
        <span>{{ timestamp }}</span>
      </div>
    </div>

    <Policy
      v-on-clickaway="() => toggleDropdown(false)"
      :permissions="['administrator']"
      class="relative shrink-0"
    >
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:bg-muted hover:text-foreground"
        @click="toggleDropdown()"
      >
        <span class="i-lucide-ellipsis-vertical size-4" />
      </RelayButton>
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="menuItems"
        class="top-full mt-1 ltr:right-0 rtl:right-0"
        @action="handleAction($event)"
      />
    </Policy>
  </div>
</template>
