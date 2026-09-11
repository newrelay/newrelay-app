<script setup>
import { computed, onBeforeUnmount, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useCallSession } from 'dashboard/composables/useCallSession';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import WindowVisibilityHelper from 'dashboard/helper/AudioAlerts/WindowVisibilityHelper';
import CallCard from 'dashboard/components-next/call/CallCard.vue';
import IncomingCallOverlay from 'dashboard/components-next/call/IncomingCallOverlay.vue';
import OngoingCallOverlay from 'dashboard/components-next/call/OngoingCallOverlay.vue';
import countriesList from 'shared/constants/countries.js';

const RINGTONE_URL = '/audio/dashboard/ringtone.mp3';

const route = useRoute();
const router = useRouter();
const store = useStore();

const {
  activeCall,
  incomingCalls,
  hasActiveCall,
  isJoining,
  joinCall,
  endCall: endCallSession,
  rejectIncomingCall,
  formattedCallDuration,
  isMuted,
  isSpeakerOn,
  isNoteModalOpen,
  noteText,
  callWidgetPos,
  isCallOverlayExpanded,
  toggleMute,
  toggleSpeaker,
  triggerNote,
  closeNote,
  saveQuickNote,
  setCallOverlayExpanded,
  acceptSimulatedCall,
} = useCallSession();

const primaryIncomingCall = computed(() =>
  hasActiveCall.value ? null : incomingCalls.value[0] || null
);

const mainCardState = computed(() => {
  if (hasActiveCall.value) return VOICE_CALL_DIRECTION.ONGOING;
  const direction = primaryIncomingCall.value?.callDirection;
  return direction === VOICE_CALL_DIRECTION.OUTBOUND
    ? VOICE_CALL_DIRECTION.OUTGOING
    : VOICE_CALL_DIRECTION.INCOMING;
});

const showIncomingOverlay = computed(
  () =>
    isCallOverlayExpanded.value &&
    !!primaryIncomingCall.value &&
    mainCardState.value === VOICE_CALL_DIRECTION.INCOMING
);

const primaryActiveCall = computed(
  () => activeCall.value || primaryIncomingCall.value
);

const isActiveCallVisible = computed(
  () =>
    mainCardState.value === VOICE_CALL_DIRECTION.OUTGOING ||
    mainCardState.value === VOICE_CALL_DIRECTION.ONGOING
);

const showOngoingOverlay = computed(
  () => isCallOverlayExpanded.value && isActiveCallVisible.value
);

const showMiniWidget = computed(
  () =>
    (hasActiveCall.value || primaryIncomingCall.value) &&
    !showIncomingOverlay.value &&
    !showOngoingOverlay.value
);

watch(isActiveCallVisible, visible => {
  if (visible) setCallOverlayExpanded(true);
});

const countryCodeToFlag = code => {
  if (!code || code.length !== 2) return '';
  const base = 0x1f1e6;
  const offset = 'A'.charCodeAt(0);
  return String.fromCodePoint(
    ...code
      .toUpperCase()
      .split('')
      .map(c => base + (c.charCodeAt(0) - offset))
  );
};

const getCallInfo = call => {
  const conversation = store.getters.getConversationById(call?.conversationId);
  const inbox = store.getters['inboxes/getInbox'](call?.inboxId);
  const sender = conversation?.meta?.sender;
  const caller = call?.caller;
  const additional =
    sender?.additional_attributes || caller?.additionalAttributes || {};
  const city = additional.city || '';
  const countryCode = additional.country_code || '';
  const country =
    additional.country ||
    countriesList.find(c => c.id === countryCode.toUpperCase())?.name ||
    '';
  const locationParts = [city, country].filter(Boolean);
  const location =
    locationParts.join(', ') || inbox?.name || 'Customer support';
  return {
    conversation,
    inbox,
    contactName:
      caller?.name ||
      sender?.name ||
      caller?.phone ||
      sender?.phone_number ||
      'Unknown caller',
    phoneNumber:
      caller?.phone ||
      sender?.phone_number ||
      store.getters['contacts/getContact'](sender?.id)?.phone_number ||
      '',
    inboxName: inbox?.name || 'Customer support',
    location,
    countryFlag: countryCodeToFlag(countryCode),
    hasLocation: locationParts.length > 0,
    avatar: caller?.avatar || sender?.avatar || sender?.thumbnail,
  };
};

const goToConversation = call => {
  const conversationId = call?.conversationId;
  const accountId = route.params.accountId;
  if (!conversationId || !accountId) return;
  router.push({
    path: frontendURL(conversationUrl({ accountId, id: conversationId })),
  });
};

