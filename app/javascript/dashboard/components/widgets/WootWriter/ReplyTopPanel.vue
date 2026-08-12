<script>
import { ref } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useTrack } from 'dashboard/composables';
import { vOnClickOutside } from '@vueuse/components';
import { REPLY_EDITOR_MODES, CHAR_LENGTH_WARNING } from './constants';
import { CAPTAIN_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import CopilotMenuBar from './CopilotMenuBar.vue';

export default {
  name: 'ReplyTopPanel',
  components: {
    CopilotMenuBar,
  },
  directives: {
    OnClickOutside: vOnClickOutside,
  },
  props: {
    mode: {
      type: String,
      default: REPLY_EDITOR_MODES.REPLY,
    },
    isReplyRestricted: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    isEditorDisabled: {
      type: Boolean,
      default: false,
    },
    conversationId: {
      type: Number,
      default: null,
    },
    isMessageLengthReachingThreshold: {
      type: Boolean,
      default: () => false,
    },
    charactersRemaining: {
      type: Number,
      default: () => 0,
    },
    editorContent: {
      type: String,
      default: undefined,
    },
    hasContent: {
      type: Boolean,
      default: false,
    },
    isCopilotActive: {
      type: Boolean,
      default: false,
    },
    contactName: {
      type: String,
      default: '',
    },
  },
  emits: [
    'setReplyMode',
    'toggleEditorSize',
    'executeCopilotAction',
    'toggleCopilot',
    'resetCopilot',
  ],
  setup(props, { emit }) {
    const setReplyMode = mode => {
      emit('setReplyMode', mode);
    };
    const handleReplyClick = () => {
      if (props.isReplyRestricted) return;
      if (props.isCopilotActive) {
        emit('resetCopilot');
      }
      setReplyMode(REPLY_EDITOR_MODES.REPLY);
    };
    const handleNoteClick = () => {
      if (props.isCopilotActive) {
        emit('resetCopilot');
      }
      setReplyMode(REPLY_EDITOR_MODES.NOTE);
    };
    const handleAiReplyClick = () => {
      if (props.disabled || props.isEditorDisabled || props.isReplyRestricted)
        return;
      if (!props.isCopilotActive) {
        if (props.mode !== REPLY_EDITOR_MODES.REPLY) {
          setReplyMode(REPLY_EDITOR_MODES.REPLY);
        }
        emit('toggleCopilot');
      }
    };

    const { captainTasksEnabled } = useCaptain();
    const showCopilotMenu = ref(false);
    const copilotToggleRef = ref(null);

    const handleCopilotAction = (actionKey, data) => {
      emit('executeCopilotAction', actionKey, data || props.editorContent);
      showCopilotMenu.value = false;
    };

    const toggleCopilotMenu = () => {
      const isOpening = !showCopilotMenu.value;
      if (isOpening) {
        useTrack(CAPTAIN_EVENTS.EDITOR_AI_MENU_OPENED, {
          conversationId: props.conversationId,
          entryPoint: 'top_panel',
        });
      }
      showCopilotMenu.value = isOpening;
    };

    const handleClickOutside = () => {
      showCopilotMenu.value = false;
    };

    const keyboardEvents = {
      'Alt+KeyP': {
        action: () => handleNoteClick(),
        allowOnFocusedInput: false,
      },
      'Alt+KeyL': {
        action: () => handleReplyClick(),
        allowOnFocusedInput: false,
      },
    };
    useKeyboardEvents(keyboardEvents);

    return {
      handleReplyClick,
      handleNoteClick,
      handleAiReplyClick,
      REPLY_EDITOR_MODES,
      captainTasksEnabled,
      handleCopilotAction,
      showCopilotMenu,
      copilotToggleRef,
      toggleCopilotMenu,
      handleClickOutside,
    };
  },
  computed: {
    isReplyActive() {
      return (
        this.mode === REPLY_EDITOR_MODES.REPLY &&
        !this.isCopilotActive &&
        !this.isReplyRestricted
      );
    },
isAiActive() {
      return this.isCopilotActive;
    },
    charLengthClass() {
      return this.charactersRemaining < 0
        ? 'text-destructive'
        : 'text-muted-foreground';
    },
    characterLengthWarning() {
      return this.charactersRemaining < 0
        ? `${-this.charactersRemaining} ${CHAR_LENGTH_WARNING.NEGATIVE}`
        : `${this.charactersRemaining} ${CHAR_LENGTH_WARNING.UNDER_50}`;
    },
  },
};
</script>

<template>
  <div
    class="w-full flex justify-between items-center h-10 bg-transparent rounded-none border-b border-border p-0 px-4"
    role="tablist"
  >
    <div class="flex gap-8 h-full">
      <!-- Reply -->
      <button
        type="button"
        role="tab"
        :aria-selected="isReplyActive"
        class="rounded-none h-full border-b-2 transition-colors flex items-center gap-1.5 px-0 font-semibold text-sm"
        :class="
          isReplyActive
            ? 'border-primary text-foreground shadow-none bg-transparent'
            : 'border-transparent text-muted-foreground hover:text-foreground shadow-none bg-transparent'
        "
        :disabled="disabled || isReplyRestricted"
        @click="handleReplyClick"
      >
        {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
      </button>

      <!-- AI Reply -->
      <button
        v-if="captainTasksEnabled"
        type="button"
        role="tab"
        :aria-selected="isAiActive"
        class="rounded-none h-full border-b-2 transition-colors flex items-center gap-1.5 px-0 font-semibold text-sm"
        :class="
          isAiActive
            ? 'border-primary text-primary shadow-none bg-transparent'
            : 'border-transparent text-muted-foreground hover:text-foreground shadow-none bg-transparent'
        "
        :disabled="disabled || isEditorDisabled || isReplyRestricted"
        @click="handleAiReplyClick"
      >
        <span class="i-lucide-wand-sparkles size-4" />
        {{ $t('CONVERSATION.REPLYBOX.AI_REPLY') }}
      </button>

    </div>

    <div class="flex items-center gap-2">
      <div v-if="isMessageLengthReachingThreshold" class="text-xs">
        <span :class="charLengthClass">
          {{ characterLengthWarning }}
        </span>
      </div>
      <div v-if="captainTasksEnabled" class="relative">
        <div ref="copilotToggleRef" class="inline-flex" />
        <CopilotMenuBar
          v-if="showCopilotMenu"
          v-on-click-outside="[
            handleClickOutside,
            { ignore: [copilotToggleRef] },
          ]"
          :has-selection="false"
          :has-content="hasContent"
          :conversation-id="conversationId"
          class="ltr:right-0 rtl:left-0 bottom-full mb-2"
          @execute-copilot-action="handleCopilotAction"
        />
      </div>
      <button
        class="size-7 flex items-center justify-center rounded-md hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
        title="Toggle editor size"
        @click="$emit('toggleEditorSize')"
      >
        <span class="i-lucide-maximize-2 size-4" />
      </button>
    </div>
  </div>
</template>
