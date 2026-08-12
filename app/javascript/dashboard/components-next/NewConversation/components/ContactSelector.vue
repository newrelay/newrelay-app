<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { INPUT_TYPES } from 'dashboard/components-next/taginput/helper/tagInputHelper.js';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  contacts: {
    type: Array,
    required: true,
  },
  selectedContact: {
    type: Object,
    default: null,
  },
  showContactsDropdown: {
    type: Boolean,
    required: true,
  },
  isLoading: {
    type: Boolean,
    required: true,
  },
  isCreatingContact: {
    type: Boolean,
    required: true,
  },
  contactId: {
    type: String,
    default: null,
  },
  contactableInboxesList: {
    type: Array,
    default: () => [],
  },
  showInboxesDropdown: {
    type: Boolean,
    required: true,
  },
  hasErrors: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'searchContacts',
  'setSelectedContact',
  'clearSelectedContact',
  'updateDropdown',
]);

const i18nPrefix = 'COMPOSE_NEW_CONVERSATION.FORM.CONTACT_SELECTOR';
const { t } = useI18n();

const inputType = ref(INPUT_TYPES.EMAIL);

const contactsList = computed(() => {
  return props.contacts?.map(({ name, id, thumbnail, email, ...rest }) => ({
    id,
    label: email ? `${name} (${email})` : name,
    value: id,
    thumbnail: { name, src: thumbnail },
    ...rest,
    name,
    email,
    action: 'contact',
  }));
});

const selectedContactPill = computed(() => {
  const {
    email = '',
    phoneNumber = '',
    name = '',
  } = props.selectedContact || {};
  return email || phoneNumber || name || '';
});

const errorClass = computed(() => {
  return props.hasErrors
    ? '[&_input]:placeholder:!text-n-ruby-9 [&_input]:dark:placeholder:!text-n-ruby-9'
    : '';
});

const handleInput = value => {
  // Update input type based on whether input starts with '+'
  // If it does, set input type to 'tel'
  // Otherwise, set input type to 'email'
  inputType.value = value.startsWith('+') ? INPUT_TYPES.TEL : INPUT_TYPES.EMAIL;
  emit('searchContacts', value);
};
</script>

<template>
  <div class="relative min-w-0 flex-1 overflow-y-visible">
    <div class="flex min-h-8 w-full items-center gap-2">
      <div
        v-if="isCreatingContact"
        class="flex min-h-7 min-w-0 items-center gap-1.5 rounded-md bg-muted px-3"
      >
        <span class="truncate text-sm text-foreground">
          {{ t(`${i18nPrefix}.CONTACT_CREATING`) }}
        </span>
      </div>
      <div
        v-else-if="selectedContact"
        class="flex min-h-7 min-w-0 items-center gap-1.5 rounded-md bg-muted px-3"
        :class="!contactId ? 'pr-1' : ''"
      >
        <span class="truncate text-sm text-foreground">
          {{ selectedContactPill }}
        </span>
        <RelayButton
          v-if="!contactId"
          variant="ghost"
          size="icon"
          class="size-6 shrink-0 text-muted-foreground hover:text-foreground"
          @click="emit('clearSelectedContact')"
        >
          <span class="i-lucide-x size-3.5" />
        </RelayButton>
      </div>
      <TagInput
        v-else
        :placeholder="t(`${i18nPrefix}.TAG_INPUT_PLACEHOLDER`)"
        mode="single"
        :menu-items="contactsList"
        :show-dropdown="showContactsDropdown"
        :is-loading="isLoading"
        :disabled="contactableInboxesList?.length > 0 && showInboxesDropdown"
        allow-create
        :type="inputType"
        class="min-h-7 flex-1"
        :class="errorClass"
        focus-on-mount
        @input="handleInput"
        @on-click-outside="emit('updateDropdown', 'contacts', false)"
        @add="emit('setSelectedContact', $event)"
        @remove="emit('clearSelectedContact')"
      />
    </div>
  </div>
</template>