const handleEndCall = async () => {
  const call = activeCall.value;
  if (!call) return;

  const inboxId = call.inboxId || getCallInfo(call).conversation?.inbox_id;
  if (!inboxId && !call.isSimulated) return;

  await endCallSession({
    conversationId: call.conversationId,
    inboxId,
    callSid: call.callSid,
  });
};

const handleJoinCall = async call => {
  if (!call || isJoining.value) return;

  if (call.isSimulated) {
    acceptSimulatedCall(call.callSid);
    return;
  }

  const { conversation } = getCallInfo(call);

  if (hasActiveCall.value) {
    await handleEndCall();
  }

  const result = await joinCall({
    conversationId: call.conversationId,
    inboxId: call.inboxId || conversation?.inbox_id,
    callSid: call.callSid,
  });

  if (result) {
    if (mainCardState.value === VOICE_CALL_DIRECTION.INCOMING) {
      setCallOverlayExpanded(false);
    }
    if (conversation) {
      router.push({
        name: 'inbox_conversation',
        params: { conversation_id: call.conversationId },
      });
    }
  }
};

const handleSaveNote = async () => {
  const call = activeCall.value || primaryIncomingCall.value;
  if (!call?.conversationId) return;
  await saveQuickNote({
    conversationId: call.conversationId,
    content: noteText.value,
  });
};

const updateWidgetPos = pos => {
  callWidgetPos.value = pos;
};

const updateNoteText = value => {
  noteText.value = value;
};

watch(
  () => incomingCalls.value[0],
  call => {
    if (
      call?.callDirection === VOICE_CALL_DIRECTION.OUTBOUND &&
      call?.provider !== VOICE_CALL_PROVIDERS.WHATSAPP &&
      !hasActiveCall.value &&
      !call?.isSimulated &&
      WindowVisibilityHelper.isWindowVisible()
    ) {
      handleJoinCall(call);
    }
  },
  { immediate: true }
);

const ringtone = new Audio(RINGTONE_URL);
ringtone.loop = true;
ringtone.volume = 1;

const stopRingtone = () => {
  ringtone.pause();
  ringtone.currentTime = 0;
};

const ringingInbound = computed(() =>
  incomingCalls.value.some(
    call =>
      call.callDirection !== VOICE_CALL_DIRECTION.OUTBOUND && !call.isSimulated
  )
);

watch(
  () => ringingInbound.value && !hasActiveCall.value,
  shouldRing => {
    if (shouldRing) {
      ringtone.play().catch(() => {});
    } else {
      stopRingtone();
    }
  },
  { immediate: true }
);

onBeforeUnmount(stopRingtone);
</script>

<template>
  <IncomingCallOverlay
    v-if="showIncomingOverlay"
    :call-info="getCallInfo(primaryIncomingCall)"
    @accept="handleJoinCall(primaryIncomingCall)"
    @reject="rejectIncomingCall(primaryIncomingCall?.callSid)"
    @minimize="setCallOverlayExpanded(false)"
  />

  <OngoingCallOverlay
    v-if="showOngoingOverlay"
    :call-info="getCallInfo(primaryActiveCall)"
    :state="mainCardState"
    :duration="hasActiveCall ? formattedCallDuration : ''"
    :is-muted="isMuted"
    :is-speaker-on="isSpeakerOn"
    :is-note-modal-open="isNoteModalOpen"
    :note-text="noteText"
    @end="handleEndCall"
    @toggle-mute="toggleMute"
    @toggle-speaker="toggleSpeaker"
    @trigger-note="triggerNote"
    @close-note="closeNote"
    @save-note="handleSaveNote"
    @update:note-text="updateNoteText"
    @minimize="setCallOverlayExpanded(false)"
  />

  <CallCard
    v-if="showMiniWidget"
    :call="activeCall || primaryIncomingCall"
    :state="mainCardState"
    :call-info="getCallInfo(activeCall || primaryIncomingCall)"
    :duration="hasActiveCall ? formattedCallDuration : ''"
    :is-muted="isMuted"
    :show-mute="hasActiveCall"
    :widget-pos="callWidgetPos"
    @update:widget-pos="updateWidgetPos"
    @accept="handleJoinCall(primaryIncomingCall)"
    @reject="rejectIncomingCall(primaryIncomingCall?.callSid)"
    @end="handleEndCall"
    @toggle-mute="toggleMute"
    @go-to-conversation="goToConversation(activeCall || primaryIncomingCall)"
  />
</template>
