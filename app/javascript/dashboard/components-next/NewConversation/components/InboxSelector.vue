<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { generateLabelForContactableInboxesList } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';

import DropdownMenuList from 'dashboard/components-next/relay/dropdown-menu/DropdownMenuList.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  targetInbox: {
    type: Object,
    default: null,
  },
  selectedContact: {
    type: Object,
    default: null,
  },
  showInboxesDropdown: {
    type: Boolean,
    required: true,
  },
  contactableInboxesList: {
    type: Array,
    default: () => [],
  },
  hasErrors: {
    type: Boolean,
    default: false,
  },
  isFetchingInboxes: {
    type: Boolean,
    default: false,
  },
  variant: {
    type: String,
    default: 'panel',
  },
});

const emit = defineEmits([
  'updateInbox',
  'toggleDropdown',
  'handleInboxAction',
]);

const { t } = useI18n();
const triggerRef = ref(null);
const dropdownRef = ref(null);

const targetInboxLabel = computed(() => {
  return generateLabelForContactableInboxesList(props.targetInbox);
});

const canSelectInbox = computed(() => Boolean(props.selectedContact));

const showDropdown = computed(
  () =>
    props.showInboxesDropdown &&
    !props.isFetchingInboxes &&
    props.contactableInboxesList?.length > 0
);

const { fixedPosition } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  showDropdown,
  { align: 'start' }
);

const toggleDropdown = () => {
  if (!canSelectInbox.value) return;
  emit('toggleDropdown', !props.showInboxesDropdown);
};

const closeDropdown = event => {
  if (triggerRef.value?.contains(event.target)) return;
  emit('toggleDropdown', false);
};

const isModalLayout = computed(() => props.variant === 'modal');
</script>

<template>
  <div
    class="flex w-full items-center gap-4"
    :class="
      isModalLayout
        ? 'border-b border-border/50 px-6 py-4'
        : 'border-b border-border/40 px-4 py-2'
    "
  >
    <span class="w-16 shrink-0 text-[14px] font-semibold text-foreground">
      {{ t('COMPOSE_NEW_CONVERSATION.FORM.INBOX_SELECTOR.LABEL') }}
    </span>
    <div
      ref="triggerRef"
      class="relative flex min-h-7 min-w-0 flex-1 items-center"
    >
      <Spinner v-if="isFetchingInboxes" :size="16" />
      <template v-else>
        <button
          v-if="targetInbox"
          type="button"
          class="min-w-0 flex-1 truncate text-left text-[14px] text-foreground"
          @click="toggleDropdown"
        >
          {{ targetInboxLabel }}
        </button>
        <button
          v-else
          type="button"
          class="min-w-0 flex-1 truncate text-left text-[14px] text-muted-foreground disabled:cursor-not-allowed"
          :class="hasErrors ? 'text-destructive' : ''"
          :disabled="!canSelectInbox"
          @click="toggleDropdown"
        >
          {{ t('COMPOSE_NEW_CONVERSATION.FORM.INBOX_SELECTOR.SHOW_INBOXES') }}
        </button>
        <button
          v-if="targetInbox"
          type="button"
          class="shrink-0 p-0.5 text-muted-foreground transition-colors hover:text-foreground"
          @click="emit('updateInbox', null)"
        >
          <span class="i-lucide-x size-3.5" />
        </button>
      </template>
    </div>
    <TeleportWithDirection to="body">
      <div
        v-if="showDropdown"
        ref="dropdownRef"
        v-on-click-outside="closeDropdown"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="min-w-[8rem] max-w-sm overflow-y-auto rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
        @click.stop
      >
        <DropdownMenuList
          :menu-items="contactableInboxesList"
          @action="emit('handleInboxAction', $event)"
        />
      </div>
    </TeleportWithDirection>
  </div>
</template>
