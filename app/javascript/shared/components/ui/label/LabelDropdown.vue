<script>
import LabelDropdownItem from './LabelDropdownItem.vue';
import LabelModal from 'dashboard/routes/dashboard/settings/labels/component/LabelModal.vue';
import { picoSearch } from '@scmmishra/pico-search';
import { sanitizeLabel } from 'shared/helpers/sanitizeData';

export default {
  components: {
    LabelDropdownItem,
    LabelModal,
  },

  props: {
    accountLabels: {
      type: Array,
      default: () => [],
    },
    selectedLabels: {
      type: Array,
      default: () => [],
    },
    allowCreation: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update', 'add', 'remove'],

  data() {
    return {
      search: '',
      createModalVisible: false,
    };
  },

  computed: {
    createLabelPlaceholder() {
      const label = this.$t('CONTACT_PANEL.LABELS.LABEL_SELECT.CREATE_LABEL');
      return this.search ? `${label}:` : label;
    },

    filteredActiveLabels() {
      if (!this.search) return this.accountLabels;

      return picoSearch(this.accountLabels, this.search, ['title']);
    },

    noResult() {
      return this.filteredActiveLabels.length === 0;
    },

    hasExactMatchInResults() {
      return this.filteredActiveLabels.some(
        label => label.title === this.search
      );
    },

    shouldShowCreate() {
      return this.allowCreation && this.filteredActiveLabels.length < 3;
    },

    parsedSearch() {
      return sanitizeLabel(this.search);
    },
  },

  mounted() {
    this.focusInput();
  },

  methods: {
    focusInput() {
      this.$refs.searchbar.focus();
    },

    updateLabels(label) {
      this.$emit('update', label);
    },

    onAdd(label) {
      this.$emit('add', label);
    },

    onRemove(label) {
      this.$emit('remove', label);
    },

    onAddRemove(label) {
      if (this.selectedLabels.includes(label.title)) {
        this.onRemove(label.title);
      } else {
        this.onAdd(label);
      }
    },

    showCreateModal() {
      this.createModalVisible = true;
    },

    hideCreateModal() {
      this.createModalVisible = false;
    },
  },
};
</script>

<template>
  <div class="flex max-h-[12.5rem] w-full flex-col">
    <div class="min-h-0 flex-1 overflow-y-auto p-1">
      <div class="mb-1 px-0.5">
        <input
          ref="searchbar"
          v-model="search"
          type="search"
          class="reset-base no-margin m-0 box-border h-7 w-full max-w-full rounded-md border border-border/80 bg-background px-2 py-0 text-xs leading-none text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          autofocus="true"
          :placeholder="$t('CONTACT_PANEL.LABELS.LABEL_SELECT.PLACEHOLDER')"
        />
      </div>

      <ul class="m-0 flex list-none flex-col gap-0.5 p-0">
        <li v-for="label in filteredActiveLabels" :key="label.title">
          <LabelDropdownItem
            :title="label.title"
            :color="label.color"
            :selected="selectedLabels.includes(label.title)"
            @select-label="onAddRemove(label)"
          />
        </li>
      </ul>

      <p
        v-if="noResult"
        class="m-0 flex w-full items-center justify-center overflow-hidden text-ellipsis whitespace-nowrap px-2.5 py-2 text-[13px] text-muted-foreground"
      >
        {{ $t('CONTACT_PANEL.LABELS.LABEL_SELECT.NO_RESULT') }}
      </p>

      <div
        v-if="allowCreation && shouldShowCreate"
        class="mt-1 border-t border-border pt-1"
      >
        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
          :disabled="hasExactMatchInResults"
          @click="showCreateModal"
        >
          <span class="i-lucide-plus size-3.5 shrink-0 text-muted-foreground" />
          <span class="truncate">
            {{ createLabelPlaceholder }}
            <template v-if="parsedSearch">{{ parsedSearch }}</template>
          </span>
        </button>

        <LabelModal
          :show="createModalVisible"
          mode="add"
          :prefill-title="parsedSearch"
          @close="hideCreateModal"
        />
      </div>
    </div>
  </div>
</template>
