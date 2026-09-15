<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import CopilotEditorSection from 'dashboard/components/widgets/conversation/CopilotEditorSection.vue';
import ComposeFormattingToolbar from './ComposeFormattingToolbar.vue';
import { RelayTextarea } from 'dashboard/components-next/relay';

const props = defineProps({
  hasErrors: { type: Boolean, default: false },
  sendWithSignature: { type: Boolean, default: false },
  messageSignature: { type: String, default: '' },
  channelType: { type: String, default: '' },
  medium: { type: String, default: '' },
  copilot: { type: Object, default: null },
  showFormatting: { type: Boolean, default: false },
  plain: { type: Boolean, default: false },
  comfortable: { type: Boolean, default: false },
});

const editorKey = computed(() => `editor-${props.channelType}-${props.medium}`);
const editorRef = ref(null);

const { t } = useI18n();

const modelValue = defineModel({
  type: String,
  default: '',
});

const isCopilotActive = computed(() => props.copilot?.isActive?.value ?? false);

const showComposeToolbar = computed(
  () => props.showFormatting && !props.plain && !isCopilotActive.value
);

const executeCopilotAction = (action, data) => {
  if (props.copilot) {
    props.copilot.execute(action, data);
  }
};

const onFormat = command => {
  editorRef.value?.executeFormat?.(command);
};
</script>

<template>
  <div
    class="relative flex min-h-0 flex-1 flex-col"
    :class="comfortable ? '' : 'min-h-[250px] px-4 py-4'"
  >
    <ComposeFormattingToolbar v-if="showComposeToolbar" @format="onFormat" />
    <Transition
      mode="out-in"
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 translate-y-2 scale-[0.98]"
      enter-to-class="opacity-100 translate-y-0 scale-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 translate-y-0 scale-100"
      leave-to-class="opacity-0 translate-y-2 scale-[0.98]"
    >
      <div
        :key="copilot ? copilot.editorTransitionKey.value : 'rich'"
        class="min-h-0 flex-1"
        :class="comfortable ? 'px-6 py-4' : 'h-full min-h-[200px]'"
      >
        <CopilotEditorSection
          v-if="isCopilotActive"
          :show-copilot-editor="copilot.showEditor.value"
          :is-generating-content="copilot.isGenerating.value"
          :generated-content="copilot.generatedContent.value"
          class="!mb-0"
          @focus="() => {}"
          @blur="() => {}"
          @clear-selection="() => {}"
          @content-ready="copilot.setContentReady"
          @send="copilot.sendFollowUp"
        />
        <textarea
          v-else-if="plain && comfortable"
          v-model="modelValue"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
          "
          class="reset-base min-h-[8rem] w-full resize-none border-none bg-transparent px-0 py-0 text-[14px] text-foreground shadow-none outline-none placeholder:text-muted-foreground focus:ring-0"
          :class="hasErrors ? 'placeholder:!text-destructive' : ''"
        />
        <RelayTextarea
          v-else-if="plain"
          v-model="modelValue"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
          "
          class-name="min-h-[12rem] border-none bg-transparent px-0 py-0 text-[14px] shadow-none focus-visible:ring-0"
        />
        <Editor
          v-else
          ref="editorRef"
          v-model="modelValue"
          :editor-key="editorKey"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
          "
          :enable-menu-bar="false"
          class="h-full gap-0 [&>div]:!border-0 [&>div]:!bg-transparent [&>div]:!px-0 [&>div]:!py-0 [&>div]:!rounded-none [&>div]:hover:!bg-transparent [&_.mention--box]:-top-[7.5rem] [&_.mention--box]:bottom-[unset]"
          :class="[
            comfortable
              ? '[&_.ProseMirror-relay-style]:!min-h-[8rem] [&_.ProseMirror-relay-style]:!max-h-none [&_.ProseMirror-relay-style]:!px-0 [&_.ProseMirror-relay-style]:!py-0 [&_.ProseMirror-relay-style]:text-[14px]'
              : '[&_.ProseMirror-relay-style]:!min-h-[12rem] [&_.ProseMirror-relay-style]:!max-h-[18rem]',
            hasErrors
              ? '[&_.empty-node]:before:!text-destructive [&_.empty-node]:dark:before:!text-destructive'
              : '',
          ]"
          enable-variables
          enable-captain-tools
          :show-character-count="false"
          :signature="messageSignature"
          allow-signature
          :send-with-signature="sendWithSignature"
          :channel-type="channelType"
          :medium="medium"
          @execute-copilot-action="executeCopilotAction"
        />
      </div>
    </Transition>
  </div>
</template>
