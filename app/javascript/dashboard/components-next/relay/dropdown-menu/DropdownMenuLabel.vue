<script setup>
import { DropdownMenuLabel } from 'reka-ui';
import { cn } from '../utils/cn';
import { DROPDOWN_MENU_LABEL_CLASS } from './constants';

defineOptions({ inheritAttrs: false });
</script>

<template>
  <DropdownMenuLabel :class="cn(DROPDOWN_MENU_LABEL_CLASS, $attrs.class)">
    <slot />
  </DropdownMenuLabel>
</template>
