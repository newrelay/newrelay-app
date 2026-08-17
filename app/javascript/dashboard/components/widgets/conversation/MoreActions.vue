<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import { RelayActionDropdown } from 'dashboard/components-next/relay';
import wootConstants from 'dashboard/constants/globals';

const store = useStore();
const { t } = useI18n();

const currentChat = computed(() => store.getters.getSelectedChat);
const isResolved = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.RESOLVED
);
const isPending = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.PENDING
);

const actionMenuSections = computed(() => {
  const primaryItems = [];

  primaryItems.push({
    icon: 'i-lucide-check',
    label: isResolved.value
      ? t('CONVERSATION.HEADER.REOPEN_ACTION')
      : t('CONVERSATION.HEADER.RESOLVE_ACTION'),
    action: isResolved.value ? 'reopen' : 'resolve',
    value: isResolved.value ? 'reopen' : 'resolve',
  });

  if (!isPending.value) {
    primaryItems.push({
      icon: 'i-lucide-clock',
      label: t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE_UNTIL'),
      action: 'snooze',
      value: 'snooze',
    });
    primaryItems.push({
      icon: 'i-lucide-hourglass',
      label: t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING'),
      action: 'pending',
      value: 'pending',
    });
  }

  const destructiveItems = [
    {
      icon: 'i-lucide-ban',
      label: 'Block Contact',
      action: 'block',
      value: 'block',
      destructive: true,
    },
    {
      icon: 'i-lucide-trash-2',
      label: t('CONVERSATION.CARD_CONTEXT_MENU.DELETE', 'Delete Thread'),
      action: 'delete',
      value: 'delete',
      destructive: true,
    },
  ];

  return [{ items: primaryItems }, { items: destructiveItems }];
});

const openSnoozeModal = () => {
  const ninja = document.querySelector('ninja-keys');
  if (ninja) ninja.open({ parent: 'snooze_conversation' });
};

const handleActionClick = ({ action }) => {
  if (action === 'resolve') {
    store.dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status: wootConstants.STATUS_TYPE.RESOLVED,
    });
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  } else if (action === 'reopen') {
    store.dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status: wootConstants.STATUS_TYPE.OPEN,
    });
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  } else if (action === 'snooze') {
    openSnoozeModal();
  } else if (action === 'pending') {
    store.dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status: wootConstants.STATUS_TYPE.PENDING,
    });
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  } else if (action === 'delete') {
    store.dispatch('deleteConversation', currentChat.value.id);
  } else if (action === 'block') {
    useAlert('Block contact is not fully implemented yet.');
  }
};
</script>

<template>
  <RelayActionDropdown
    :menu-sections="actionMenuSections"
    align="end"
    content-class="w-52"
    @action="handleActionClick"
  >
    <template #trigger>
      <ButtonV4
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-horizontal"
        class="rounded-md"
        :title="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
      />
    </template>
  </RelayActionDropdown>
</template>
