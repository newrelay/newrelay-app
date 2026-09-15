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
  variant: { type: String, default: 'panel' },
});

const emit = defineEmits([
  'searchCcEmails',
  'searchBccEmails',
  'updateDropdown',
  'closeCc',
  'closeBcc',
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

const isModalLayout = computed(() => props.variant === 'modal');

const fieldRowClass = computed(() =>
  isModalLayout.value
    ? 'flex min-h-8 items-center gap-4 border-b border-border/50 px-6 py-4'
    : 'flex min-h-8 items-center gap-4 border-b border-border/40 px-4 py-2'
);
</script>

<template>
  <div class="flex flex-col">
    <div v-if="showCcInput" :class="fieldRowClass">
      <span class="w-16 shrink-0 text-[14px] font-semibold text-foreground">
        {{ t(`${i18nPrefix}.CC_LABEL`) }}
      </span>
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
      <button
        type="button"
        class="rounded-sm p-0.5 text-muted-foreground transition-colors hover:text-foreground"
        :title="t(`${i18nPrefix}.CC_BUTTON`)"
        @click="emit('closeCc')"
      >
        <span class="i-lucide-x size-3.5" />
      </button>
    </div>
    <div v-if="showBccInput" :class="fieldRowClass">
      <span class="w-16 shrink-0 text-[14px] font-semibold text-foreground">
        {{ t(`${i18nPrefix}.BCC_LABEL`) }}
      </span>
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
      <button
        type="button"
        class="rounded-sm p-0.5 text-muted-foreground transition-colors hover:text-foreground"
        :title="t(`${i18nPrefix}.BCC_BUTTON`)"
        @click="emit('closeBcc')"
      >
        <span class="i-lucide-x size-3.5" />
      </button>
    </div>
    <div :class="fieldRowClass">
      <span class="w-16 shrink-0 text-[14px] font-semibold text-foreground">
        {{ t(`${i18nPrefix}.SUBJECT_LABEL`) }}
      </span>
      <input
        v-model="subject"
        type="text"
        :placeholder="t(`${i18nPrefix}.SUBJECT_PLACEHOLDER`)"
        class="reset-base h-6 min-w-0 flex-1 border-none bg-transparent px-0 text-[14px] text-foreground shadow-none outline-none placeholder:text-muted-foreground focus:ring-0"
        :class="hasErrors ? 'placeholder:!text-destructive' : ''"
      />
    </div>
  </div>
</template>
