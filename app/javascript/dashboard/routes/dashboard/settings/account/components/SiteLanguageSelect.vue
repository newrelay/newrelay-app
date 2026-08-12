<script setup>
import { ref, computed } from 'vue';
import { cn } from 'dashboard/components-next/relay/utils/cn';
import { RelayButton } from 'dashboard/components-next/relay';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  id: { type: String, default: undefined },
  options: {
    type: Array,
    required: true,
    validator: value =>
      value.every(option => 'value' in option && 'label' in option),
  },
  placeholder: { type: String, default: '' },
  modelValue: { type: [String, Number], default: '' },
  disabled: { type: Boolean, default: false },
  searchPlaceholder: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);

const open = ref(false);

const menuItems = computed(() =>
  props.options.map(option => ({
    label: option.label,
    value: option.value,
    action: 'select',
    isSelected: option.value === props.modelValue,
  }))
);

const selectedLabel = computed(() => {
  const selected = props.options.find(
    option => option.value === props.modelValue
  );
  return selected?.label ?? props.placeholder;
});

const toggleDropdown = () => {
  if (props.disabled) return;
  open.value = !open.value;
};

const closeDropdown = () => {
  open.value = false;
};

const handleAction = ({ value }) => {
  emit('update:modelValue', value);
  closeDropdown();
};
</script>

<template>
  <div v-on-clickaway="closeDropdown" class="relative w-full min-w-0">
    <RelayButton
      :id="id"
      type="button"
      variant="outline"
      size="lg"
      :disabled="disabled"
      :class="
        cn(
          'w-full h-10 justify-between text-sm font-normal bg-background shadow-xs',
          hasError && 'border-destructive focus-visible:ring-destructive/30'
        )
      "
      @click="toggleDropdown"
    >
      <span :class="cn('truncate', !modelValue && 'text-muted-foreground')">
        {{ selectedLabel }}
      </span>
      <span
        class="i-lucide-chevron-down size-4 text-muted-foreground opacity-50"
        aria-hidden="true"
      />
    </RelayButton>
    <DropdownMenu
      v-if="open"
      :menu-items="menuItems"
      show-search
      :search-placeholder="searchPlaceholder"
      class="top-full z-50 mt-1 w-full ltr:left-0 rtl:right-0"
      @action="handleAction"
    />
  </div>
</template>
