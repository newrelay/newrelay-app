<script setup>
import { onMounted, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ContactNotes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactNotes.vue';
import ContactHistory from 'dashboard/components-next/Contacts/ContactsSidebar/ContactHistory.vue';
import ContactMerge from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMerge.vue';
import ContactCustomAttributes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributes.vue';
import ContactDetailHeader from 'dashboard/components-next/Contacts/ContactDetail/ContactDetailHeader.vue';
import ContactAboutPanel from 'dashboard/components-next/Contacts/ContactDetail/ContactAboutPanel.vue';
import ContactLogActivityModal from 'dashboard/components-next/Contacts/ContactDetail/ContactLogActivityModal.vue';
import ContactScheduleMeetingModal from 'dashboard/components-next/Contacts/ContactDetail/ContactScheduleMeetingModal.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';
import {
  RelayTabs,
  RelayTabsList,
  RelayTabsTrigger,
} from 'dashboard/components-next/relay';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const contact = useMapGetter('contacts/getContactById');
const uiFlags = useMapGetter('contacts/getUIFlags');

const activeTab = ref('attributes');
const showLogActivity = ref(false);
const showScheduleMeeting = ref(false);
const confirmDeleteContactDialogRef = ref(null);

const DETAIL_TABS = [
  { value: 'attributes', labelKey: 'CONTACTS_LAYOUT.SIDEBAR.TABS.ATTRIBUTES' },
  { value: 'history', labelKey: 'CONTACTS_LAYOUT.SIDEBAR.TABS.HISTORY' },
  { value: 'notes', labelKey: 'CONTACTS_LAYOUT.SIDEBAR.TABS.NOTES' },
  { value: 'merge', labelKey: 'CONTACTS_LAYOUT.SIDEBAR.TABS.MERGE' },
];

const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);
const isMergingContact = computed(() => uiFlags.value.isMerging);
const isUpdatingContact = computed(() => uiFlags.value.isUpdating);

const contactId = computed(() => route.params.contactId);
const selectedContact = computed(() => contact.value(contactId.value));
const hasContact = computed(() => Boolean(selectedContact.value?.id));

const showSpinner = computed(
  () => (isFetchingItem.value || isMergingContact.value) && !hasContact.value
);

const goToContactsList = () => {
  if (window.history.state?.back || window.history.length > 1) {
    router.back();
  } else {
    router.push(`/app/accounts/${route.params.accountId}/contacts?page=1`);
  }
};

const fetchActiveContact = async () => {
  if (!contactId.value) return;
  await store.dispatch('contacts/show', { id: contactId.value });
  await store.dispatch('contacts/fetchContactableInbox', contactId.value);
};

const fetchContactNotes = () => {
  if (contactId.value) {
    store.dispatch('contactNotes/get', { contactId: contactId.value });
  }
};

const fetchContactConversations = () => {
  if (contactId.value) {
    store.dispatch('contactConversations/get', contactId.value);
  }
};

const fetchAttributes = () => {
  store.dispatch('attributes/get');
};

const toggleContactBlock = async isBlocked => {
  const ALERT_MESSAGES = {
    success: {
      block: t('CONTACTS_LAYOUT.HEADER.ACTIONS.BLOCK_SUCCESS_MESSAGE'),
      unblock: t('CONTACTS_LAYOUT.HEADER.ACTIONS.UNBLOCK_SUCCESS_MESSAGE'),
    },
    error: {
      block: t('CONTACTS_LAYOUT.HEADER.ACTIONS.BLOCK_ERROR_MESSAGE'),
      unblock: t('CONTACTS_LAYOUT.HEADER.ACTIONS.UNBLOCK_ERROR_MESSAGE'),
    },
  };

  try {
    await store.dispatch('contacts/update', {
      ...selectedContact.value,
      blocked: !isBlocked,
    });
    useAlert(
      isBlocked ? ALERT_MESSAGES.success.unblock : ALERT_MESSAGES.success.block
    );
  } catch {
    useAlert(
      isBlocked ? ALERT_MESSAGES.error.unblock : ALERT_MESSAGES.error.block
    );
  }
};

const openDeleteDialog = () => {
  confirmDeleteContactDialogRef.value?.dialogRef.open();
};

