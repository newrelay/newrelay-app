<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { RelayDeleteConfirmModal } from 'dashboard/components-next/relay';

import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from 'dashboard/helper/routeHelpers';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'deleted']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const uiFlags = useMapGetter('contacts/getUIFlags');
const showDeleteModal = ref(false);

const openDeleteModal = () => {
  showDeleteModal.value = true;
};

const onDelete = async () => {
  try {
    await store.dispatch('contacts/delete', props.contact.id);
    useAlert(t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));
    showDeleteModal.value = false;
    emit('deleted');
    emit('close');

    if (isAConversationRoute(route.name)) {
      router.push({ name: getConversationDashboardRoute(route.name) });
    } else if (isAInboxViewRoute(route.name)) {
      router.push({ name: 'inbox_view' });
    } else if (route.name !== 'contacts_dashboard') {
      router.push({ name: 'contacts_dashboard' });
    }
  } catch (error) {
    useAlert(error.message || t('DELETE_CONTACT.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="contents">
    <slot name="trigger" :open="openDeleteModal" />
    <RelayDeleteConfirmModal
      :show="showDeleteModal"
      :title="t('DELETE_CONTACT.CONFIRM.TITLE')"
      :highlight-name="contact.name"
      :description-prefix="t('DELETE_CONTACT.CONFIRM.DESCRIPTION_PREFIX')"
      :description-suffix="t('DELETE_CONTACT.CONFIRM.DESCRIPTION_SUFFIX')"
      :confirm-text="t('DELETE_CONTACT.CONFIRM.YES')"
      :cancel-text="t('DELETE_CONTACT.CONFIRM.NO')"
      :is-loading="uiFlags.isDeleting"
      @update:show="showDeleteModal = $event"
      @confirm="onDelete"
    />
  </div>
</template>
