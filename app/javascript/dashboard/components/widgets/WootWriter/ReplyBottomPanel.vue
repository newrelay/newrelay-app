<script>
import { ref } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import FileUpload from 'vue-upload-component';
import * as ActiveStorage from 'activestorage';
import inboxMixin from 'shared/mixins/inboxMixin';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import VideoCallButton from '../VideoCallButton.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { mapGetters } from 'vuex';
import { RelayButton } from 'dashboard/components-next/relay';
import CannedResponsesDropdown from '../conversation/CannedResponsesDropdown.vue';
import EmojiInput from 'shared/components/emoji/EmojiInput.vue';
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'ReplyBottomPanel',
  components: { RelayButton, FileUpload, VideoCallButton, EmojiInput, CannedResponsesDropdown },
  directives: { OnClickOutside: vOnClickOutside },
  mixins: [inboxMixin],
  props: {
    isNote: {
      type: Boolean,
      default: false,
    },
    onSend: {
      type: Function,
      default: () => {},
    },
    sendButtonText: {
      type: String,
      default: '',
    },
    recordingAudioDurationText: {
      type: String,
      default: '00:00',
    },
    // inbox prop is used in /mixins/inboxMixin,
    // remove this props when refactoring to composable if not needed
    // eslint-disable-next-line vue/no-unused-properties
    inbox: {
      type: Object,
      default: () => ({}),
    },
    showFileUpload: {
      type: Boolean,
      default: false,
    },
    showAudioRecorder: {
      type: Boolean,
      default: false,
    },
    onFileUpload: {
      type: Function,
      default: () => {},
    },
    toggleEmojiPicker: {
      type: Function,
      default: () => {},
    },
    showEmojiPicker: {
      type: Boolean,
      default: false,
    },
    onEmojiSelect: {
      type: Function,
      default: () => {},
    },
    toggleAudioRecorder: {
      type: Function,
      default: () => {},
    },
    toggleAudioRecorderPlayPause: {
      type: Function,
      default: () => {},
    },
    isRecordingAudio: {
      type: Boolean,
      default: false,
    },
    recordingAudioState: {
      type: String,
      default: '',
    },
    isSendDisabled: {
      type: Boolean,
      default: false,
    },
    isOnPrivateNote: {
      type: Boolean,
      default: false,
    },
    enableMultipleFileUpload: {
      type: Boolean,
      default: true,
    },
    enableWhatsAppTemplates: {
      type: Boolean,
      default: false,
    },
    enableContentTemplates: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: Number,
      required: true,
    },
    // eslint-disable-next-line vue/no-unused-properties
    message: {
      type: String,
      default: '',
    },
    newConversationModalActive: {
      type: Boolean,
      default: false,
    },
    portalSlug: {
      type: String,
      required: true,
    },
    conversationType: {
      type: String,
      default: '',
    },
    showQuotedReplyToggle: {
      type: Boolean,
      default: false,
    },
    quotedReplyEnabled: {
      type: Boolean,
      default: false,
    },
    isEditorDisabled: {
      type: Boolean,
      default: false,
    },
    isCopilotActive: {
      type: Boolean,
      default: false,
    },
  },
  emits: [
    'toggleInsertArticle',
    'selectWhatsappTemplate',
    'selectContentTemplate',
    'toggleQuotedReply',
    'togglePrivateNote',
    'selectCannedResponse',
    'openLogCall',
    'openMeeting',
  ],
  setup(props) {
    const { setSignatureFlagForInbox, fetchSignatureFlagFromUISettings } =
      useUISettings();

    const uploadRef = ref(false);

    const keyboardEvents = {
      '$mod+Alt+KeyA': {
        action: () => {
          // Skip if editor is disabled (e.g., WhatsApp 24-hour window expired)
          if (props.isEditorDisabled) return;

          // TODO: This is really hacky, we need to replace the file picker component with
          // a custom one, where the logic and the component markup is isolated.
          // Once we have the custom component, we can remove the hacky logic below.

          const uploadTriggerButton = document.querySelector(
            '#conversationAttachment'
          );
          if (uploadTriggerButton) uploadTriggerButton.click();
        },
        allowOnFocusedInput: true,
      },
    };

    useKeyboardEvents(keyboardEvents);

    const handleEmojiPickerClick = e => {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      if (props.toggleEmojiPicker) {
        props.toggleEmojiPicker();
      }
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
      toolbarIconButtonClass:
        'h-8 w-8 shrink-0 p-0 min-h-8 min-w-8 text-muted-foreground hover:text-foreground',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      uiFlags: 'integrations/getUIFlags',
    }),
    wrapClass() {
      return {
        'is-note-mode': this.isNote,
      };
    },
    showAttachButton() {
      if (this.isEditorDisabled) return false;
      return this.showFileUpload || this.isNote;
    },
    showAudioRecorderButton() {
      if (this.isEditorDisabled) return false;
      if (this.isALineChannel || this.isATiktokChannel) {
        return false;
      }
      // Disable audio recorder for safari browser as recording is not supported
      // const isSafari = /^((?!chrome|android|crios|fxios).)*safari/i.test(
      //   navigator.userAgent
      // );

      return (
        this.isFeatureEnabledonAccount(
          this.accountId,
          FEATURE_FLAGS.VOICE_RECORDER
        ) && this.showAudioRecorder
        // !isSafari
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
      if (this.isOnPrivateNote) {
        return getAllowedFileTypesByChannel();
      }

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
        // playing paused recording stopped inactive destroyed
        case 'playing':
          return 'i-ph-pause';
        case 'paused':
          return 'i-ph-play';
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
      // channelType is sourced from inboxMixin
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
    isFetchingAppIntegrations() {
      return this.uiFlags.isFetching;
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
  },
  mounted() {
    ActiveStorage.start();
  },
  methods: {
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
    },
    toggleInsertArticle() {
      this.$emit('toggleInsertArticle');
    },
    togglePrivateNote() {
      this.$emit('togglePrivateNote');
    },

  },
};
</script>

