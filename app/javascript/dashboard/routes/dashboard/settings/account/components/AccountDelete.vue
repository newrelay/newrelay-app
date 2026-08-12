<script setup>
import { computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import WootConfirmDeleteModal from 'dashboard/components/widgets/modal/ConfirmDeleteModal.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import SectionLayout from './SectionLayout.vue';

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('accounts/getUIFlags');
const { currentAccount } = useAccount();
const [showDeletePopup, toggleDeletePopup] = useToggle();

const confirmPlaceHolderText = computed(() => {
  return `${t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.CONFIRM.PLACE_HOLDER', {
    accountName: currentAccount.value.name,
  })}`;
});

const isMarkedForDeletion = computed(() => {
  const { custom_attributes = {} } = currentAccount.value;
  return !!custom_attributes.marked_for_deletion_at;
});

const markedForDeletionDate = computed(() => {
  const { custom_attributes = {} } = currentAccount.value;
  if (!custom_attributes.marked_for_deletion_at) return null;
  return new Date(custom_attributes.marked_for_deletion_at);
});

const markedForDeletionReason = computed(() => {
  const { custom_attributes = {} } = currentAccount.value;
  return custom_attributes.marked_for_deletion_reason || 'manual_deletion';
});

const formattedDeletionDate = computed(() => {
  if (!markedForDeletionDate.value) return '';
  return markedForDeletionDate.value.toLocaleString();
});

const markedForDeletionMessage = computed(() => {
  const params = { deletionDate: formattedDeletionDate.value };

  if (markedForDeletionReason.value === 'manual_deletion') {
    return t(
      `GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.SCHEDULED_DELETION.MESSAGE_MANUAL`,
      params
    );
  }

  return t(
    `GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.SCHEDULED_DELETION.MESSAGE_INACTIVITY`,
    params
  );
});

function handleDeletionError(error) {
  const message = error.response?.data?.message;
  if (message) {
    useAlert(message);
    return;
  }
  useAlert(t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.FAILURE'));
}

async function markAccountForDeletion() {
  toggleDeletePopup(false);
  try {
    await store.dispatch('accounts/toggleDeletion', {
      action_type: 'delete',
    });
    await store.dispatch('accounts/get');
    useAlert(t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.SUCCESS'));
  } catch (error) {
    handleDeletionError(error);
  }
}

async function clearDeletionMark() {
  try {
    await store.dispatch('accounts/toggleDeletion', {
      action_type: 'undelete',
    });

    await store.dispatch('accounts/get');
    useAlert(t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.UPDATE.ERROR'));
  }
}
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.TITLE')"
    :description="t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.NOTE')"
    as-card
    inline-header
    hide-content
  >
    <template #headerActions>
      <div v-if="isMarkedForDeletion" class="flex flex-col gap-3">
        <p class="max-w-sm text-sm text-muted-foreground">
          {{ markedForDeletionMessage }}
        </p>
        <RelayButton
          variant="outline"
          class="border-red-200 bg-background text-red-500 shadow-xs hover:bg-red-50 hover:text-red-600"
          :disabled="uiFlags.isUpdating"
          @click="clearDeletionMark"
        >
          {{
            $t(
              'GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.SCHEDULED_DELETION.CLEAR_BUTTON'
            )
          }}
        </RelayButton>
      </div>
      <div v-else class="flex items-center gap-3">
        <RelayButton
          variant="outline"
          type="button"
          class="border-red-200 text-red-500 hover:bg-red-50"
        >
          {{ $t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.DEACTIVATE_BUTTON') }}
        </RelayButton>
        <RelayButton
          variant="destructive"
          class="shadow-xs"
          @click="toggleDeletePopup(true)"
        >
          {{ $t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.BUTTON_TEXT') }}
        </RelayButton>
      </div>
    </template>
  </SectionLayout>
  <WootConfirmDeleteModal
    v-if="showDeletePopup"
    v-model:show="showDeletePopup"
    :title="$t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.CONFIRM.TITLE')"
    :message="$t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.CONFIRM.MESSAGE')"
    :confirm-text="
      $t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.CONFIRM.BUTTON_TEXT')
    "
    :reject-text="$t('GENERAL_SETTINGS.ACCOUNT_DELETE_SECTION.CONFIRM.DISMISS')"
    :confirm-value="currentAccount.name"
    :confirm-place-holder-text="confirmPlaceHolderText"
    @on-confirm="markAccountForDeletion"
    @on-close="toggleDeletePopup(false)"
  />
</template>
