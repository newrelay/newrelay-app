<script setup>
import { computed } from 'vue';
import { useDropdownContext } from './provider.js';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  DROPDOWN_MENU_ITEM_BASE_CLASS,
  getDropdownItemInteractionClass,
} from 'dashboard/components-next/relay/dropdown-menu/constants';
import { cn } from 'dashboard/components-next/relay/utils/cn';

const props = defineProps({
  label: { type: String, default: '' },
  icon: { type: [String, Object, Function], default: '' },
  link: { type: [String, Object], default: '' },
  nativeLink: { type: Boolean, default: false },
  click: { type: Function, default: null },
  preserveOpen: { type: Boolean, default: false },
  destructive: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  active: { type: Boolean, default: false },
});

defineOptions({
  inheritAttrs: false,
});

const { closeMenu } = useDropdownContext();

const componentIs = computed(() => {
  if (props.link) {
    if (props.nativeLink && typeof props.link === 'string') {
      return 'a';
    }

    return 'router-link';
  }
  if (props.click) return 'button';

  return 'div';
});

const itemClass = computed(() =>
  cn(
    DROPDOWN_MENU_ITEM_BASE_CLASS,
    getDropdownItemInteractionClass(
      props.destructive ? { destructive: true } : {}
    ),
    props.active && 'font-medium text-primary',
    props.disabled && 'pointer-events-none opacity-50'
  )
);

const triggerClick = () => {
  if (props.disabled) return;
  if (props.click) {
    props.click();
  }
  if (!props.preserveOpen) closeMenu();
};
</script>

<template>
  <li class="list-none">
    <component
      :is="componentIs"
      v-bind="$attrs"
      :class="itemClass"
      :href="componentIs === 'a' ? props.link : null"
      :to="componentIs === 'router-link' ? props.link : null"
      :disabled="componentIs === 'button' ? disabled : undefined"
      @click="triggerClick"
    >
      <slot>
        <slot name="icon">
          <Icon v-if="icon" :icon="icon" />
        </slot>
        <slot name="label">{{ label }}</slot>
      </slot>
    </component>
  </li>
</template>
