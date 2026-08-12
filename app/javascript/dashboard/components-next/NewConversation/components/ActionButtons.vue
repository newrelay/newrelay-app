<script setup>
import { defineAsyncComponent, ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useFileUpload } from 'dashboard/composables/useFileUpload';
import { vOnClickOutside } from '@vueuse/components';
import { useEventListener } from '@vueuse/core';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import FileUpload from 'vue-upload-component';
import WhatsAppOptions from './WhatsAppOptions.vue';
import ContentTemplateSelector from './ContentTemplateSelector.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  attachedFiles: { type: Array, default: () => [] },
  isWhatsappInbox: { type: Boolean, default: false },
  isEmailOrWebWidgetInbox: { type: Boolean, default: false },
  isTwilioSmsInbox: { type: Boolean, default: false },
  isTwilioWhatsAppInbox: { type: Boolean, default: false },
  // eslint-disable-next-line vue/no-unused-properties
  messageTemplates: { type: Array, default: () => [] },
  channelType: { type: String, default: '' },
  isLoading: { type: Boolean, default: false },
  disableSendButton: { type: Boolean, default: false },
  hasSelectedInbox: { type: Boolean, default: false },
  hasNoInbox: { type: Boolean, default: false },
  isDropdownActive: { type: Boolean, default: false },
  messageSignature: { type: String, default: '' },
  inboxId: { type: Number, default: null },
  voiceEnabled: { type: Boolean, default: false },
  showFormatting: { type: Boolean, default: false },
});

const emit = defineEmits([
  'discard',
  'sendMessage',
  'sendWhatsappMessage',
  'sendTwilioMessage',
  'insertEmoji',
  'insertLink',
  'toggleFormatting',
  'addSignature',
  'removeSignature',
  'attachFile',
]);

const { t } = useI18n();

const attachmentId = ref(0);
const generateUid = () => {
  attachmentId.value += 1;
  return `attachment-${attachmentId.value}`;
};

const uploadAttachment = ref(null);
const imageUpload = ref(null);
const isEmojiPickerOpen = ref(false);
const isSendMenuOpen = ref(false);

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

const {
  fetchSignatureFlagFromUISettings,
  setSignatureFlagForInbox,
  isEditorHotKeyEnabled,
} = useUISettings();

const sendWithSignature = computed(() => {
  return fetchSignatureFlagFromUISettings(props.channelType);
});

const showTwilioContentTemplates = computed(() => {
  return props.isTwilioWhatsAppInbox && props.inboxId;
});

const shouldShowEmojiButton = computed(() => {
  return (
    !props.isWhatsappInbox && !props.isTwilioWhatsAppInbox && !props.hasNoInbox
  );
});

const isRegularMessageMode = computed(() => {
  return !props.isWhatsappInbox && !props.isTwilioWhatsAppInbox;
});

const shouldShowSignatureButton = computed(() => {
  return (
    props.hasSelectedInbox && isRegularMessageMode.value && !props.voiceEnabled
  );
});

const setSignature = () => {
  if (props.messageSignature) {
    if (sendWithSignature.value) {
      emit('addSignature', props.messageSignature);
    } else {
      emit('removeSignature', props.messageSignature);
    }
  }
};

const toggleMessageSignature = () => {
  setSignatureFlagForInbox(props.channelType, !sendWithSignature.value);
};

// Added this watch to dynamically set signature on target inbox change.
// Only targetInbox has value and is Advance Editor(used by isEmailOrWebWidgetInbox)
// Set the signature only if the inbox based flag is true
watch(
  () => props.hasSelectedInbox,
  newValue => {
    nextTick(() => {
      if (newValue && !props.voiceEnabled) setSignature();
    });
  },
  { immediate: true }
);

const onClickInsertEmoji = emoji => {
  emit('insertEmoji', emoji);
  isEmojiPickerOpen.value = false;
};

const { onFileUpload } = useFileUpload({
  isATwilioSMSChannel: props.isTwilioSmsInbox,
  attachFile: ({ blob, file }) => {
    if (!file) return;
    const reader = new FileReader();
    reader.readAsDataURL(file.file);
    reader.onloadend = () => {
      const newFile = {
        resource: blob || file,
        isPrivate: false,
        thumb: reader.result,
        blobSignedId: blob?.signed_id,
      };
      emit('attachFile', [...props.attachedFiles, newFile]);
    };
  },
});

const keyboardEvents = {
  Enter: {
    action: () => {
      if (
        isEditorHotKeyEnabled('enter') &&
        isRegularMessageMode.value &&
        !props.isDropdownActive
      ) {
        emit('sendMessage');
      }
    },
  },
  '$mod+Enter': {
    action: () => {
      if (
        isEditorHotKeyEnabled('cmd_enter') &&
        isRegularMessageMode.value &&
        !props.isDropdownActive
      ) {
        emit('sendMessage');
      }
    },
  },
};
useKeyboardEvents(keyboardEvents);

const onPaste = e => {
  if (!props.isEmailOrWebWidgetInbox) return;

  const files = e.clipboardData?.files;
  if (!files?.length) return;

  // Filter valid files (non-zero size)
  Array.from(files)
    .filter(file => file.size > 0)
    .forEach(file => {
      const { name, type, size } = file;
      // Add unique ID for clipboard-pasted files
      onFileUpload({ file, name, type, size, id: generateUid() });
    });
};

