<script setup>
import { ref, computed, watch, onMounted, useTemplateRef } from 'vue';

import {
  buildMessageSchema,
  buildEditor,
  EditorView,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';

import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorId: { type: String, default: '' },
  placeholder: {
    type: String,
    default: 'Write a prompt for the AI to generate a reply...',
  },
  generatedContent: { type: String, default: '' },
  autofocus: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits([
  'blur',
  'input',
  'update:modelValue',
  'keyup',
  'focus',
  'keydown',
  'send',
]);

const { formatMessage } = useMessageFormatter();

// Minimal schema with no marks or nodes for copilot input
const copilotSchema = buildMessageSchema([], []);

const handleSubmit = () => emit('send');

const createState = (
  content,
  placeholder,
  plugins = [],
  enabledMenuOptions = []
) => {
  return EditorState.create({
    doc: new MessageMarkdownTransformer(copilotSchema).parse(content),
    plugins: buildEditor({
      schema: copilotSchema,
      placeholder,
      plugins,
      enabledMenuOptions,
    }),
  });
};

// we don't need them to be reactive
// It cases weird issues where the objects are proxied
// and then the editor doesn't work as expected
let editorView = null;
let state = null;

// reactive data
const isTextSelected = ref(false); // Tracks text selection and prevents unnecessary re-renders on mouse selection

// element refs
const editor = useTemplateRef('editor');

function contentFromEditor() {
  if (editorView) {
    return MessageMarkdownSerializer.serialize(editorView.state.doc);
  }
  return '';
}

function focusEditorInputField() {
  const { tr } = editorView.state;
  const selection = Selection.atEnd(tr.doc);

  editorView.dispatch(tr.setSelection(selection));
  editorView.focus();
}

function emitOnChange() {
  emit('update:modelValue', contentFromEditor());
  emit('input', contentFromEditor());
}

function onKeyup() {
  emit('keyup');
}

function onKeydown(view, event) {
  emit('keydown');

  // Handle Enter key to send message (Shift+Enter for new line)
  // Skip if IME composition is active (CJK character confirmation)
  if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
    event.preventDefault();
    handleSubmit();
    return true; // Prevent ProseMirror's default Enter handling
  }

  return false; // Allow other keys to work normally
}

function onBlur() {
  emit('blur');
}

function onFocus() {
  emit('focus');
}

function checkSelection(editorState) {
  const hasSelection = editorState.selection.from !== editorState.selection.to;
  if (hasSelection === isTextSelected.value) return;
  isTextSelected.value = hasSelection;
}

// computed properties
const plugins = computed(() => {
  return [];
});

const enabledMenuOptions = computed(() => {
  return [];
});

const hasGeneratedContent = computed(() => !!props.generatedContent?.trim());

function reloadState() {
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    enabledMenuOptions.value
  );
  editorView.updateState(state);
  focusEditorInputField();
}

function createEditorView() {
  editorView = new EditorView(editor.value, {
    state: state,
    dispatchTransaction: tx => {
      state = state.apply(tx);
      editorView.updateState(state);
      if (tx.docChanged) {
        emitOnChange();
      }
      checkSelection(state);
    },
    handleDOMEvents: {
      keyup: onKeyup,
      focus: onFocus,
      blur: onBlur,
      keydown: onKeydown,
    },
  });
}

// watchers
watch(
  computed(() => props.modelValue),
  (newValue = '') => {
    if (newValue !== contentFromEditor()) {
      reloadState();
    }
  }
);

watch(
  computed(() => props.editorId),
  () => {
    reloadState();
  }
);

// lifecycle
onMounted(() => {
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    enabledMenuOptions.value
  );

  createEditorView();
  editorView.updateState(state);

  if (props.autofocus) {
    focusEditorInputField();
  }
});
</script>

<template>
  <div class="mb-2">
    <div
      v-if="hasGeneratedContent"
      class="overflow-y-auto max-h-56 mb-2 px-1"
    >
      <p
        v-dompurify-html="formatMessage(generatedContent, false)"
        class="text-foreground text-sm prose-sm font-normal"
      />
    </div>
    <div class="editor-root relative editor--copilot">
      <div ref="editor" />
    </div>
  </div>
</template>

<style lang="scss">
@import '@chatwoot/prosemirror-schema/src/styles/base.scss';

.editor--copilot {
  @apply bg-primary/5 dark:bg-primary/10 rounded-md;

  .ProseMirror-woot-style {
    min-height: 5rem;
    max-height: 7.5rem !important;
    overflow: auto;
    @apply px-4 py-3 !important;

    .empty-node {
      &::before {
        @apply text-muted-foreground;
      }
    }
  }
}
</style>