<template>
  <div
    class="px-3 py-2 flex items-center justify-between border-t border-border bg-muted/20 overflow-visible"
  >
    <div class="flex items-center gap-1 flex-wrap">
      <!-- Attach -->
      <FileUpload
        v-if="showAttachButton"
        ref="uploadRef"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
        input-id="conversationAttachment"
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
      <CannedResponsesDropdown
        v-if="showCannedResponsesButton"
        :button-class="toolbarIconButtonClass"
        @select="$emit('selectCannedResponse', $event)"
      />

      <!-- Log Call -->
      <RelayButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_LOG_CALL')"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="$emit('openLogCall')"
      >
        <span class="i-lucide-phone size-4 shrink-0" />
      </RelayButton>

      <!-- Meeting -->
      <RelayButton
        v-if="!isEditorDisabled"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_MEETING')"
        variant="ghost"
        :class="toolbarIconButtonClass"
        @click="$emit('openMeeting')"
      >
        <span class="i-lucide-calendar size-4 shrink-0" />
      </RelayButton>

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

      <!-- Audio Play/Pause -->
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
        @click="toggleInsertArticle"
      >
        <span class="i-lucide-file-text size-4 shrink-0" />
      </RelayButton>

      <!-- Private Note -->
      <RelayButton
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.PRIVATE_NOTE')"
        variant="ghost"
        :class="[
          toolbarIconButtonClass,
          isOnPrivateNote
            ? 'bg-amber-500/10 text-amber-600 hover:bg-amber-500/20 hover:text-amber-700'
            : '',
        ]"
        :aria-pressed="isOnPrivateNote"
        @click="togglePrivateNote"
      >
        <span class="i-lucide-sticky-note size-4 shrink-0" />
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

    <!-- Right Side: Send Button -->
    <div class="flex items-center">
      <RelayButton
        type="submit"
        variant="default"
        class="px-4 h-8 gap-2 font-semibold shadow-xs"
        :class="isNote ? 'bg-amber-500 text-white hover:bg-amber-600' : ''"
        :disabled="isSendDisabled"
        @click="onSend"
      >
        {{ sendButtonText }}
        <span class="i-lucide-corner-down-left size-3.5 opacity-70" />
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
