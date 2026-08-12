<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  question: {
    type: String,
    required: true,
  },
  answer: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: 'approved',
  },
  documentable: {
    type: Object,
    default: null,
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  showMenu: {
    type: Boolean,
    default: true,
  },
  showActions: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['action', 'navigate', 'select', 'hover']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const statusAction = computed(() => {
  if (props.status === 'pending') {
    return [
      {
        label: t('CAPTAIN.RESPONSES.OPTIONS.APPROVE'),
        value: 'approve',
        action: 'approve',
        icon: 'i-lucide-circle-check-big',
      },
    ];
  }
  return [];
});

const menuItems = computed(() => [
  ...statusAction.value,
  {
    label: t('CAPTAIN.RESPONSES.OPTIONS.EDIT_RESPONSE'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.RESPONSES.OPTIONS.DELETE_RESPONSE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAssistantAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const handleDocumentableClick = () => {
  emit('navigate', {
    id: props.documentable.id,
    type: props.documentable.type,
  });
};

const handleCardClick = () => {
  if (props.selectable) {
    emit('select', props.id);
  }
};
</script>

<template>
  <div
    class="group flex cursor-pointer select-none flex-col justify-between rounded-xl border bg-card p-5 transition-all hover:shadow-xs sm:flex-row sm:items-start"
    :class="
      isSelected
        ? 'border-primary/50 bg-primary/[0.02]'
        : 'border-border hover:border-border'
    "
    @click="handleCardClick"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div class="flex min-w-0 flex-1 items-start gap-4 pr-4">
      <div
        v-if="selectable"
        class="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors"
        :class="
          isSelected
            ? 'border-primary bg-primary text-primary-foreground shadow-xs'
            : 'border-border/80 bg-background/50'
        "
      >
        <span v-if="isSelected" class="i-lucide-check size-3 stroke-[3]" />
      </div>

      <div class="min-w-0 flex-1">
        <h3 class="mb-1.5 text-[15px] font-medium text-foreground">
          {{ question }}
        </h3>
        <p
          class="mb-4 line-clamp-2 text-[14px] leading-relaxed text-muted-foreground"
        >
          {{ answer }}
        </p>

        <div
          v-if="!compact"
          class="flex flex-wrap items-center gap-4 text-[12.5px] text-muted-foreground/80"
        >
          <div
            v-if="status === 'approved' || assistant?.name"
            class="flex items-center gap-1.5"
          >
            <span class="i-lucide-brain-circuit size-3.5 text-primary/70" />
            {{ assistant?.name || '' }}
          </div>

          <div
            v-if="documentable"
            class="flex min-w-0 items-center gap-1.5"
            @click.stop
          >
            <span
              v-if="documentable.type === 'Captain::Document'"
              class="i-ph-files-light size-3.5 opacity-60"
            />
            <span
              v-else-if="documentable.type === 'User'"
              class="i-lucide-user size-3.5 opacity-60"
            />
            <span
              v-else-if="documentable.type === 'Conversation'"
              class="i-ph-chat-circle-dots size-3.5 opacity-60"
            />
            <span
              v-if="documentable.type === 'Captain::Document'"
              class="truncate"
              :title="documentable.name"
            >
              {{ documentable.name }}
            </span>
            <span
              v-else-if="documentable.type === 'User'"
              class="truncate"
              :title="documentable.available_name"
            >
              {{ documentable.available_name }}
            </span>
            <span
              v-else-if="documentable.type === 'Conversation'"
              class="cursor-pointer truncate hover:underline"
              role="button"
              @click="handleDocumentableClick"
            >
              {{
                t(`CAPTAIN.RESPONSES.DOCUMENTABLE.CONVERSATION`, {
                  id: documentable.display_id,
                })
              }}
            </span>
          </div>
        </div>

        <Policy
          v-if="!compact && showActions"
          :permissions="['administrator']"
          class="mt-4"
        >
          <div class="flex w-full items-center gap-2 sm:gap-5" @click.stop>
            <RelayButton
              v-if="status === 'pending'"
              variant="link"
              size="sm"
              class="hover:!no-underline"
              @click="
                handleAssistantAction({ action: 'approve', value: 'approve' })
              "
            >
              <span class="i-lucide-circle-check-big size-4" />
              {{ $t('CAPTAIN.RESPONSES.OPTIONS.APPROVE') }}
            </RelayButton>
            <RelayButton
              variant="link"
              size="sm"
              class="text-muted-foreground hover:!no-underline"
              @click="
                handleAssistantAction({
                  action: 'edit',
                  value: 'edit',
                })
              "
            >
              <span class="i-lucide-pencil-line size-4" />
              {{ $t('CAPTAIN.RESPONSES.OPTIONS.EDIT_RESPONSE') }}
            </RelayButton>
            <RelayButton
              variant="link"
              size="sm"
              class="text-destructive hover:!no-underline"
              @click="
                handleAssistantAction({ action: 'delete', value: 'delete' })
              "
            >
              <span class="i-lucide-trash size-4" />
              {{ $t('CAPTAIN.RESPONSES.OPTIONS.DELETE_RESPONSE') }}
            </RelayButton>
          </div>
        </Policy>
      </div>
    </div>

    <div
      v-if="!compact"
      class="mt-4 flex shrink-0 items-center gap-4 self-end sm:mt-0 sm:self-center"
      @click.stop
    >
      <div
        class="hidden items-center gap-1 text-[12.5px] text-muted-foreground/70 sm:flex"
      >
        <span class="i-lucide-clock size-3.5 opacity-50" />
        <span>{{ timestamp }}</span>
      </div>

      <Policy
        v-if="showMenu"
        v-on-clickaway="() => toggleDropdown(false)"
        :permissions="['administrator']"
        class="relative"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 rounded-md border border-border text-muted-foreground opacity-0 hover:border-transparent hover:bg-muted hover:text-foreground group-hover:opacity-100 focus:opacity-100"
          @click="toggleDropdown()"
        >
          <span class="i-lucide-ellipsis-vertical size-4" />
        </RelayButton>
        <DropdownMenu
          v-if="showActionsDropdown"
          :menu-items="menuItems"
          class="top-full mt-1 ltr:right-0 rtl:right-0"
          @action="handleAssistantAction($event)"
        />
      </Policy>
    </div>
  </div>
</template>
