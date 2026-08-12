<script>
import Draggable from 'vuedraggable';
import MacroNode from './MacroNode.vue';
import { getFileName } from './macroHelper';

export default {
  components: {
    Draggable,
    MacroNode,
  },
  props: {
    errors: {
      type: Object,
      default: () => ({}),
    },
    modelValue: {
      type: Array,
      default: () => [],
    },
    files: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['update:modelValue', 'resetAction', 'deleteNode', 'addNewNode'],
  computed: {
    actionData: {
      get() {
        return this.modelValue;
      },
      set(value) {
        this.$emit('update:modelValue', value);
      },
    },
  },
  methods: {
    fileName() {
      return getFileName(...arguments);
    },
  },
};
</script>

<template>
  <div
    class="macros__nodes flex flex-col items-center w-full max-w-[600px] mx-auto relative select-none"
  >
    <!-- Start Flow Node -->
    <div
      class="flex items-center gap-3 px-6 h-[48px] bg-card border border-border/60 rounded-full shadow-sm z-10 mb-2"
    >
      <div
        class="size-7 rounded-full bg-primary flex items-center justify-center text-primary-foreground shrink-0"
      >
        <span class="i-lucide-play size-3.5 fill-current block" />
      </div>
      <span class="text-[14px] font-semibold text-primary tracking-tight">
        {{ $t('MACROS.EDITOR.START_FLOW') }}
      </span>
    </div>

    <!-- Draggable List -->
    <Draggable
      :list="actionData"
      animation="200"
      item-key="id"
      ghost-class="ghost"
      tag="div"
      class="w-full flex flex-col items-center"
      handle=".macros__node-drag-handle"
    >
      <template #item="{ index: i }">
        <div :key="i" class="flex flex-col items-center w-full">
          <!-- Vertical Line -->
          <div class="w-px h-8 border-l border-dashed border-primary/40 z-0" />

          <MacroNode
            v-model="actionData[i]"
            class="macros__node-action z-10 w-full"
            :index="i"
            :error-key="errors[`action_${i}`]"
            :file-name="
              fileName(
                actionData[i].action_params[0],
                actionData[i].action_name,
                files
              )
            "
            :single-node="actionData.length === 1"
            @reset-action="$emit('resetAction', i)"
            @delete-node="$emit('deleteNode', i)"
          />
        </div>
      </template>
    </Draggable>

    <!-- Line before Add Action -->
    <div class="w-px h-8 border-l border-dashed border-primary/40 z-0" />

    <!-- Add Action Node -->
    <div class="w-full max-w-[600px] relative z-30 flex justify-center">
      <button
        type="button"
        class="flex items-center justify-center gap-2 px-6 h-[48px] min-w-[140px] bg-primary hover:bg-primary/90 text-primary-foreground rounded-full shadow-sm transition-all group border-0 text-[14px] font-semibold cursor-pointer"
        :title="$t('MACROS.EDITOR.ADD_BTN_TOOLTIP')"
        @click="$emit('addNewNode')"
      >
        <span class="i-lucide-plus size-4 block" />
        <span class="tracking-tight">{{
          $t('MACROS.EDITOR.ADD_BTN_TOOLTIP')
        }}</span>
      </button>
    </div>

    <!-- Line to End -->
    <div class="w-px h-8 border-l border-dashed border-primary/40 z-0" />

    <!-- End Flow Node -->
    <div
      class="flex items-center gap-3 px-6 h-[48px] bg-card border border-border/60 rounded-full shadow-sm z-10 mt-2"
    >
      <div
        class="size-7 rounded-full bg-primary flex items-center justify-center text-primary-foreground shrink-0"
      >
        <span class="i-lucide-square size-3 fill-current block" />
      </div>
      <span class="text-[14px] font-semibold text-primary tracking-tight">
        {{ $t('MACROS.EDITOR.END_FLOW') }}
      </span>
    </div>
  </div>
</template>
