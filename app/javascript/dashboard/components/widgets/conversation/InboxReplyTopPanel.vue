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
  },
};
</script>

<template>
  <div
    class="flex items-center justify-between border-b border-border px-1 pt-1 bg-muted/5 rounded-t-xl"
    role="tablist"
  >
    <!-- Tab bar: global button { border-0 rounded-lg } — use absolute underline, not border-b-2 -->
    <div class="flex items-center gap-0">
      <button
        type="button"
        role="tab"
        :aria-selected="isReplyActive"
        class="relative -mb-px rounded-none border-0 bg-transparent px-4 py-2.5 text-sm shadow-none transition-colors hover:bg-transparent focus:outline-none focus-visible:ring-0"
        :class="
          isReplyActive
            ? 'font-semibold text-foreground'
            : 'font-medium text-muted-foreground hover:text-foreground'
        "
        :disabled="disabled || isReplyRestricted"
        @click="handleReplyClick"
      >
        {{
          $t('CONVERSATION.REPLYBOX.REPLY_TO_CONTACT', {
            contactName: contactName || $t('CONVERSATION.REPLYBOX.CONTACT'),
          })
        }}
        <span
          v-if="isReplyActive"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-foreground"
          aria-hidden="true"
        />
      </button>
      <button
        type="button"
        role="tab"
        :aria-selected="isNoteActive"
        class="relative -mb-px rounded-none border-0 bg-transparent px-4 py-2.5 text-sm shadow-none transition-colors hover:bg-transparent focus:outline-none focus-visible:ring-0"
        :class="
          isNoteActive
            ? 'font-semibold text-amber-600 bg-amber-500/10'
            : 'font-medium text-muted-foreground hover:text-foreground'
        "
        :disabled="disabled"
        @click="handleNoteClick"
      >
        {{ $t('CONVERSATION.REPLYBOX.INTERNAL_COMMENT') }}
        <span
          v-if="isNoteActive"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-amber-500"
          aria-hidden="true"
        />
      </button>
    </div>
    <button
      type="button"
      class="size-8 flex items-center justify-center rounded-md hover:bg-muted text-muted-foreground hover:text-foreground transition-colors mr-1 border-0 bg-transparent shadow-none"
      :title="$t('CONVERSATION.REPLYBOX.TOGGLE_EDITOR_SIZE')"
      @click="$emit('toggleEditorSize')"
    >
      <span class="i-lucide-maximize-2 size-4" />
    </button>
  </div>
</template>
