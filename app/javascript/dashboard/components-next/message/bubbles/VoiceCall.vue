<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useMessageContext } from '../provider.js';
import {
  VOICE_CALL_STATUS,
  VOICE_CALL_DIRECTION,
  VOICE_CALL_OUTBOUND_INIT_STATUS,
  VOICE_CALL_END_REASON,
  MESSAGE_TYPES,
  ATTACHMENT_TYPES,
} from '../constants';
import { useCallActions } from 'dashboard/composables/useCallSession';
import { useWhatsappCallSession } from 'dashboard/composables/useWhatsappCallSession';
import { useCallsStore } from 'dashboard/stores/calls';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import { formatDuration, messageStamp } from 'shared/helpers/timeHelper';
import { useAlert } from 'dashboard/composables';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import VoiceCallRecordingPlayer from 'next/message/chips/VoiceCallRecordingPlayer.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const LABEL_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CONVERSATION.VOICE_CALL.CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-lucide-phone-call',
  [VOICE_CALL_STATUS.COMPLETED]: 'i-lucide-phone',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-lucide-phone-off',
  [VOICE_CALL_STATUS.FAILED]: 'i-lucide-phone-off',
};

const { t } = useI18n();
const store = useStore();
const {
  call,
  attachments,
  contentAttributes,
  conversationId,
  createdAt,
  currentUserId,
  inboxId,
  sender,
  messageType,
} = useMessageContext();
const { joinCall, endCall, activeCall, hasActiveCall, isJoining } =
  useCallActions();
const whatsappCallSession = useWhatsappCallSession();
const callsStore = useCallsStore();
const contactsUiFlags = useMapGetter('contacts/getUIFlags');
const isInitiatingCall = computed(
  () => contactsUiFlags.value?.isInitiatingCall || false
);

// Merge top-level call payload (API) with content_attributes.data.call (seeders / legacy).
const callData = computed(() => {
  const dataBlock = contentAttributes?.value?.data || {};
  const nestedCall = dataBlock.call || {};
  const fromProp = call.value || {};

  return {
    ...nestedCall,
    ...fromProp,
    status: fromProp.status ?? nestedCall.status ?? dataBlock.status ?? null,
    direction:
      fromProp.direction ??
      nestedCall.direction ??
      dataBlock.callDirection ??
      dataBlock.call_direction ??
      null,
    durationSeconds:
      fromProp.durationSeconds ??
      fromProp.duration_seconds ??
      nestedCall.durationSeconds ??
      nestedCall.duration_seconds ??
      dataBlock.durationSeconds ??
      dataBlock.duration_seconds ??
      null,
    recordingUrl:
      fromProp.recordingUrl ??
      fromProp.recording_url ??
      nestedCall.recordingUrl ??
      nestedCall.recording_url ??
      null,
    acceptedByAgentId:
      fromProp.acceptedByAgentId ??
      fromProp.accepted_by_agent_id ??
      nestedCall.acceptedByAgentId ??
      nestedCall.accepted_by_agent_id ??
      null,
    acceptedByAgentName:
      fromProp.acceptedByAgentName ??
      fromProp.accepted_by_agent_name ??
      nestedCall.acceptedByAgentName ??
      nestedCall.accepted_by_agent_name ??
      null,
    providerCallId:
      fromProp.providerCallId ??
      fromProp.provider_call_id ??
      nestedCall.providerCallId ??
      nestedCall.provider_call_id ??
      dataBlock.callSid ??
      dataBlock.call_sid ??
      null,
    endReason:
      fromProp.endReason ??
      fromProp.end_reason ??
      nestedCall.endReason ??
      nestedCall.end_reason ??
      null,
    provider:
      fromProp.provider ??
      nestedCall.provider ??
      dataBlock.callSource ??
      dataBlock.call_source ??
      null,
    transcript: fromProp.transcript ?? nestedCall.transcript ?? null,
  };
});

