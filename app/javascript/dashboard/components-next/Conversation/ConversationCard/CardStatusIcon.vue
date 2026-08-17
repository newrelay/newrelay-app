<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed } from 'vue';
import { CONVERSATION_STATUS } from 'shared/constants/messages';

import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  status: {
    type: String,
    default: '',
  },
  showEmpty: {
    type: Boolean,
    default: false,
  },
});

const icons = {
  [CONVERSATION_STATUS.OPEN]: 'i-woot-status-open',
  [CONVERSATION_STATUS.RESOLVED]: 'i-woot-status-resolved',
  [CONVERSATION_STATUS.PENDING]: 'i-woot-status-pending',
  [CONVERSATION_STATUS.SNOOZED]: 'i-woot-status-snoozed',
};

const iconName = computed(() => {
  if (props.status && icons[props.status]) {
    return icons[props.status];
  }
  return props.showEmpty ? 'i-woot-status-empty' : '';
});
</script>

<template>
  <RelayTooltip
    :content="{
      content: status,
      delay: { show: 500, hide: 0 },
    }"
    side="top"
  >
    <Icon :icon="iconName" class="size-4 flex-shrink-0" />
  </RelayTooltip>
</template>
