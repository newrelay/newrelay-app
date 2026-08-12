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
  <div
    class="flex flex-col w-full h-full lg:flex-row border border-border/60 bg-card rounded-2xl shadow-2xl overflow-hidden"
  >
    <div
      class="flex-1 w-full h-full max-h-full ltr:pl-12 ltr:pr-6 rtl:pl-6 rtl:pr-12 py-12 overflow-y-auto lg:w-auto relative bg-[radial-gradient(#cbd5e1_1.25px,transparent_1.25px)] dark:bg-[radial-gradient(#334155_1.25px,transparent_1.25px)] [background-size:24px_24px]"
    >
      <div
        :inert="readOnly"
        :class="{ 'opacity-75': readOnly }"
        class="transition-transform duration-200"
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
      <!-- Zoom Controls -->
      <div
        class="absolute bottom-6 right-6 flex flex-col bg-card border border-border/60 rounded-xl shadow-sm overflow-hidden z-20"
      >
        <button
          class="p-2.5 text-muted-foreground hover:text-foreground hover:bg-muted transition-colors border-b border-border/40"
          @click="zoomIn"
        >
          <span class="i-lucide-plus size-4 block" />
        </button>
        <button
          class="p-2.5 text-muted-foreground hover:text-foreground hover:bg-muted transition-colors border-b border-border/40"
          @click="zoomOut"
        >
          <span class="i-lucide-minus size-4 block" />
        </button>
        <button
          class="p-2.5 text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
          @click="resetZoom"
        >
          <span class="i-lucide-maximize size-4 block" />
        </button>
      </div>
    </div>
    <div class="w-full lg:w-[380px] h-full shrink-0 border-l border-border/40">
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
