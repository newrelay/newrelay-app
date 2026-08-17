<script>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Avatar from 'next/avatar/Avatar.vue';
import AddContactDrawer from 'dashboard/components-next/Contacts/Drawers/AddContactDrawer.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ContactDeleteModal from 'dashboard/modules/contact/ContactDeleteModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    RelayTooltip,
    RelayButton,
    AddContactDrawer,
    Avatar,
    ComposeConversation,
    ContactMergeModal,
    ContactDeleteModal,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['panelClose'],
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
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
    actionButtonClass() {
      return 'size-8 rounded-lg border border-border bg-transparent flex items-center justify-center text-foreground transition-colors hover:border-transparent hover:bg-muted/50';
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
      try {
        await this.$store.dispatch('contacts/update', {
          id: contactId,
          ...attrs,
        });
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
    class="relative flex w-full flex-col rounded-xl border border-border/60 bg-card p-5 shadow-sm"
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
        <div
          class="overflow-hidden rounded-full border border-border/40 shadow-xs"
        >
          <Avatar
            v-if="showAvatar"
            :src="contact.thumbnail"
            :name="contact.name"
            :size="64"
            hide-offline-status
            rounded-full
          />
        </div>
        <div
          v-if="contact.availability_status === 'online'"
          class="absolute bottom-0 right-0 size-3.5 rounded-full border-[2.5px] border-background bg-emerald-500"
        />
      </div>
      <div class="flex min-w-0 w-full flex-col items-start gap-0.5">
        <a
          v-if="showAvatar"
          :href="contactProfileLink"
          target="_blank"
          rel="noopener nofollow noreferrer"
          class="max-w-full truncate text-[15px] font-semibold leading-tight text-foreground transition-colors hover:text-primary"
        >
          {{ contact.name }}
        </a>
        <span class="truncate text-[13px] text-muted-foreground">
          {{ additionalAttributes.company_plan || 'Enterprise Plan' }}
        </span>
      </div>
    </div>

    <div class="mb-4 h-px w-full bg-border/60" />

    <!-- Contact fields -->
    <div class="flex flex-col gap-2">
      <div v-if="contact.email" class="group flex items-center gap-3">
        <div
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
        >
          <span class="i-lucide-mail size-4" />
        </div>
        <a
          :href="`mailto:${contact.email}`"
          class="truncate text-[13px] text-foreground transition-colors hover:text-primary"
        >
          {{ contact.email }}
        </a>
      </div>

      <div v-if="contact.phone_number" class="group flex items-center gap-3">
        <div
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
        >
          <span class="i-lucide-phone size-4" />
        </div>
        <a
          :href="phoneTelLink"
          class="truncate text-[13px] text-foreground transition-colors hover:text-primary"
        >
          {{ contact.phone_number }}
        </a>
      </div>

      <div v-if="locationText" class="group flex items-center gap-3">
        <div
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
        >
          <span class="i-lucide-map-pin size-4" />
        </div>
        <a
          :href="mapsLink"
          target="_blank"
          rel="noopener noreferrer"
          class="truncate text-[13px] text-foreground transition-colors hover:text-primary"
        >
          {{ locationText }}
        </a>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex items-center gap-3 px-1 pt-5">
      <ComposeConversation :contact-id="String(contact.id)">
        <template #trigger>
          <RelayTooltip
            :content="$t('CONTACT_PANEL.NEW_MESSAGE')"
            side="top"
            align="end"
          >
            <RelayButton variant="ghost" size="icon" :class="actionButtonClass">
              <span class="i-lucide-message-square size-4" />
            </RelayButton>
          </RelayTooltip>
        </template>
      </ComposeConversation>
      <RelayTooltip
        :content="$t('EDIT_CONTACT.BUTTON_LABEL')"
        side="top"
        align="end"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          :class="actionButtonClass"
          @click="toggleEditModal"
        >
          <span class="i-lucide-pen-line size-4" />
        </RelayButton>
      </RelayTooltip>
      <ContactMergeModal :primary-contact="contact">
        <template #trigger>
          <RelayTooltip
            :content="$t('CONTACT_PANEL.MERGE_CONTACT')"
            side="top"
            align="end"
          >
            <RelayButton
              variant="ghost"
              size="icon"
              :class="actionButtonClass"
              :disabled="uiFlags.isMerging"
            >
              <span class="i-lucide-merge size-4" />
            </RelayButton>
          </RelayTooltip>
        </template>
      </ContactMergeModal>
      <ContactDeleteModal
        v-if="isAdmin"
        :contact="contact"
        @deleted="$emit('panelClose')"
      >
        <template #trigger>
          <RelayTooltip
            :content="$t('DELETE_CONTACT.BUTTON_LABEL')"
            side="top"
            align="end"
          >
            <RelayButton
              variant="ghost"
              size="icon"
              :class="`${actionButtonClass} text-destructive hover:bg-destructive/10 hover:text-destructive`"
              :disabled="uiFlags.isDeleting"
            >
              <span class="i-lucide-trash-2 size-4" />
            </RelayButton>
          </RelayTooltip>
        </template>
      </ContactDeleteModal>
    </div>

    <AddContactDrawer ref="editContactDrawer" @update="onContactUpdate" />
  </div>
</template>
