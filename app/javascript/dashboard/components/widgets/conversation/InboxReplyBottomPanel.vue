<script>
import { ref } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useCaptain } from 'dashboard/composables/useCaptain';
import FileUpload from 'vue-upload-component';
import * as ActiveStorage from 'activestorage';
import inboxMixin from 'shared/mixins/inboxMixin';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import VideoCallButton from '../VideoCallButton.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { mapGetters } from 'vuex';
import { RelayButton } from 'dashboard/components-next/relay';
import EmojiInput from 'shared/components/emoji/EmojiInput.vue';
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'InboxReplyBottomPanel',
  components: { RelayButton, FileUpload, VideoCallButton, EmojiInput },
  directives: { OnClickOutside: vOnClickOutside },
  mixins: [inboxMixin],
  props: {
    isNote: { type: Boolean, default: false },
    onSend: { type: Function, default: () => {} },
    sendButtonText: { type: String, default: '' },
    recordingAudioDurationText: { type: String, default: '00:00' },
    // eslint-disable-next-line vue/no-unused-properties
    inbox: { type: Object, default: () => ({}) },
    showFileUpload: { type: Boolean, default: false },
    showAudioRecorder: { type: Boolean, default: false },
    onFileUpload: { type: Function, default: () => {} },
    toggleEmojiPicker: { type: Function, default: () => {} },
    showEmojiPicker: { type: Boolean, default: false },
    onEmojiSelect: { type: Function, default: () => {} },
    toggleAudioRecorder: { type: Function, default: () => {} },
    toggleAudioRecorderPlayPause: { type: Function, default: () => {} },
    isRecordingAudio: { type: Boolean, default: false },
    recordingAudioState: { type: String, default: '' },
    isSendDisabled: { type: Boolean, default: false },
    isOnPrivateNote: { type: Boolean, default: false },
    enableMultipleFileUpload: { type: Boolean, default: true },
    enableWhatsAppTemplates: { type: Boolean, default: false },
    enableContentTemplates: { type: Boolean, default: false },
    conversationId: { type: Number, required: true },
    newConversationModalActive: { type: Boolean, default: false },
    portalSlug: { type: String, required: true },
    conversationType: { type: String, default: '' },
    showQuotedReplyToggle: { type: Boolean, default: false },
    quotedReplyEnabled: { type: Boolean, default: false },
    isEditorDisabled: { type: Boolean, default: false },
    isCopilotActive: { type: Boolean, default: false },
  },
  emits: [
    'toggleInsertArticle',
    'selectWhatsappTemplate',
    'selectContentTemplate',
    'toggleQuotedReply',
    'openCannedResponses',
    'toggleCopilot',
  ],
  setup(props) {
    const { setSignatureFlagForInbox, fetchSignatureFlagFromUISettings } =
      useUISettings();
    const { captainTasksEnabled } = useCaptain();
    const uploadRef = ref(false);

    useKeyboardEvents({
      '$mod+Alt+KeyA': {
        action: () => {
          if (props.isEditorDisabled) return;
          const uploadTriggerButton = document.querySelector(
            '#inboxConversationAttachment'
          );
          if (uploadTriggerButton) uploadTriggerButton.click();
        },
        allowOnFocusedInput: true,
      },
    });

    const handleEmojiPickerClick = e => {
      e?.preventDefault?.();
      e?.stopPropagation?.();
      props.toggleEmojiPicker?.();
    };

    const hideEmojiPicker = () => {
      if (props.showEmojiPicker && props.toggleEmojiPicker) {
        props.toggleEmojiPicker();
      }
    };

    return {
      setSignatureFlagForInbox,
      fetchSignatureFlagFromUISettings,
      uploadRef,
      handleEmojiPickerClick,
      hideEmojiPicker,
      captainTasksEnabled,
      toolbarIconButtonClass:
        'h-8 w-8 shrink-0 p-0 min-h-8 min-w-8 text-muted-foreground hover:text-foreground',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    showAttachButton() {
      if (this.isEditorDisabled) return false;
      return this.showFileUpload || this.isNote;
    },
    showAudioRecorderButton() {
      if (this.isEditorDisabled) return false;
      if (this.isALineChannel || this.isATiktokChannel) return false;
      return (
        this.isFeatureEnabledonAccount(
          this.accountId,
          FEATURE_FLAGS.VOICE_RECORDER
        ) && this.showAudioRecorder
      );
    },
    showAudioPlayStopButton() {
      if (this.isEditorDisabled) return false;
      return this.showAudioRecorder && this.isRecordingAudio;
    },
    isInstagramDM() {
      return this.conversationType === 'instagram_direct_message';
    },
    allowedFileTypes() {
      if (this.isOnPrivateNote) return getAllowedFileTypesByChannel();
      let channelType = this.channelType || this.inbox?.channel_type;
      if (this.isAnInstagramChannel || this.isInstagramDM) {
        channelType = INBOX_TYPES.INSTAGRAM;
      }
      return getAllowedFileTypesByChannel({
        channelType,
        medium: this.inbox?.medium,
      });
    },
    enableDragAndDrop() {
      return !this.newConversationModalActive;
    },
    audioRecorderPlayStopIcon() {
      switch (this.recordingAudioState) {
        case 'playing':
          return 'i-ph-pause';
        case 'paused':
        case 'stopped':
          return 'i-ph-play';
        default:
          return 'i-ph-stop';
      }
    },
    showMessageSignatureButton() {
      if (this.isEditorDisabled) return false;
      return !this.isOnPrivateNote;
    },
    sendWithSignature() {
      return this.fetchSignatureFlagFromUISettings(this.channelType);
    },
    signatureToggleTooltip() {
      return this.sendWithSignature
        ? this.$t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
        : this.$t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
    },
    enableInsertArticleInReply() {
      return this.portalSlug;
    },
    quotedReplyToggleTooltip() {
      return this.quotedReplyEnabled
        ? this.$t('CONVERSATION.REPLYBOX.QUOTED_REPLY.DISABLE_TOOLTIP')
        : this.$t('CONVERSATION.REPLYBOX.QUOTED_REPLY.ENABLE_TOOLTIP');
    },
    showCannedResponsesButton() {
      if (
        this.isEditorDisabled ||
        this.isOnPrivateNote ||
        this.isCopilotActive
      ) {
        return false;
      }
      return !this.enableWhatsAppTemplates && !this.enableContentTemplates;
    },
    showSendShortcutIcon() {
      return !this.isNote;
    },
  },
  mounted() {
    ActiveStorage.start();
  },
  methods: {
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
    },
    openCannedResponses() {
      this.$emit('openCannedResponses');
    },
  },
};
</script>

