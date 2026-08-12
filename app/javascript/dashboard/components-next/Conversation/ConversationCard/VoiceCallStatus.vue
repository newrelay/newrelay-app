<script setup>
import { computed } from 'vue';
import {
  VOICE_CALL_STATUS,
  VOICE_CALL_DIRECTION,
} from 'dashboard/components-next/message/constants';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  status: { type: String, default: '' },
  direction: { type: String, default: '' },
});

const LABEL_KEYS = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-phone-call',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-phone-x',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-phone-x',
};

const COLOR_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'text-success',
  [VOICE_CALL_STATUS.RINGING]: 'text-success',
  [VOICE_CALL_STATUS.COMPLETED]: 'text-muted-foreground',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'text-destructive',
  [VOICE_CALL_STATUS.FAILED]: 'text-destructive',
};

const isOutbound = computed(
  () => props.direction === VOICE_CALL_DIRECTION.OUTBOUND
);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(props.status)
);

const labelKey = computed(() => {
  if (LABEL_KEYS[props.status]) return LABEL_KEYS[props.status];
  if (props.status === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
      : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
  }
  return isFailed.value
    ? 'CONVERSATION.VOICE_CALL.MISSED_CALL'
    : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
});

const iconName = computed(() => {
  if (ICON_MAP[props.status]) return ICON_MAP[props.status];
  return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
});

const statusColor = computed(
  () => COLOR_MAP[props.status] || 'text-muted-foreground'
);
</script>

<template>
  <div class="grid grid-cols-[auto_1fr] items-center gap-1 min-w-0 text-sm">
    <Icon class="size-3.5" :icon="iconName" :class="statusColor" />
    <span class="truncate text-body-main" :class="statusColor">
      {{ $t(labelKey) }}
    </span>
  </div>
</template>