const status = computed(() => callData.value?.status);
// Server-side call records use `outgoing`/`incoming`, while the Pinia store
// and a few API hops normalise to `outbound`/`inbound`. Accept either so the
// bubble label matches the message orientation no matter the source.
const isOutbound = computed(() => {
  const dir = callData.value?.direction;
  if (
    dir === VOICE_CALL_DIRECTION.OUTGOING ||
    dir === VOICE_CALL_DIRECTION.OUTBOUND
  )
    return true;
  if (
    dir === VOICE_CALL_DIRECTION.INCOMING ||
    dir === VOICE_CALL_DIRECTION.INBOUND
  )
    return false;
  // Fall back to the message orientation: agent-authored messages sit on the
  // right (outbound) and contact-authored ones on the left.
  return messageType.value === MESSAGE_TYPES.OUTGOING;
});
const isWhatsapp = computed(
  () => callData.value?.provider === VOICE_CALL_PROVIDERS.WHATSAPP
);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);
const isMissedInbound = computed(() => isFailed.value && !isOutbound.value);
const endReason = computed(() => callData.value?.endReason);
const wasDeclinedByAgent = computed(
  () =>
    isMissedInbound.value &&
    endReason.value === VOICE_CALL_END_REASON.AGENT_REJECTED
);
const acceptedByAgentId = computed(() => callData.value?.acceptedByAgentId);
const conversationAssignee = computed(() => {
  const conversation = store.getters.getConversationById?.(
    conversationId?.value
  );
  return conversation?.meta?.assignee || null;
});
const displayAgentName = computed(() => {
  if (callData.value?.acceptedByAgentName)
    return callData.value.acceptedByAgentName;
  if (acceptedByAgentId.value) {
    const agent = store.getters['agents/getAgentById'](acceptedByAgentId.value);
    if (agent?.available_name) return agent.available_name;
    if (agent?.name) return agent.name;
  }
  return conversationAssignee.value?.name || null;
});

const audioAttachment = computed(() =>
  (attachments?.value || []).find(a => a.fileType === ATTACHMENT_TYPES.AUDIO)
);

const durationSeconds = computed(() => {
  const fromCall = callData.value?.durationSeconds;
  if (fromCall != null) return fromCall;
  const data = contentAttributes?.value?.data;
  return data?.durationSeconds || data?.duration_seconds;
});

const formattedDuration = computed(() => formatDuration(durationSeconds.value));

const isCompleted = computed(
  () => status.value === VOICE_CALL_STATUS.COMPLETED
);

// "Ended at" clock time for the completed-call metadata grid.
const endedAt = computed(() =>
  createdAt?.value ? messageStamp(createdAt.value, 'h:mm a') : null
);

const callTypeLabel = computed(() =>
  t(
    isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.OUTBOUND'
      : 'CONVERSATION.VOICE_CALL.INBOUND'
  )
);

const callTypeIcon = computed(() =>
  isOutbound.value ? 'i-lucide-corner-down-left' : 'i-lucide-corner-down-right'
);

// Agent who handled the call (initiator on outbound, answerer on inbound), taken
// strictly from the persisted accept fields — never the conversation's current
// assignee, which would mis-attribute a historical call after a reassignment.
const handlerName = computed(() => {
  if (callData.value?.acceptedByAgentName)
    return callData.value.acceptedByAgentName;
  if (!acceptedByAgentId.value) return null;
  const agent = store.getters['agents/getAgentById'](acceptedByAgentId.value);
  return agent?.available_name || agent?.name || null;
});

const handledBy = computed(() =>
  handlerName.value
    ? t('CONVERSATION.VOICE_CALL.HANDLED_BY', { agentName: handlerName.value })
    : null
);

const labelKey = computed(() => {
  if (LABEL_MAP[status.value]) return LABEL_MAP[status.value];
  if (isFailed.value) {
    return isOutbound.value
      ? 'CONVERSATION.VOICE_CALL.NO_ANSWER_OUTBOUND_LABEL'
      : 'CONVERSATION.VOICE_CALL.MISSED_CALL';
  }
  // RINGING or an as-yet-unknown/initial status: orient purely by direction so an
  // outbound call never falls through to the "Incoming call" label.
  return isOutbound.value
    ? 'CONVERSATION.VOICE_CALL.OUTGOING_CALL'
    : 'CONVERSATION.VOICE_CALL.INCOMING_CALL';
});