<template>
  <div
    class="px-3 py-2.5 flex items-center justify-between border-t border-border bg-muted/5 rounded-b-xl overflow-visible"
  >
    <div class="flex items-center gap-1 flex-wrap">
      <!-- Emoji -->
      <div
        v-if="!isEditorDisabled"
        class="relative flex items-center justify-center"
      >
        <RelayButton
          v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
          variant="ghost"
          :class="toolbarIconButtonClass"
          @click="handleEmojiPickerClick"
        >
          <span class="i-lucide-smile size-4 shrink-0" />
        </RelayButton>
        <EmojiInput
          v-if="showEmojiPicker"
          v-on-click-outside="hideEmojiPicker"
          class="!left-0 !right-auto !top-auto !bottom-full !mb-2 z-50"
          :on-click="onEmojiSelect"
        />
      </div>

      <!-- Attach -->
      <FileUpload
        v-if="showAttachButton"
        ref="uploadRef"
        input-id="inboxConversationAttachment"
        :size="4096 * 4096"
        :accept="allowedFileTypes"
        :multiple="enableMultipleFileUpload"
        :drop="enableDragAndDrop"
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        class="inline-flex"
        @input-file="onFileUpload"
      >
        <RelayButton
          v-if="!isEditorDisabled"
          v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          variant="ghost"
          :class="toolbarIconButtonClass"
        >
          <span class="i-lucide-paperclip size-4 shrink-0" />
        </RelayButton>
      </FileUpload>

      <!-- Audio Recorder -->
      <RelayButton
        v-if="showAudioRecorderButton"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ICON')"
        variant="ghost"
        :class="[
          toolbarIconButtonClass,
          isRecordingAudio
            ? 'bg-red-500/10 text-red-500 hover:bg-red-500/20 hover:text-red-600'
            : '',
        ]"
        @click="toggleAudioRecorder"
      >
        <span
          class="size-4 shrink-0"
          :class="!isRecordingAudio ? 'i-lucide-mic' : 'i-lucide-mic-off'"
        />
      </RelayButton>

      <RelayButton
        v-if="showAudioPlayStopButton"
        variant="ghost"
        class="h-8 px-2 text-muted-foreground"
        @click="toggleAudioRecorderPlayPause"
      >
        <span :class="audioRecorderPlayStopIcon" class="size-4" />
        {{ recordingAudioDurationText }}
      </RelayButton>

      <!-- Signature -->
      <RelayButton
        v-if="showMessageSignatureButton"
        v-tooltip.top-end="signatureToggleTooltip"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="toggleMessageSignature"
      >
        <span class="i-lucide-pen-line size-4 shrink-0" />
      </RelayButton>

      <!-- Video Call -->
      <VideoCallButton
        v-if="!isEditorDisabled"
        compact
        :conversation-id="conversationId"
      />

      <!-- WhatsApp Templates -->
      <RelayButton
        v-if="enableWhatsAppTemplates"
        v-tooltip.top-end="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="$emit('selectWhatsappTemplate')"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </RelayButton>

      <!-- Content Templates -->
      <RelayButton
        v-if="enableContentTemplates"
        v-tooltip.top-end="'Content Templates'"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="$emit('selectContentTemplate')"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </RelayButton>

      <!-- Canned Responses -->
      <RelayButton
        v-if="showCannedResponsesButton"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_CANNED_ICON')"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="openCannedResponses"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </RelayButton>

      <!-- Quoted Reply -->
      <RelayButton
        v-if="showQuotedReplyToggle"
        v-tooltip.top-end="quotedReplyToggleTooltip"
        :variant="quotedReplyEnabled ? 'secondary' : 'ghost'"
        :class="[
          toolbarIconButtonClass,
          quotedReplyEnabled ? 'bg-muted text-foreground' : '',
        ]"
        :aria-pressed="quotedReplyEnabled"
        @click="$emit('toggleQuotedReply')"
      >
        <span class="i-lucide-quote size-4 shrink-0" />
      </RelayButton>

      <!-- Insert Article -->
      <RelayButton
        v-if="enableInsertArticleInReply && !isEditorDisabled"
        v-tooltip.top-end="$t('HELP_CENTER.ARTICLE_SEARCH.OPEN_ARTICLE_SEARCH')"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="$emit('toggleInsertArticle')"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </RelayButton>

      <div
        v-if="captainTasksEnabled && !isEditorDisabled && !isOnPrivateNote"
        class="w-px h-4 bg-border mx-1"
      />

      <!-- AI Reply -->
      <RelayButton
        v-if="captainTasksEnabled && !isEditorDisabled && !isOnPrivateNote"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.AI_REPLY')"
        variant="ghost"
        :class="[
          toolbarIconButtonClass,
          isCopilotActive
            ? 'bg-primary/10 text-primary hover:bg-primary/20 hover:text-primary'
            : 'hover:bg-primary/10 hover:text-primary',
        ]"
        @click="$emit('toggleCopilot')"
      >
        <span class="i-lucide-wand-sparkles size-4 shrink-0" />
      </RelayButton>

      <transition name="modal-fade">
        <div
          v-show="uploadRef && uploadRef.dropActive"
          class="flex fixed top-0 right-0 bottom-0 left-0 z-20 flex-col gap-2 justify-center items-center w-full h-full text-foreground bg-background/80 backdrop-blur-sm"
        >
          <span class="i-lucide-cloud-upload size-10" />
          <h4 class="text-2xl break-words font-medium">
            {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
    </div>

    <div class="flex items-center gap-2">
      <RelayButton
        type="submit"
        variant="default"
        class="h-8 px-4 gap-1.5 font-semibold text-sm shadow-xs"
        :class="isNote ? 'bg-amber-500 text-white hover:bg-amber-600' : ''"
        :disabled="isSendDisabled"
        @click="onSend"
      >
        {{ sendButtonText }}
        <span
          v-if="showSendShortcutIcon"
          class="i-lucide-corner-down-left size-3.5 opacity-70"
        />
      </RelayButton>
    </div>
  </div>
</template>

<style lang="scss" scoped>
:deep(.file-uploads) {
  label {
    cursor: pointer;
  }
}
</style>
