<script setup>
import { DropdownMenuSeparator } from 'reka-ui';
import { cn } from '../utils/cn';
import { DROPDOWN_MENU_SEPARATOR_CLASS } from './constants';

defineOptions({ inheritAttrs: false });
</script>

<template>
  <DropdownMenuSeparator
    :class="cn(DROPDOWN_MENU_SEPARATOR_CLASS, $attrs.class)"
  />
</template>
