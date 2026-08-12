<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  showCcEmailsDropdown: { type: Boolean, required: false },
  showBccEmailsDropdown: { type: Boolean, required: false },
  showCcInput: { type: Boolean, default: false },
  showBccInput: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  hasErrors: { type: Boolean, default: false },
});

const emit = defineEmits([
  'searchCcEmails',
  'searchBccEmails',
  'updateDropdown',
]);

const i18nPrefix = `COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS`;

const subject = defineModel('subject', { type: String, default: '' });
const ccEmails = defineModel('ccEmails', { type: String, default: '' });
const bccEmails = defineModel('bccEmails', { type: String, default: '' });

const { t } = useI18n();

// Convert string to array for TagInput
const ccEmailsArray = computed(() =>
  ccEmails.value
    ? ccEmails.value
        .split(',')
        .map(email => email.trim())
        .filter(Boolean)
    : []
);

const bccEmailsArray = computed(() =>
  bccEmails.value
    ? bccEmails.value
        .split(',')
        .map(email => email.trim())
        .filter(Boolean)
    : []
);

const contactEmailsList = computed(() => {
  return props.contacts
    ?.filter(contact => contact.email)
    .map(({ name, id, email }) => ({
      id,
      label: email,
      email,
      thumbnail: { name: name, src: '' },
      value: id,
      action: 'email',
    }));
});

// Handle updates from TagInput and convert array back to string
const handleCcUpdate = value => {
  ccEmails.value = value.join(',');
};

const handleBccUpdate = value => {
  bccEmails.value = value.join(',');
};

const subjectClass = computed(() => {
  return [
    'h-8 w-full border-none bg-transparent px-0 text-sm font-medium text-foreground shadow-none outline-none placeholder:text-muted-foreground focus-visible:ring-0',
    props.hasErrors ? 'placeholder:!text-n-ruby-9' : '',
  ];
});
</script>

<template>
  <div class="flex flex-col">
    <div
      v-if="showCcInput"
      class="flex min-h-8 items-center gap-3 border-b border-border/40 px-4 py-2"
    >
      <label class="shrink-0 text-xs font-medium text-muted-foreground">
        {{ t(`${i18nPrefix}.CC_LABEL`) }}
      </label>
      <TagInput
        :model-value="ccEmailsArray"
        :placeholder="t(`${i18nPrefix}.CC_PLACEHOLDER`)"
        :menu-items="contactEmailsList"
        :show-dropdown="showCcEmailsDropdown"
        :is-loading="isLoading"
        type="email"
        allow-create
        class="min-h-7 flex-1"
        @input="emit('searchCcEmails', $event)"
        @on-click-outside="emit('updateDropdown', 'cc', false)"
        @update:model-value="handleCcUpdate"
      />
    </div>
    <div
      v-if="showBccInput"
      class="flex min-h-8 items-center gap-3 border-b border-border/40 px-4 py-2"
    >
      <label class="shrink-0 text-xs font-medium text-muted-foreground">
        {{ t(`${i18nPrefix}.BCC_LABEL`) }}
      </label>
      <TagInput
        :model-value="bccEmailsArray"
        :placeholder="t(`${i18nPrefix}.BCC_PLACEHOLDER`)"
        :menu-items="contactEmailsList"
        :show-dropdown="showBccEmailsDropdown"
        :is-loading="isLoading"
        type="email"
        allow-create
        class="min-h-7 flex-1"
        focus-on-mount
        @input="emit('searchBccEmails', $event)"
        @on-click-outside="emit('updateDropdown', 'bcc', false)"
        @update:model-value="handleBccUpdate"
      />
    </div>
    <div class="flex items-center border-b border-border/40 px-4 py-2">
      <input
        v-model="subject"
        type="text"
        :placeholder="t(`${i18nPrefix}.SUBJECT_PLACEHOLDER`)"
        :class="subjectClass"
      />
    </div>
  </div>
</template>
