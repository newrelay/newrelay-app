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
import { RelayButton, RelayTooltip } from 'dashboard/components-next/relay';
import CannedResponsesDropdown from './CannedResponsesDropdown.vue';
import EmojiInput from 'shared/components/emoji/EmojiInput.vue';
import { vOnClickOutside } from '@vueuse/components';

const TOOLBAR_BUTTON_CLASS =
  'size-8 flex items-center justify-center rounded-md hover:bg-accent text-muted-foreground hover:text-foreground transition-colors focus-visible:outline-none';

export default {
  name: 'InboxReplyBottomPanel',
  components: {
    RelayButton,
    RelayTooltip,
    FileUpload,
    VideoCallButton,
    EmojiInput,
    CannedResponsesDropdown,
  },
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
    'selectCannedResponse',
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
      toolbarButtonClass: TOOLBAR_BUTTON_CLASS,
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
    audioRecorderButtonClass() {
      return this.isRecordingAudio
        ? 'size-8 flex items-center justify-center rounded-md bg-destructive/10 text-destructive transition-colors hover:bg-destructive/20 hover:text-destructive focus-visible:outline-none'
        : this.toolbarButtonClass;
    },
    aiReplyButtonClass() {
      return this.isCopilotActive
        ? 'size-8 flex items-center justify-center rounded-md bg-primary/10 text-primary transition-colors hover:bg-primary/20 hover:text-primary focus-visible:outline-none'
        : 'size-8 flex items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary focus-visible:outline-none';
    },
  },
  mounted() {
    ActiveStorage.start();
  },
  methods: {
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between overflow-visible rounded-b-xl border-t border-border bg-muted/20 px-3 py-2"
  >
    <div class="flex flex-wrap items-center gap-1">
      <!-- Emoji -->
      <RelayTooltip
        v-if="!isEditorDisabled"
        :content="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        side="top"
      >
        <div class="relative flex items-center justify-center">
          <button
            type="button"
            :class="toolbarButtonClass"
            @click="handleEmojiPickerClick"
          >
            <span class="i-lucide-smile size-4 shrink-0" />
          </button>
          <EmojiInput
            v-if="showEmojiPicker"
            v-on-click-outside="hideEmojiPicker"
            class="!bottom-full !left-0 !right-auto !top-auto !mb-2 z-50"
            :on-click="onEmojiSelect"
          />
        </div>
      </RelayTooltip>

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
        <RelayTooltip
          v-if="!isEditorDisabled"
          :content="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          side="top"
        >
          <button type="button" :class="toolbarButtonClass">
            <span class="i-lucide-paperclip size-4 shrink-0" />
          </button>
        </RelayTooltip>
      </FileUpload>

      <RelayTooltip
        v-if="showAudioRecorderButton"
        :content="$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ICON')"
        side="top"
      >
        <button
          type="button"
          :class="audioRecorderButtonClass"
          @click="toggleAudioRecorder"
        >
          <span
            class="size-4 shrink-0"
            :class="!isRecordingAudio ? 'i-lucide-mic' : 'i-lucide-mic-off'"
          />
        </button>
      </RelayTooltip>

      <button
        v-if="showAudioPlayStopButton"
        type="button"
        class="flex h-8 items-center gap-1 rounded-md px-2 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
        @click="toggleAudioRecorderPlayPause"
      >
        <span :class="audioRecorderPlayStopIcon" class="size-4" />
        {{ recordingAudioDurationText }}
      </button>

      <RelayTooltip
        v-if="showMessageSignatureButton"
        :content="signatureToggleTooltip"
        side="top"
      >
        <button
          type="button"
          :class="toolbarButtonClass"
          @click="toggleMessageSignature"
        >
          <span class="i-lucide-pen-line size-4 shrink-0" />
        </button>
      </RelayTooltip>

      <!-- Video Call -->
      <VideoCallButton
        v-if="!isEditorDisabled"
        compact
        plain
        :conversation-id="conversationId"
      />

      <RelayTooltip
        v-if="enableWhatsAppTemplates"
        :content="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        side="top"
      >
        <button
          type="button"
          :class="toolbarButtonClass"
          @click="$emit('selectWhatsappTemplate')"
        >
          <span class="i-lucide-file-text size-4 shrink-0" />
        </button>
      </RelayTooltip>

      <!-- Content Templates -->
      <div
        v-if="enableContentTemplates"
        class="group relative flex items-center justify-center"
      >
        <button
          type="button"
          :class="toolbarButtonClass"
          @click="$emit('selectContentTemplate')"
        >
          <span class="i-lucide-file-text size-4 shrink-0" />
        </button>
      </div>

      <!-- Canned Responses -->
      <CannedResponsesDropdown
        v-if="showCannedResponsesButton"
        plain
        :button-class="toolbarButtonClass"
        @select="$emit('selectCannedResponse', $event)"
      />

      <RelayTooltip
        v-if="showQuotedReplyToggle"
        :content="quotedReplyToggleTooltip"
        side="top"
      >
        <button
          type="button"
          :class="[
            toolbarButtonClass,
            quotedReplyEnabled ? 'bg-muted text-foreground' : '',
          ]"
          :aria-pressed="quotedReplyEnabled"
          @click="$emit('toggleQuotedReply')"
        >
          <span class="i-lucide-quote size-4 shrink-0" />
        </button>
      </RelayTooltip>

      <!-- Insert Article -->
      <div
        v-if="enableInsertArticleInReply && !isEditorDisabled"
        class="group relative flex items-center justify-center"
      >
        <button
          type="button"
          :class="toolbarButtonClass"
          @click="$emit('toggleInsertArticle')"
        >
          <span class="i-lucide-file-text size-4 shrink-0" />
        </button>
      </div>

      <div
        v-if="captainTasksEnabled && !isEditorDisabled && !isOnPrivateNote"
        class="mx-1 h-4 w-px bg-border"
      />

      <RelayTooltip
        v-if="captainTasksEnabled && !isEditorDisabled && !isOnPrivateNote"
        :content="$t('CONVERSATION.REPLYBOX.AI_REPLY')"
        side="top"
      >
        <button
          type="button"
          :class="aiReplyButtonClass"
          @click="$emit('toggleCopilot')"
        >
          <span class="i-lucide-wand-sparkles size-4 shrink-0" />
        </button>
      </RelayTooltip>

      <transition name="modal-fade">
        <div
          v-show="uploadRef && uploadRef.dropActive"
          class="fixed inset-0 z-20 flex h-full w-full flex-col items-center justify-center gap-2 bg-background/80 text-foreground backdrop-blur-[8px]"
        >
          <span class="i-lucide-cloud-upload size-10" />
          <h4 class="break-words text-2xl font-medium capitalize">
            {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
    </div>

    <div class="flex items-center gap-2">
      <RelayButton
        type="submit"
        variant="default"
        class="h-8 gap-1.5 px-4 text-sm font-semibold shadow-xs"
        :class="
          isNote ? 'bg-warning text-primary-foreground hover:bg-warning/90' : ''
        "
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
