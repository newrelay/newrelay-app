<script>
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';

export default {
  name: 'InboxReplyTopPanel',
  props: {
    mode: {
      type: String,
      default: REPLY_EDITOR_MODES.REPLY,
    },
    contactName: {
      type: String,
      default: '',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    isReplyRestricted: {
      type: Boolean,
      default: false,
    },
    isCopilotActive: {
      type: Boolean,
      default: false,
    },
    isEditorExpanded: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['setReplyMode', 'toggleEditorSize', 'resetCopilot'],
  setup(props, { emit }) {
    const setReplyMode = mode => emit('setReplyMode', mode);

    const handleReplyClick = () => {
      if (props.isReplyRestricted) return;
      if (props.isCopilotActive) emit('resetCopilot');
      setReplyMode(REPLY_EDITOR_MODES.REPLY);
    };

    const handleNoteClick = () => {
      if (props.isCopilotActive) emit('resetCopilot');
      setReplyMode(REPLY_EDITOR_MODES.NOTE);
    };

    useKeyboardEvents({
      'Alt+KeyP': {
        action: () => handleNoteClick(),
        allowOnFocusedInput: false,
      },
      'Alt+KeyL': {
        action: () => handleReplyClick(),
        allowOnFocusedInput: false,
      },
    });

    return { handleReplyClick, handleNoteClick, REPLY_EDITOR_MODES };
  },
  computed: {
    isReplyActive() {
      return (
        this.mode === REPLY_EDITOR_MODES.REPLY &&
        !this.isCopilotActive &&
        !this.isReplyRestricted
      );
    },
    isNoteActive() {
      return this.mode === REPLY_EDITOR_MODES.NOTE && !this.isCopilotActive;
    },
    replyTabClass() {
      return this.isReplyActive
        ? 'px-4 py-2.5 text-sm font-semibold text-foreground border-b-2 border-foreground -mb-px bg-transparent'
        : 'px-4 py-2.5 text-sm font-medium text-muted-foreground hover:text-foreground border-b-2 border-transparent -mb-px transition-colors';
    },
    noteTabClass() {
      return this.isNoteActive
        ? 'px-4 py-2.5 text-sm font-semibold text-amber-600 border-b-2 border-amber-500 -mb-px bg-amber-500/10'
        : 'px-4 py-2.5 text-sm font-medium text-muted-foreground hover:text-foreground border-b-2 border-transparent -mb-px transition-colors';
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between rounded-t-xl border-b border-border bg-muted/5 px-1 pt-1"
    role="tablist"
  >
    <div class="flex items-center">
      <button
        type="button"
        role="tab"
        :aria-selected="isReplyActive"
        class="rounded-none border-0 bg-transparent shadow-none focus:outline-none focus-visible:ring-0"
        :class="replyTabClass"
        :disabled="disabled || isReplyRestricted"
        @click="handleReplyClick"
      >
        {{
          $t('CONVERSATION.REPLYBOX.REPLY_TO_CONTACT', {
            contactName: contactName || $t('CONVERSATION.REPLYBOX.CONTACT'),
          })
        }}
      </button>
      <button
        type="button"
        role="tab"
        :aria-selected="isNoteActive"
        class="rounded-none border-0 bg-transparent shadow-none focus:outline-none focus-visible:ring-0"
        :class="noteTabClass"
        :disabled="disabled"
        @click="handleNoteClick"
      >
        {{ $t('CONVERSATION.REPLYBOX.INTERNAL_COMMENT') }}
      </button>
    </div>
    <button
      type="button"
      class="mr-1 flex size-8 items-center justify-center rounded-md border-0 bg-transparent text-muted-foreground shadow-none transition-colors hover:bg-muted hover:text-foreground"
      :title="
        isEditorExpanded
          ? $t('CONVERSATION.REPLYBOX.COLLAPSE_EDITOR')
          : $t('CONVERSATION.REPLYBOX.EXPAND_EDITOR')
      "
      @click="$emit('toggleEditorSize')"
    >
      <span
        class="size-4"
        :class="
          isEditorExpanded ? 'i-lucide-minimize-2' : 'i-lucide-maximize-2'
        "
      />
    </button>
  </div>
</template>