const handleAvatarUpload = async ({ file }) => {
  try {
    await store.dispatch('contacts/update', {
      id: contactId.value,
      avatar: file,
      isFormData: true,
    });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.ERROR_MESSAGE'));
  }
};

const handleAvatarDelete = async () => {
  try {
    await store.dispatch('contacts/deleteAvatar', contactId.value);
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.ERROR_MESSAGE'));
  }
};

watch(
  contactId,
  async id => {
    activeTab.value = 'attributes';
    if (!id) return;
    await Promise.allSettled([
      fetchActiveContact(),
      fetchContactNotes(),
      fetchContactConversations(),
      fetchAttributes(),
    ]);
  },
  { immediate: true }
);

watch(activeTab, tab => {
  if (tab === 'notes') fetchContactNotes();
  if (tab === 'history') fetchContactConversations();
});

onMounted(() => {
  fetchAttributes();
});
</script>

<template>
  <section
    class="relative flex h-full w-full flex-col overflow-hidden bg-background animate-in fade-in zoom-in-95 duration-200"
  >
    <ContactDetailHeader
      v-if="hasContact"
      :contact="selectedContact"
      :contact-id="contactId"
      @back="goToContactsList"
      @schedule-meeting="showScheduleMeeting = true"
      @log-activity="showLogActivity = true"
      @block="toggleContactBlock"
      @delete="openDeleteDialog"
      @upload="handleAvatarUpload"
      @avatar-delete="handleAvatarDelete"
    />

    <div
      v-if="showSpinner"
      class="flex flex-1 flex-col items-center justify-center gap-3 text-muted-foreground"
    >
      <Spinner />
      <span class="text-sm">{{ t('CONTACTS_LAYOUT.DETAIL.LOADING') }}</span>
    </div>

    <div
      v-else-if="!hasContact"
      class="m-auto flex flex-1 flex-col items-center justify-center gap-3 px-6 py-24 text-center"
    >
      <span class="text-[20px] font-[600] text-foreground">
        {{ t('CONTACTS_LAYOUT.DETAIL.EMPTY_STATE.TITLE') }}
      </span>
      <p class="max-w-md text-sm text-muted-foreground">
        {{ t('CONTACTS_LAYOUT.DETAIL.EMPTY_STATE.SUBTITLE') }}
      </p>
    </div>

    <main
      v-else
      class="flex flex-1 flex-col overflow-y-auto bg-muted/10 lg:flex-row lg:overflow-hidden"
    >
      <div
        class="flex min-w-0 flex-col bg-background lg:min-h-0 lg:flex-1 lg:overflow-hidden"
      >
        <div class="shrink-0 bg-card px-6">
          <RelayTabs v-model="activeTab">
            <RelayTabsList variant="underline">
              <RelayTabsTrigger
                v-for="tab in DETAIL_TABS"
                :key="tab.value"
                :value="tab.value"
                variant="underline"
              >
                {{ t(tab.labelKey) }}
              </RelayTabsTrigger>
            </RelayTabsList>
          </RelayTabs>
        </div>

        <div class="flex-1 p-6 lg:overflow-y-auto">
          <ContactCustomAttributes
            v-if="activeTab === 'attributes'"
            :selected-contact="selectedContact"
          />
          <ContactHistory v-else-if="activeTab === 'history'" />
          <ContactNotes v-else-if="activeTab === 'notes'" />
          <ContactMerge
            v-else-if="activeTab === 'merge'"
            :selected-contact="selectedContact"
            @go-to-contacts-list="goToContactsList"
            @reset-tab="activeTab = 'attributes'"
          />
        </div>
      </div>

      <ContactAboutPanel
        :contact="selectedContact"
        :is-updating="isUpdatingContact"
      />
    </main>

    <ContactLogActivityModal
      v-if="showLogActivity"
      :contact-name="selectedContact?.name"
      @close="showLogActivity = false"
    />
    <ContactScheduleMeetingModal
      v-if="showScheduleMeeting"
      :contact-name="selectedContact?.name"
      @close="showScheduleMeeting = false"
    />
    <ConfirmContactDeleteDialog
      ref="confirmDeleteContactDialogRef"
      :selected-contact="selectedContact"
      @go-to-contacts-list="goToContactsList"
    />
  </section>
</template>
