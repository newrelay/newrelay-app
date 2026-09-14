<script>
import { provide, ref, computed } from 'vue';
import MacroNodes from './MacroNodes.vue';
import MacroProperties from './MacroProperties.vue';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { validateActions } from 'dashboard/helper/validations';

export default {
  components: {
    MacroNodes,
    MacroProperties,
  },
  props: {
    macroData: {
      type: Object,
      default: () => ({}),
    },
    canManagePublicMacros: {
      type: Boolean,
      default: true,
    },
    readOnly: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['submit', 'close'],
  setup() {
    const v$ = useVuelidate();
    provide('v$', v$);

    const zoomLevel = ref(1);
    const zoomIn = () => {
      zoomLevel.value = Math.min(2, zoomLevel.value + 0.1);
    };
    const zoomOut = () => {
      zoomLevel.value = Math.max(0.5, zoomLevel.value - 0.1);
    };
    const resetZoom = () => {
      zoomLevel.value = 1;
    };

    const zoomStyle = computed(() => ({
      transform: `scale(${zoomLevel.value})`,
      transformOrigin: 'top center',
    }));

    return { v$, zoomLevel, zoomIn, zoomOut, resetZoom, zoomStyle };
  },
  data() {
    return {
      macro: this.macroData,
      errors: {},
    };
  },
  computed: {
    files() {
      if (this.macro && this.macro.files) return this.macro.files;
      return [];
    },
  },
  watch: {
    $route: {
      handler() {
        this.resetValidation();
      },
      immediate: true,
    },
    macroData: {
      handler() {
        this.macro = this.macroData;
      },
      immediate: true,
    },
  },
  validations: {
    macro: {
      name: {
        required,
      },
      visibility: {
        required,
      },
    },
  },
  methods: {
    removeObjectProperty(obj, keyToRemove) {
      return Object.fromEntries(
        Object.entries(obj).filter(([key]) => key !== keyToRemove)
      );
    },
    updateName(value) {
      this.macro.name = value;
    },
    updateVisibility(value) {
      this.macro.visibility = value;
    },
    appendNode() {
      this.macro.actions.push({
        action_name: 'assign_team',
        action_params: [],
      });
    },
    deleteNode(index) {
      // remove that index specifically
      // so that the next item does not get marked invalid
      this.errors = this.removeObjectProperty(this.errors, `action_${index}`);
      this.macro.actions.splice(index, 1);
    },
    submit() {
      this.errors = validateActions(this.macro.actions);
      if (Object.keys(this.errors).length !== 0) return;

      this.v$.$touch();
      if (this.v$.$invalid) return;

      this.$emit('submit', this.macro);
    },
    resetNode(index) {
      // remove that index specifically
      // so that the next item does not get marked invalid
      this.errors = this.removeObjectProperty(this.errors, `action_${index}`);
      this.macro.actions[index].action_params = [];
    },
    resetValidation() {
      this.errors = {};
      this.v$?.$reset?.();
    },
  },
};
</script>

<template>
  <div class="flex h-full w-full flex-col overflow-hidden lg:flex-row">
    <div
      class="relative flex min-h-0 flex-1 flex-col overflow-hidden bg-muted/10 bg-[radial-gradient(var(--border)_1.25px,transparent_1.25px)] [background-size:24px_24px]"
    >
      <div
        class="z-20 flex shrink-0 items-center justify-between border-b border-border/40 bg-card/80 px-6 py-3 backdrop-blur-sm"
      >
        <div class="flex items-center gap-3">
          <span class="text-[13px] font-medium text-foreground">
            {{ $t('MACROS.EDITOR.FLOW_CANVAS') }}
          </span>
          <span
            class="rounded-full border border-primary/20 bg-primary/10 px-2 py-0.5 text-[11.5px] font-medium text-primary"
          >
            {{ $t('MACROS.EDITOR.STEPS', { n: macro.actions.length }) }}
          </span>
        </div>
      </div>

      <div
        class="custom-scrollbar flex flex-1 flex-col items-center overflow-y-auto p-12"
      >
        <div
          :inert="readOnly"
          :class="{ 'opacity-75': readOnly }"
          class="relative flex w-full flex-col items-center transition-transform duration-200"
          :style="zoomStyle"
        >
          <MacroNodes
            v-model="macro.actions"
            :files="files"
            :errors="errors"
            @add-new-node="appendNode"
            @delete-node="deleteNode"
            @reset-action="resetNode"
          />
        </div>
      </div>

      <div
        class="absolute bottom-6 right-6 z-20 flex flex-col overflow-hidden rounded-lg border border-border/60 bg-card shadow-sm"
      >
        <button
          type="button"
          class="border-b border-border/40 p-2 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          @click="zoomIn"
        >
          <span class="i-lucide-plus size-4 block" />
        </button>
        <button
          type="button"
          class="border-b border-border/40 p-2 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          @click="zoomOut"
        >
          <span class="i-lucide-minus size-4 block" />
        </button>
        <button
          type="button"
          class="p-2 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          @click="resetZoom"
        >
          <span class="i-lucide-maximize size-4 block" />
        </button>
      </div>
    </div>
    <div class="h-full w-full shrink-0 border-l border-border/40 lg:w-[420px]">
      <MacroProperties
        :macro-name="macro.name"
        :macro-visibility="macro.visibility"
        :can-manage-public-macros="canManagePublicMacros"
        :read-only="readOnly"
        @update:name="updateName"
        @update:visibility="updateVisibility"
        @submit="submit"
        @close="$emit('close')"
      />
    </div>
  </div>
</template>
