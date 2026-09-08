<script>
import { ref } from 'vue';
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import Spinner from 'shared/components/Spinner.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import {
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS,
} from 'dashboard/components-next/relay';
import { RELAY_SIDEBAR_TEXT_ACTION_CLASS } from 'dashboard/components-next/relay/sidebar/constants';

export default {
  components: {
    Spinner,
    LabelDropdown,
    RelayDropdownMenu,
    RelayDropdownMenuTrigger,
    RelayDropdownMenuContent,
  },
  setup() {
    const { isAdmin } = useAdmin();

    const {
      savedLabels,
      activeLabels,
      accountLabels,
      addLabelToConversation,
      removeLabelFromConversation,
    } = useConversationLabels();

    const showSearchDropdownLabel = ref(false);

    const toggleLabels = () => {
      showSearchDropdownLabel.value = !showSearchDropdownLabel.value;
    };

    const closeDropdownLabel = () => {
      showSearchDropdownLabel.value = false;
    };

    const keyboardEvents = {
      KeyL: {
        action: e => {
          e.preventDefault();
          toggleLabels();
        },
      },
      Escape: {
        action: () => {
          if (showSearchDropdownLabel.value) {
            toggleLabels();
          }
        },
        allowOnFocusedInput: true,
      },
    };
    useKeyboardEvents(keyboardEvents);
    return {
      isAdmin,
      savedLabels,
      activeLabels,
      accountLabels,
      addLabelToConversation,
      removeLabelFromConversation,
      showSearchDropdownLabel,
      closeDropdownLabel,
      toggleLabels,
      sidebarTextActionClass: RELAY_SIDEBAR_TEXT_ACTION_CLASS,
      dropdownContentClass: DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS,
    };
  },
  data() {
    return {
      selectedLabels: [],
    };
  },

  computed: {
    ...mapGetters({
      conversationUiFlags: 'conversationLabels/getUIFlags',
    }),
  },
};
</script>

<template>
  <div class="flex w-full flex-col items-stretch gap-2">
    <div
      v-if="!conversationUiFlags.isFetching"
      class="flex w-full flex-col items-stretch gap-2"
    >
      <div class="w-full">
        <RelayDropdownMenu v-model:open="showSearchDropdownLabel">
          <RelayDropdownMenuTrigger as-child>
            <button
              type="button"
              :class="sidebarTextActionClass"
              @keyup.esc="closeDropdownLabel"
            >
              <span class="i-lucide-plus size-3.5" />
              {{ $t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON') }}
            </button>
          </RelayDropdownMenuTrigger>
          <RelayDropdownMenuContent
            align="start"
            :side-offset="4"
            :class="dropdownContentClass"
          >
            <LabelDropdown
              v-if="showSearchDropdownLabel"
              :account-labels="accountLabels"
              :selected-labels="savedLabels"
              :allow-creation="isAdmin"
              @add="addLabelToConversation"
              @remove="removeLabelFromConversation"
              @close="closeDropdownLabel"
            />
          </RelayDropdownMenuContent>
        </RelayDropdownMenu>
      </div>

      <div v-if="activeLabels.length" class="flex flex-wrap items-center gap-2">
        <button
          v-for="label in activeLabels"
          :key="label.id"
          type="button"
          class="inline-flex h-6 max-w-[calc(100%-0.5rem)] items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 text-[11px] font-normal text-primary"
          :title="label.description"
          @click="removeLabelFromConversation(label.title)"
        >
          {{ label.title }}
          <span class="i-lucide-x size-3 shrink-0 opacity-60" />
        </button>
      </div>
    </div>
    <Spinner v-else />
  </div>
</template>