useEventListener(document, 'paste', onPaste);
</script>

<template>
  <div
    class="flex w-full items-center justify-between gap-2 border-t border-border bg-background p-3"
  >
    <div class="flex min-w-0 items-center gap-3 sm:gap-4">
      <WhatsAppOptions
        v-if="isWhatsappInbox"
        :inbox-id="inboxId"
        @send-message="emit('sendWhatsappMessage', $event)"
      />
      <ContentTemplateSelector
        v-if="showTwilioContentTemplates"
        :inbox-id="inboxId"
        @send-message="emit('sendTwilioMessage', $event)"
      />

      <div
        v-if="isRegularMessageMode"
        v-on-click-outside="() => (isSendMenuOpen = false)"
        class="relative flex shrink-0 items-center overflow-hidden rounded-full bg-primary shadow-sm"
      >
        <button
          type="button"
          class="h-8 px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          :disabled="isLoading || disableSendButton"
          @click="emit('sendMessage')"
        >
          {{ t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.SEND') }}
        </button>
        <button
          type="button"
          class="flex h-8 w-6 items-center justify-center border-l border-primary-foreground/20 text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          :disabled="isLoading || disableSendButton"
          :title="
            t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.SEND_OPTIONS')
          "
          @click="isSendMenuOpen = !isSendMenuOpen"
        >
          <span class="i-lucide-chevron-down size-3.5" />
        </button>
        <div
          v-if="isSendMenuOpen"
          class="absolute bottom-full left-0 z-50 mb-2 min-w-[10rem] rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
        >
          <button
            type="button"
            class="flex w-full items-center rounded-sm px-2 py-1.5 text-sm hover:bg-accent hover:text-accent-foreground"
            @click="
              () => {
                isSendMenuOpen = false;
                emit('sendMessage');
              }
            "
          >
            {{ t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.SEND_NOW') }}
          </button>
        </div>
      </div>

      <div
        v-if="isRegularMessageMode"
        class="flex items-center gap-0.5 sm:gap-1"
      >
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8"
          :class="
            showFormatting
              ? 'bg-primary/10 text-primary'
              : 'text-muted-foreground hover:text-foreground'
          "
          :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.FORMATTING')"
          @click="emit('toggleFormatting')"
        >
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
          <span class="text-sm font-bold">A</span>
        </RelayButton>

        <FileUpload
          v-if="isEmailOrWebWidgetInbox"
          ref="uploadAttachment"
          input-id="composeNewConversationAttachment"
          :size="4096 * 4096"
          :accept="ALLOWED_FILE_TYPES"
          multiple
          :drop-directory="false"
          :data="{
            direct_upload_url: '/rails/active_storage/direct_uploads',
            direct_upload: true,
          }"
          class="inline-flex"
          @input-file="onFileUpload"
        >
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 text-muted-foreground hover:text-foreground"
            :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.ATTACH')"
            as="span"
          >
            <span class="i-lucide-paperclip size-4" />
          </RelayButton>
        </FileUpload>

        <RelayButton
          variant="ghost"
          size="icon"
          class="hidden size-8 text-muted-foreground hover:text-foreground sm:inline-flex"
          :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.LINK')"
          @click="emit('insertLink')"
        >
          <span class="i-lucide-link-2 size-4" />
        </RelayButton>

        <div
          v-if="shouldShowEmojiButton"
          v-on-click-outside="() => (isEmojiPickerOpen = false)"
          class="relative hidden sm:block"
        >
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 text-muted-foreground hover:text-foreground"
            :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.EMOJI')"
            @click="isEmojiPickerOpen = !isEmojiPickerOpen"
          >
            <span class="i-lucide-smile size-4" />
          </RelayButton>
          <EmojiInput
            v-if="isEmojiPickerOpen"
            class="!top-auto !bottom-full mb-1.5 ltr:left-0 rtl:right-0"
            :on-click="onClickInsertEmoji"
          />
        </div>

        <FileUpload
          v-if="isEmailOrWebWidgetInbox"
          ref="imageUpload"
          input-id="composeNewConversationImage"
          :size="4096 * 4096"
          accept="image/*"
          multiple
          :drop-directory="false"
          :data="{
            direct_upload_url: '/rails/active_storage/direct_uploads',
            direct_upload: true,
          }"
          class="hidden sm:inline-flex"
          @input-file="onFileUpload"
        >
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 text-muted-foreground hover:text-foreground"
            :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.IMAGE')"
            as="span"
          >
            <span class="i-lucide-image size-4" />
          </RelayButton>
        </FileUpload>

        <RelayButton
          v-if="shouldShowSignatureButton"
          variant="ghost"
          size="icon"
          class="size-8 text-muted-foreground hover:text-foreground"
          :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.SIGNATURE')"
          @click="toggleMessageSignature"
        >
          <span class="i-lucide-signature size-4" />
        </RelayButton>
      </div>
    </div>

    <RelayButton
      variant="ghost"
      size="icon"
      class="size-8 shrink-0 text-muted-foreground hover:text-destructive"
      :title="t('COMPOSE_NEW_CONVERSATION.FORM.ACTION_BUTTONS.DISCARD')"
      @click="emit('discard')"
    >
      <span class="i-lucide-trash-2 size-4" />
    </RelayButton>
  </div>
</template>