const subtext = computed(() => {
  // Completed: duration on the top row; handler/time/type move to the grid below.
  if (status.value === VOICE_CALL_STATUS.COMPLETED) {
    return formattedDuration.value;
  }
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return handledBy.value;
  }
  if (isFailed.value) {
    // Missed/failed calls have no handler, so keep the reason rather than "Handled by".
    if (isOutbound.value) {
      return t('CONVERSATION.VOICE_CALL.NO_ANSWER_OUTBOUND_SUBTEXT');
    }
    if (wasDeclinedByAgent.value && displayAgentName.value) {
      return t('CONVERSATION.VOICE_CALL.MISSED_CALL_DECLINED_BY', {
        agentName: displayAgentName.value,
      });
    }
    return t('CONVERSATION.VOICE_CALL.MISSED_CALL_INBOUND_SUBTEXT');
  }
  // RINGING or an as-yet-unknown/initial status.
  if (isOutbound.value) {
    return handledBy.value || t('CONVERSATION.VOICE_CALL.CALLING');
  }
  return t('CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET');
});

const iconName = computed(() => {
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value
    ? 'i-lucide-phone-outgoing'
    : 'i-lucide-phone-incoming';
});

// Subtle icon container — matches the design's tonal swatch over the bubble bg.
// Status drives the accent: teal for live, ruby for missed, neutral otherwise.
const iconContainerClass = computed(() => {
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return 'bg-success/10 text-success';
  }
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return 'bg-success/10 text-success';
  }
  if (isMissedInbound.value) {
    return 'bg-accent text-destructive';
  }
  return 'bg-primary/10 text-primary';
});

const callSid = computed(() => callData.value?.providerCallId);

const canJoinCall = computed(() => {
  if (status.value !== VOICE_CALL_STATUS.RINGING) return false;
  if (isOutbound.value) return false;
  if (acceptedByAgentId.value) return false;
  if (!callSid.value || !inboxId.value || !conversationId.value) return false;
  if (hasActiveCall.value && activeCall.value?.callSid === callSid.value)
    return false;
  const assignee = conversationAssignee.value;
  if (assignee?.id && assignee.id !== currentUserId.value) return false;
  return true;
});

const recordingAttachment = computed(() => {
  if (audioAttachment.value) return audioAttachment.value;
  const url = callData.value?.recordingUrl;
  if (!url) return null;
  return {
    dataUrl: url,
    fileType: ATTACHMENT_TYPES.AUDIO,
    extension: 'wav',
    transcribedText: callData.value?.transcript || '',
  };
});

const handleJoinCall = async () => {
  if (!canJoinCall.value || isJoining.value) return;

  if (hasActiveCall.value && activeCall.value?.callSid !== callSid.value) {
    await endCall({
      conversationId: activeCall.value.conversationId,
      inboxId: activeCall.value.inboxId,
      callSid: activeCall.value.callSid,
    });
  }

  await joinCall({
    conversationId: conversationId.value,
    inboxId: inboxId.value,
    callSid: callSid.value,
  });
};

const canCallBack = computed(
  () =>
    isMissedInbound.value &&
    !!inboxId.value &&
    !!conversationId.value &&
    !hasActiveCall.value &&
    !callsStore.hasIncomingCall
);

