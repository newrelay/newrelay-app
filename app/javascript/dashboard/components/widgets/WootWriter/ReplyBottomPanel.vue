<script>
import { RelayButton, RelayTooltip } from 'dashboard/components-next/relay';
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
import CannedResponsesDropdown from '../conversation/CannedResponsesDropdown.vue';
import EmojiInput from 'shared/components/emoji/EmojiInput.vue';
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'ReplyBottomPanel',
  components: {
    RelayTooltip,
    RelayButton,
    FileUpload,
    VideoCallButton,
    EmojiInput,
    CannedResponsesDropdown,
  },
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
        'h-8 w-8 shrink-0 p-0 min-h-8 min-w-8 border-transparent text-muted-foreground hover:border-transparent hover:bg-accent hover:text-foreground focus-visible:outline-none',
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
    isAudioPlayback() {
      return (
        this.recordingAudioState === 'playing' ||
        this.recordingAudioState === 'paused'
      );
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
    class="px-3 py-1.5 flex items-center justify-between border-t border-border bg-muted/20 overflow-visible"
  >
    <div class="flex items-center gap-1 flex-wrap">
      <!-- Attach -->
      <FileUpload
        v-if="showAttachButton"
        ref="uploadRef"
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
        <RelayTooltip
          v-if="!isEditorDisabled"
          :content="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          side="top"
          align="end"
        >
          <RelayButton variant="ghost" :class="toolbarIconButtonClass">
            <span class="i-lucide-paperclip size-4 shrink-0" />
          </RelayButton>
        </RelayTooltip>
      </FileUpload>

      <!-- Emoji -->
      <div
        v-if="!isEditorDisabled"
        class="relative flex items-center justify-center"
      >
        <RelayTooltip
          :content="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
          side="top"
          align="end"
        >
          <RelayButton
            variant="ghost"
            :class="toolbarIconButtonClass"
            @click="handleEmojiPickerClick"
          >
            <span class="i-lucide-smile size-4 shrink-0" />
          </RelayButton>
        </RelayTooltip>
        <EmojiInput
          v-if="showEmojiPicker"
          v-on-click-outside="hideEmojiPicker"
          class="!left-0 !right-auto !top-auto !bottom-full !mb-2 z-50"
          :on-click="onEmojiSelect"
        />
      </div>

      <!-- WhatsApp Templates -->
      <RelayTooltip
        :content="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        side="top"
        align="end"
      >
        <RelayButton
          v-if="enableWhatsAppTemplates"
          variant="ghost"
          :class="toolbarIconButtonClass"
          @click="$emit('selectWhatsappTemplate')"
        >
          <span class="i-lucide-file-text size-4 shrink-0" />
        </RelayButton>
      </RelayTooltip>

      <!-- Content Templates -->
      <RelayTooltip content="Content Templates" side="top" align="end">
        <RelayButton
          v-if="enableContentTemplates"
          variant="ghost"
          :class="toolbarIconButtonClass"
          @click="$emit('selectContentTemplate')"
        >
          <span class="i-lucide-file-text size-4 shrink-0" />
        </RelayButton>
      </RelayTooltip>

      <!-- Canned Responses -->
      <CannedResponsesDropdown
        v-if="showCannedResponsesButton"
        :button-class="toolbarIconButtonClass"
        @select="$emit('selectCannedResponse', $event)"
      />

      <!-- Log Call -->
      <RelayTooltip
        :content="$t('CONVERSATION.REPLYBOX.TIP_LOG_CALL')"
        side="top"
        align="end"
      >
        <RelayButton
          v-if="!isEditorDisabled"
          variant="ghost"
          :class="toolbarIconButtonClass"
          @click="$emit('openLogCall')"
        >
          <span class="i-lucide-phone size-4 shrink-0" />
        </RelayButton>
      </RelayTooltip>

      <!-- Audio Recorder -->
      <RelayTooltip
        :content="$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ICON')"
        side="top"
        align="end"
      >
        <RelayButton
          v-if="showAudioRecorderButton"
          variant="ghost"
          :class="[
            toolbarIconButtonClass,
            isRecordingAudio
              ? 'bg-destructive/10 text-destructive hover:bg-destructive/20 hover:text-destructive'
              : '',
          ]"
          @click="toggleAudioRecorder"
        >
          <span
            class="size-4 shrink-0"
            :class="!isRecordingAudio ? 'i-lucide-mic' : 'i-lucide-mic-off'"
          />
        </RelayButton>
      </RelayTooltip>

      <!-- Audio Play/Pause -->
      <RelayButton
        v-if="showAudioPlayStopButton"
        variant="ghost"
        :class="
          isAudioPlayback
            ? 'h-8 px-2 text-muted-foreground border border-border hover:border-transparent'
            : 'h-8 px-3 rounded-md bg-warning text-foreground font-medium text-[13px] flex items-center gap-2 border-none shadow-sm hover:bg-warning/90 hover:text-foreground'
        "
        @click="
          isAudioPlayback
            ? toggleAudioRecorderPlayPause()
            : toggleAudioRecorder()
        "
      >
        <span
          class="shrink-0"
          :class="
            isAudioPlayback
              ? [audioRecorderPlayStopIcon, 'size-4']
              : 'i-lucide-square size-3.5 fill-current'
          "
        />
        {{ recordingAudioDurationText }}
      </RelayButton>

      <!-- Signature -->
      <RelayTooltip :content="signatureToggleTooltip" side="top" align="end">
        <RelayButton
          v-if="showMessageSignatureButton"
          variant="ghost"
          :class="toolbarIconButtonClass"
          @click="toggleMessageSignature"
        >
          <span class="i-lucide-pen-line size-4 shrink-0" />
        </RelayButton>
      </RelayTooltip>

      <!-- Video Call -->
      <VideoCallButton
        v-if="!isEditorDisabled"
        compact
        :conversation-id="conversationId"
      />

      <!-- Quoted Reply -->
      <RelayTooltip :content="quotedReplyToggleTooltip" side="top" align="end">
        <RelayButton
          v-if="showQuotedReplyToggle"
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
      </RelayTooltip>

      <!-- Insert Article -->
      <RelayTooltip
        :content="$t('HELP_CENTER.ARTICLE_SEARCH.OPEN_ARTICLE_SEARCH')"
        side="top"
        align="end"
      >
        <RelayButton
          v-if="enableInsertArticleInReply && !isEditorDisabled"
          variant="ghost"
          :class="toolbarIconButtonClass"
          @click="toggleInsertArticle"
        >
          <span class="i-lucide-file-text size-4 shrink-0" />
        </RelayButton>
      </RelayTooltip>

      <!-- Private Note -->
      <RelayTooltip
        :content="$t('CONVERSATION.REPLYBOX.PRIVATE_NOTE')"
        side="top"
        align="end"
      >
        <RelayButton
          variant="ghost"
          :class="[
            toolbarIconButtonClass,
            isOnPrivateNote
              ? 'bg-warning/10 text-warning hover:bg-warning/20 hover:text-warning'
              : '',
          ]"
          :aria-pressed="isOnPrivateNote"
          @click="togglePrivateNote"
        >
          <span class="i-lucide-sticky-note size-4 shrink-0" />
        </RelayButton>
      </RelayTooltip>

      <transition name="modal-fade">
        <div
          v-show="uploadRef && uploadRef.dropActive"
          class="flex fixed top-0 right-0 bottom-0 left-0 z-20 flex-col gap-2 justify-center items-center w-full h-full text-foreground bg-background/80 backdrop-blur-[8px]"
        >
          <span class="i-lucide-cloud-upload size-10" />
          <h4 class="capitalize text-2xl break-words font-medium">
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
        size="sm"
        class="px-4 h-8 min-h-8 gap-2 font-semibold shadow-xs"
        :class="
          isNote ? 'bg-warning text-primary-foreground hover:bg-warning/90' : ''
        "
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
