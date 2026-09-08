<script>
import { RelayTooltip } from 'dashboard/components-next/relay';
// components
import NextButton from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { useBranding } from 'shared/composables/useBranding';

// composables
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useTrack } from 'dashboard/composables';

// store & api
import { mapGetters } from 'vuex';

// utils & constants
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { CAPTAIN_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  name: 'LabelSuggestion',
  components: {
    RelayTooltip,
    Avatar,
    NextButton,
  },
  props: {
    suggestedLabels: {
      type: Array,
      required: true,
    },
    chatLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  setup() {
    const { captainTasksEnabled } = useCaptain();
    const { replaceInstallationName } = useBranding();

    return { captainTasksEnabled, replaceInstallationName };
  },
  data() {
    return {
      isDismissed: false,
      isHovered: false,
      selectedLabels: [],
    };
  },
  computed: {
    ...mapGetters({
      allLabels: 'labels/getLabels',
      currentAccountId: 'getCurrentAccountId',
      currentChat: 'getSelectedChat',
    }),
    conversationId() {
      return this.currentChat?.id;
    },
    labelTooltip() {
      if (this.preparedLabels.length > 1) {
        return this.$t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.MULTIPLE_SUGGESTION');
      }

      return this.$t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.SINGLE_SUGGESTION');
    },
    addButtonText() {
      if (this.selectedLabels.length === 1) {
        return this.$t('LABEL_MGMT.SUGGESTIONS.ADD_SELECTED_LABEL');
      }

      if (this.selectedLabels.length > 1) {
        return this.$t('LABEL_MGMT.SUGGESTIONS.ADD_SELECTED_LABELS');
      }

      return this.$t('LABEL_MGMT.SUGGESTIONS.ADD_ALL_LABELS');
    },
    preparedLabels() {
      return this.allLabels.filter(label =>
        this.suggestedLabels.includes(label.title)
      );
    },
    shouldShowSuggestions() {
      if (this.isDismissed) return false;
      if (!this.captainTasksEnabled) return false;

      return this.preparedLabels.length && this.chatLabels.length === 0;
    },
  },
  watch: {
    conversationId: {
      immediate: true,
      handler() {
        this.selectedLabels = [];
        this.isDismissed = this.isConversationDismissed();
      },
    },
  },
  methods: {
    pushOrAddLabel(label) {
      if (this.preparedLabels.length === 1) {
        this.addAllLabels();
        return;
      }

      if (!this.selectedLabels.includes(label)) {
        this.selectedLabels.push(label);
      } else {
        this.selectedLabels = this.selectedLabels.filter(l => l !== label);
      }
    },
    dismissSuggestions() {
      LocalStorage.setFlag(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        this.currentAccountId,
        this.conversationId
      );

      // dismiss this once the values are set
      this.isDismissed = true;
      this.trackLabelEvent(CAPTAIN_EVENTS.LABEL_SUGGESTION_DISMISSED);
    },
    isConversationDismissed() {
      return LocalStorage.getFlag(
        LOCAL_STORAGE_KEYS.DISMISSED_LABEL_SUGGESTIONS,
        this.currentAccountId,
        this.conversationId
      );
    },
    addAllLabels() {
      let labelsToAdd = this.selectedLabels;
      if (!labelsToAdd.length) {
        labelsToAdd = this.preparedLabels.map(label => label.title);
      }
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: labelsToAdd,
      });
      this.trackLabelEvent(CAPTAIN_EVENTS.LABEL_SUGGESTION_APPLIED);
    },
    trackLabelEvent(event) {
      const payload = {
        conversationId: this.conversationId,
        account: this.currentAccountId,
        suggestions: this.suggestedLabels,
        labelsApplied: this.selectedLabels.length
          ? this.selectedLabels
          : this.suggestedLabels,
      };

      useTrack(event, payload);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    v-if="shouldShowSuggestions"
    class="mt-4 flex list-none flex-row justify-end"
    @mouseover="isHovered = true"
    @mouseleave="isHovered = false"
  >
    <div class="flex">
      <div class="max-w-[300px]">
        <h6 class="mt-0.5 text-[10px] font-medium text-muted-foreground">
          {{ $t('LABEL_MGMT.SUGGESTIONS.SUGGESTED_LABELS') }}
        </h6>
        <div class="flex items-center gap-0.5 text-end">
          <RelayTooltip
            v-for="label in preparedLabels"
            :key="label.title"
            :content="{
              content: selectedLabels.includes(label.title)
                ? $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DESELECT')
                : labelTooltip,
              delay: { show: 600, hide: 0 },
            }"
            side="top"
          >
            <button
              type="button"
              class="inline-flex h-6 items-center gap-1.5 rounded-full border border-dashed border-border px-2.5 text-[11px] font-medium text-muted-foreground"
              :class="
                selectedLabels.includes(label.title)
                  ? 'border-transparent bg-primary text-primary-foreground'
                  : ''
              "
              @click="pushOrAddLabel(label.title)"
            >
              <span
                v-if="!selectedLabels.includes(label.title)"
                class="size-2 shrink-0 rounded-sm"
                :style="{ background: label.color }"
              />
              {{ label.title }}
            </button>
          </RelayTooltip>
          <RelayTooltip
            v-if="preparedLabels.length === 1"
            :content="{
              content: $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DISMISS'),
              delay: { show: 600, hide: 0 },
            }"
            side="top"
          >
            <NextButton
              faded
              xs
              icon="i-lucide-x"
              class="flex-shrink-0"
              :color="isHovered ? 'ruby' : 'blue'"
              @click="dismissSuggestions"
            />
          </RelayTooltip>
        </div>
        <div
          v-if="preparedLabels.length > 1"
          class="inline-flex items-center gap-1"
        >
          <NextButton
            xs
            icon="i-lucide-plus"
            class="flex-shrink-0"
            :variant="selectedLabels.length === 0 ? 'faded' : 'solid'"
            :label="addButtonText"
            @click="addAllLabels"
          />
          <RelayTooltip
            :content="{
              content: $t('LABEL_MGMT.SUGGESTIONS.TOOLTIP.DISMISS'),
              delay: { show: 600, hide: 0 },
            }"
            side="top"
          >
            <NextButton
              faded
              xs
              icon="i-lucide-x"
              class="flex-shrink-0"
              :color="isHovered ? 'ruby' : 'blue'"
              @click="dismissSuggestions"
            />
          </RelayTooltip>
        </div>
      </div>
      <div class="flex items-center">
        <RelayTooltip
          :content="{
            content: replaceInstallationName(
              $t('LABEL_MGMT.SUGGESTIONS.POWERED_BY')
            ),
            delay: { show: 600, hide: 0 },
          }"
          side="top"
        >
          <Avatar :size="16" name="chatwoot-ai" icon-name="i-lucide-sparkles" />
        </RelayTooltip>
      </div>
    </div>
  </li>
</template>