const handleCallBack = async () => {
  if (!canCallBack.value || isInitiatingCall.value) return;
  try {
    if (isWhatsapp.value) {
      const response = await whatsappCallSession.initiateOutboundCall(
        conversationId.value
      );
      if (response?.status === VOICE_CALL_OUTBOUND_INIT_STATUS.LOCKED) return;
      // Permission template path returns no call id — show banner, no widget yet.
      if (!response?.id) {
        useAlert(
          response?.status ===
            VOICE_CALL_OUTBOUND_INIT_STATUS.PERMISSION_PENDING
            ? t('CONVERSATION.HEADER.WHATSAPP_CALL_PERMISSION_PENDING')
            : t('CONVERSATION.HEADER.WHATSAPP_CALL_PERMISSION_REQUESTED')
        );
        return;
      }
      callsStore.addCall({
        callSid: response.call_id,
        callId: response.id,
        conversationId: conversationId.value,
        inboxId: inboxId.value,
        callDirection: VOICE_CALL_DIRECTION.OUTBOUND,
        provider: VOICE_CALL_PROVIDERS.WHATSAPP,
      });
      return;
    }
    const response = await store.dispatch('contacts/initiateCall', {
      contactId: sender.value?.id,
      inboxId: inboxId.value,
      conversationId: conversationId.value,
    });
    callsStore.addCall({
      callSid: response?.call_sid,
      conversationId: response?.conversation_id ?? conversationId.value,
      inboxId: inboxId.value,
      callDirection: VOICE_CALL_DIRECTION.OUTBOUND,
    });
  } catch (error) {
    useAlert(error?.message || t('CONTACT_PANEL.CALL_FAILED'));
  }
};
</script>

<template>
  <BaseBubble
    class="relative !w-[360px] !max-w-full overflow-hidden !border !border-border !bg-card !p-3.5 !text-foreground shadow-xs"
    hide-meta
  >
    <div class="flex w-full flex-col gap-3">
      <div class="flex items-center gap-3">
        <div
          class="flex size-10 shrink-0 items-center justify-center rounded-xl"
          :class="iconContainerClass"
        >
          <Icon class="size-5" :icon="iconName" />
        </div>
        <div class="flex min-w-0 flex-1 flex-col">
          <span class="truncate text-[14px] font-semibold text-foreground">
            {{ $t(labelKey) }}
          </span>
          <span
            v-if="subtext"
            class="truncate text-[13px] text-muted-foreground"
          >
            {{ subtext }}
          </span>
        </div>
      </div>

      <VoiceCallRecordingPlayer
        v-if="isCompleted"
        :attachment="recordingAttachment"
        :has-recording="!!recordingAttachment"
      />

      <div
        v-if="isCompleted"
        class="grid grid-cols-3 gap-2 border-t border-border/50 pt-2.5 text-[11px]"
      >
        <div class="flex flex-col gap-0.5">
          <span class="font-medium text-muted-foreground">
            {{ $t('CONVERSATION.VOICE_CALL.ENDED_AT') }}
          </span>
          <span class="text-foreground">{{ endedAt || '—' }}</span>
        </div>
        <div class="flex flex-col gap-0.5 min-w-0">
          <span class="font-medium text-muted-foreground">
            {{ $t('CONVERSATION.VOICE_CALL.HANDLED_BY_LABEL') }}
          </span>
          <span class="truncate text-foreground">{{ handlerName || '—' }}</span>
        </div>
        <div class="flex flex-col gap-0.5 min-w-0">
          <span class="font-medium text-muted-foreground">
            {{ $t('CONVERSATION.VOICE_CALL.CALL_TYPE') }}
          </span>
          <span class="flex items-center gap-1 truncate text-foreground">
            <Icon class="size-3 text-primary/70" :icon="callTypeIcon" />
            {{ callTypeLabel }}
          </span>
        </div>
      </div>

      <RelayButton
        v-if="canCallBack"
        type="button"
        size="sm"
        class="h-8 w-full rounded-full text-[13px]"
        :disabled="isInitiatingCall"
        @click="handleCallBack"
      >
        <span class="i-lucide-phone size-3.5" />
        {{ $t('CONVERSATION.VOICE_CALL.CALL_BACK') }}
      </RelayButton>

      <RelayButton
        v-if="canJoinCall"
        type="button"
        size="sm"
        class="h-8 w-full rounded-full text-[13px]"
        :disabled="isJoining"
        @click="handleJoinCall"
      >
        <span class="i-lucide-phone size-3.5" />
        {{ $t('CONVERSATION.VOICE_CALL.JOIN_CALL') }}
      </RelayButton>
    </div>
  </BaseBubble>
</template>
