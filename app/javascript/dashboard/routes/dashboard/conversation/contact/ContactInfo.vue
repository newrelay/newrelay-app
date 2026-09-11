<script>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useCompaniesStore } from 'dashboard/stores/companies';
import { isVoiceCallEnabled } from 'dashboard/helper/inbox';
import Avatar from 'next/avatar/Avatar.vue';
import AddContactDrawer from 'dashboard/components-next/Contacts/Drawers/AddContactDrawer.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ContactDeleteModal from 'dashboard/modules/contact/ContactDeleteModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';

export default {
  components: {
    RelayTooltip,
    AddContactDrawer,
    Avatar,
    ComposeConversation,
    ContactMergeModal,
    ContactDeleteModal,
    VoiceCallButton,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    conversationId: {
      type: [Number, String],
      default: null,
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['panelClose'],
  setup() {
    const { isAdmin } = useAdmin();
    const companiesStore = useCompaniesStore();
    return {
      isAdmin,
      companiesStore,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      inboxesList: 'inboxes/getInboxes',
    }),
    contactProfileLink() {
      return `/app/accounts/${this.$route.params.accountId}/contacts/${this.contact.id}`;
    },
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    locationText() {
      const { country = '', city = '' } = this.additionalAttributes;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (cityAndCountry) return cityAndCountry;
      return this.additionalAttributes.location || '';
    },
    phoneTelLink() {
      const phone = this.contact.phone_number || '';
      const digits = phone.replace(/[^\d+]/g, '');
      return digits ? `tel:${digits}` : '';
    },
    mapsLink() {
      if (!this.locationText) return '';
      return `https://maps.google.com/?q=${encodeURIComponent(this.locationText)}`;
    },
    contactSubtitle() {
      return (
        this.additionalAttributes.company_name ||
        this.additionalAttributes.company_plan ||
        this.contact.company?.name ||
        ''
      );
    },
    actionButtonClass() {
      return 'flex size-8 items-center justify-center rounded-lg border border-border bg-transparent text-foreground transition-colors hover:border-transparent hover:bg-muted/50';
    },
    deleteButtonClass() {
      return 'flex size-8 items-center justify-center rounded-lg border border-border bg-transparent text-destructive transition-colors hover:border-transparent hover:bg-destructive/10';
    },
    voiceInboxes() {
      return (this.inboxesList || []).filter(isVoiceCallEnabled);
    },
    showVoiceCallButton() {
      return this.voiceInboxes.length > 0 && !!this.contact.phone_number;
    },
  },
  watch: {
    'contact.id': {
      handler(id) {
        this.$store.dispatch('contacts/fetchContactableInbox', id);
      },
      immediate: true,
    },
  },
  methods: {
    toggleEditModal() {
      this.$refs.editContactDrawer?.open(this.contact);
    },
    async onContactUpdate(payload) {
      await this.updateContactField(payload);
    },
    async updateContactField(attrs) {
      const contactId = this.contact.id;
      const { companyId, previousCompanyId, ...contactAttrs } = attrs;
      try {
        await this.$store.dispatch('contacts/update', {
          id: contactId,
          ...contactAttrs,
        });
        if (companyId !== undefined && companyId !== previousCompanyId) {
          if (companyId) {
            await this.companiesStore.attachContactToCompany(
              companyId,
              contactId
            );
          } else if (previousCompanyId) {
            await this.companiesStore.removeContactFromCompany(
              previousCompanyId,
              contactId
            );
          }
        }
        useAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
        await this.$store.dispatch('contacts/fetchContactableInbox', contactId);
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          const detail = error.contactErrorDetail;
          if (detail) {
            useAlert(detail);
          } else {
            const invalidAttrs = Array.isArray(error.data) ? error.data : [];
            if (invalidAttrs.includes('email')) {
              useAlert(this.$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.DUPLICATE'));
            } else if (invalidAttrs.includes('phone_number')) {
              useAlert(this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
            } else {
              useAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
            }
          }
        } else if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(error.message || this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>

<template>
  <div
    class="flex w-full flex-col rounded-xl border border-border/60 bg-card p-5 shadow-sm"
  >
    <!-- Header -->
    <div class="mb-6 flex w-full items-center justify-between">
      <h3 class="text-base font-medium text-foreground">
        {{ $t('CONVERSATION.SIDEBAR.OVERVIEW') }}
      </h3>
      <a
        :href="contactProfileLink"
        target="_blank"
        rel="noopener nofollow noreferrer"
        class="flex items-center gap-1.5 rounded-md bg-primary/10 px-3 py-1.5 text-[13px] font-medium text-primary transition-colors hover:bg-primary/20"
      >
        {{ $t('CONVERSATION.SIDEBAR.VIEW_FULL_PROFILE') }}
        <span class="i-lucide-arrow-up-right size-3.5 shrink-0" />
      </a>
    </div>

    <!-- Avatar & Name -->
    <div class="mb-4 flex items-center gap-4">
      <div class="relative shrink-0">
        <img
          v-if="showAvatar && contact.thumbnail"
          :src="contact.thumbnail"
          :alt="contact.name"
          class="size-16 rounded-full border border-border/40 object-cover shadow-xs"
        />
        <div
          v-else-if="showAvatar"
          class="overflow-hidden rounded-full border border-border/40 shadow-xs"
        >
          <Avatar
            :src="contact.thumbnail"
            :name="contact.name"
            :size="64"
            hide-offline-status
            rounded-full
          />
        </div>
        <div
          v-if="contact.availability_status === 'online'"
          class="absolute bottom-0 right-0 size-3.5 rounded-full border-[2.5px] border-background bg-success"
        />
      </div>
      <div class="flex w-full min-w-0 flex-col items-start gap-0.5">
        <div
          v-if="showAvatar"
          class="group flex max-w-full cursor-pointer items-center gap-2"
        >
          <a
            :href="contactProfileLink"
            target="_blank"
            rel="noopener nofollow noreferrer"
            class="max-w-full truncate text-[15px] font-semibold leading-tight text-foreground transition-colors hover:text-primary"
          >
            {{ contact.name }}
          </a>
        </div>
        <span
          v-if="contactSubtitle"
          class="truncate text-[13px] text-muted-foreground"
        >
          {{ contactSubtitle }}
        </span>
      </div>
    </div>

    <div
      class="mb-4 h-[1.5px] w-full shrink-0 bg-border"
      role="separator"
      aria-hidden="true"
    />

    <!-- Contact fields -->
    <div class="flex flex-col gap-2">
      <div class="group flex items-center gap-3">
        <div
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
        >
          <span class="i-lucide-mail size-4" />
        </div>
        <a
          v-if="contact.email"
          :href="`mailto:${contact.email}`"
          class="truncate text-[13px] text-foreground transition-colors hover:text-primary"
        >
          {{ contact.email }}
        </a>
        <span v-else class="truncate text-[13px] text-muted-foreground">
          {{ $t('CONTACT_PANEL.EMAIL_NOT_PROVIDED') }}
        </span>
      </div>

      <div class="group flex items-center gap-3">
        <div
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
        >
          <span class="i-lucide-phone size-4" />
        </div>
        <a
          v-if="contact.phone_number && phoneTelLink"
          :href="phoneTelLink"
          class="truncate text-[13px] text-foreground transition-colors hover:text-primary"
        >
          {{ contact.phone_number }}
        </a>
        <span v-else class="truncate text-[13px] text-muted-foreground">
          {{ $t('CONTACT_PANEL.PHONE_NOT_PROVIDED') }}
        </span>
      </div>

      <div class="group flex items-center gap-3">
        <div
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
        >
          <span class="i-lucide-map-pin size-4" />
        </div>
        <a
          v-if="locationText && mapsLink"
          :href="mapsLink"
          target="_blank"
          rel="noopener noreferrer"
          class="truncate text-[13px] text-foreground transition-colors hover:text-primary"
        >
          {{ locationText }}
        </a>
        <span v-else class="truncate text-[13px] text-muted-foreground">
          {{ $t('CONTACT_PANEL.ADDRESS_NOT_PROVIDED') }}
        </span>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex items-center gap-3 px-1 pt-5">
      <ComposeConversation variant="modal" :contact-id="String(contact.id)">
        <template #trigger>
          <RelayTooltip
            :content="$t('CONTACT_PANEL.NEW_MESSAGE')"
            side="top"
            align="end"
          >
            <button type="button" :class="actionButtonClass">
              <span class="i-lucide-message-square size-4" />
            </button>
          </RelayTooltip>
        </template>
      </ComposeConversation>
      <VoiceCallButton
        v-if="showVoiceCallButton"
        :phone="contact.phone_number"
        :contact-id="contact.id"
        :conversation-id="conversationId"
        :tooltip-label="$t('CONTACT_PANEL.CALL')"
      >
        <template #trigger="{ onClick, disabled }">
          <button
            type="button"
            :class="actionButtonClass"
            :disabled="disabled"
            @click="onClick"
          >
            <span class="i-lucide-phone size-4" />
          </button>
        </template>
      </VoiceCallButton>
      <RelayTooltip
        v-else
        :content="$t('CONTACT_PANEL.CALL')"
        side="top"
        align="end"
      >
        <a v-if="phoneTelLink" :href="phoneTelLink" :class="actionButtonClass">
          <span class="i-lucide-phone size-4" />
        </a>
        <button v-else type="button" :class="actionButtonClass" disabled>
          <span class="i-lucide-phone size-4" />
        </button>
      </RelayTooltip>
      <RelayTooltip
        :content="$t('EDIT_CONTACT.BUTTON_LABEL')"
        side="top"
        align="end"
      >
        <button
          type="button"
          :class="actionButtonClass"
          @click="toggleEditModal"
        >
          <span class="i-lucide-pen-line size-4" />
        </button>
      </RelayTooltip>
      <ContactMergeModal :primary-contact="contact">
        <template #trigger="{ open }">
          <RelayTooltip
            :content="$t('CONTACT_PANEL.MERGE_CONTACT')"
            side="top"
            align="end"
          >
            <button
              type="button"
              :class="actionButtonClass"
              :disabled="uiFlags.isMerging"
              @click="open"
            >
              <span class="i-lucide-merge size-4" />
            </button>
          </RelayTooltip>
        </template>
      </ContactMergeModal>
      <ContactDeleteModal
        v-if="isAdmin"
        :contact="contact"
        @deleted="$emit('panelClose')"
      >
        <template #trigger="{ open }">
          <RelayTooltip
            :content="$t('DELETE_CONTACT.BUTTON_LABEL')"
            side="top"
            align="end"
          >
            <button
              type="button"
              :class="deleteButtonClass"
              :disabled="uiFlags.isDeleting"
              @click="open"
            >
              <span class="i-lucide-trash-2 size-4" />
            </button>
          </RelayTooltip>
        </template>
      </ContactDeleteModal>
    </div>

    <AddContactDrawer ref="editContactDrawer" @update="onContactUpdate" />
  </div>
</template>
