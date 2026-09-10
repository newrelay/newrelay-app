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
    class="macros__nodes relative mx-auto flex w-full max-w-[620px] select-none flex-col items-center"
  >
    <!-- Start Flow Node -->
    <div
      class="z-10 mb-2 flex items-center gap-3 rounded-full border border-border/70 bg-card px-5 py-2.5 shadow-sm"
    >
      <div
        class="flex size-7 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground"
      >
        <span class="i-lucide-play size-3.5 block fill-current" />
      </div>
      <span class="text-[13px] font-medium text-foreground">
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
    <div class="relative z-30 flex w-full max-w-[620px] justify-center">
      <button
        type="button"
        class="group flex h-[44px] min-w-[160px] cursor-pointer items-center justify-center gap-2 rounded-full border-0 bg-primary px-6 text-[13.5px] font-medium text-primary-foreground shadow-sm transition-all hover:bg-primary/90"
        :title="$t('MACROS.EDITOR.ADD_BTN_TOOLTIP')"
        @click="$emit('addNewNode')"
      >
        <span class="i-lucide-plus size-4 block" />
        <span class="tracking-tight">{{
          $t('MACROS.EDITOR.ADD_BTN_TOOLTIP')
        }}</span>
      </button>
    </div>

    <div class="z-0 h-8 w-px border-l border-dashed border-primary/40" />

    <div
      class="z-10 mt-2 flex items-center gap-3 rounded-full border border-border/70 bg-card px-5 py-2 shadow-sm"
    >
      <div
        class="flex size-7 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground"
      >
        <span class="i-lucide-square size-3 block fill-current" />
      </div>
      <span class="text-[13.5px] font-medium tracking-tight text-primary">
        {{ $t('MACROS.EDITOR.END_FLOW') }}
      </span>
    </div>
  </div>
</template>
