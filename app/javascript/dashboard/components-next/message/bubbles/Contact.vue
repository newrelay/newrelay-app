<script setup>
import { computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';
import { RelayButton } from 'dashboard/components-next/relay';

import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';

const { attachments } = useMessageContext();

const $store = useStore();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});

const phoneNumber = computed(() => {
  return attachment.value.fallbackTitle;
});

const contactName = computed(() => {
  const { meta } = attachment.value ?? {};
  const { firstName, lastName } = meta ?? {};
  return `${firstName ?? ''} ${lastName ?? ''}`.trim();
});

const formattedPhoneNumber = computed(() => {
  return (phoneNumber.value || '').replace(/\s|-|[A-Za-z]/g, '');
});

const rawPhoneNumber = computed(() => {
  return phoneNumber.value.replace(/\D/g, '');
});

function getContactObject() {
  const contactItem = {
    name: contactName.value,
    phone_number: `+${rawPhoneNumber.value}`,
  };
  return contactItem;
}

async function filterContactByNumber(searchCandidate) {
  const query = {
    attribute_key: 'phone_number',
    filter_operator: 'equal_to',
    values: [searchCandidate],
    attribute_model: 'standard',
    custom_attribute_type: '',
  };

  const queryPayload = { payload: [query] };
  const contacts = await $store.dispatch('contacts/filter', {
    queryPayload,
    resetState: false,
  });
  return contacts.shift();
}

function openContactNewTab(contactId) {
  const accountId = window.location.pathname.split('/')[3];
  const url = `/app/accounts/${accountId}/contacts/${contactId}`;
  window.open(url, '_blank');
}

async function addContact() {
  try {
    let contact = await filterContactByNumber(rawPhoneNumber.value);
    if (!contact) {
      contact = await $store.dispatch('contacts/create', getContactObject());
      useAlert(t('CONTACT_FORM.SUCCESS_MESSAGE'));
    }
    openContactNewTab(contact.id);
  } catch (error) {
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('phone_number')) {
        useAlert(t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t('CONTACT_FORM.ERROR_MESSAGE'));
    }
  }
}
</script>

<template>
  <BaseBubble
    class="min-w-[280px] overflow-hidden !rounded-xl !border !border-border !bg-card !p-3 !text-foreground shadow-xs"
    data-bubble-name="contact"
  >
    <div class="flex min-w-0 items-center gap-4">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
      >
        <span class="i-lucide-user size-5" />
      </div>
      <div class="flex min-w-0 flex-1 flex-col">
        <span class="truncate text-sm font-semibold text-foreground">
          {{ contactName || phoneNumber }}
        </span>
        <span
          v-if="contactName && phoneNumber"
          class="mt-0.5 truncate text-[13px] text-muted-foreground"
        >
          {{ phoneNumber }}
        </span>
      </div>
      <RelayButton
        v-if="formattedPhoneNumber"
        variant="outline"
        size="sm"
        class="shrink-0"
        @click="addContact"
      >
        {{ t('CONVERSATION.SAVE_CONTACT') }}
      </RelayButton>
    </div>
  </BaseBubble>
</template>
