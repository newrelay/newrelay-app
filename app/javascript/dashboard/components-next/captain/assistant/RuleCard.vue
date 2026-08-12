<script setup>
import { computed, ref, watch } from 'vue';
import { RelayButton } from 'dashboard/components-next/relay';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  content: {
    type: String,
    required: true,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'hover', 'edit', 'delete']);

const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});

const isEditing = ref(false);
const editedContent = ref(props.content);

const localContent = ref(props.content);

watch(
  () => props.content,
  newVal => {
    localContent.value = newVal;
  }
);

const startEdit = () => {
  isEditing.value = true;
  editedContent.value = props.content;
};

const saveEdit = () => {
  isEditing.value = false;
  localContent.value = editedContent.value;
  emit('edit', { id: props.id, content: editedContent.value });
};
</script>

<template>
  <div
    class="group relative flex items-start gap-4 rounded-xl border border-border bg-card p-5 transition-all hover:shadow-sm"
    :class="{ 'border-primary/50 bg-primary/[0.02]': isSelected }"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div
      v-if="selectable"
      class="mt-0.5 flex size-5 shrink-0 cursor-pointer items-center justify-center rounded-full border transition-colors"
      :class="
        isSelected
          ? 'border-primary bg-primary text-primary-foreground shadow-xs'
          : 'border-border/80 bg-background/50'
      "
      @click="modelValue = !modelValue"
    >
      <span v-if="isSelected" class="i-lucide-check size-3 stroke-[3]" />
    </div>
    <div class="min-w-0 flex-1">
      <InlineInput
        v-if="isEditing"
        v-model="editedContent"
        focus-on-mount
        @keyup.enter="saveEdit"
      />
      <span v-else class="text-sm text-foreground">
        {{ localContent }}
      </span>
    </div>
    <div class="flex shrink-0 items-center gap-1">
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:text-foreground"
        @click="startEdit"
      >
        <span class="i-lucide-pen size-3.5" />
      </RelayButton>
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:bg-destructive/10 hover:text-destructive"
        @click="emit('delete', id)"
      >
        <span class="i-lucide-trash size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
