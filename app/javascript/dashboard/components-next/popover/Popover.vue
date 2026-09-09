<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useBreakpoints, breakpointsTailwind } from '@vueuse/core';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  align: {
    type: String,
    default: 'end',
    validator: v => ['start', 'end'].includes(v),
  },
  disableMobileView: {
    type: Boolean,
    default: false,
  },
  showContentBorder: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['show', 'hide']);

const isActive = ref(false);
const triggerRef = ref(null);
const popoverRef = ref(null);
const mobileContentRef = ref(null);

const breakpoints = useBreakpoints(breakpointsTailwind);
const belowMd = breakpoints.smaller('md');
const isMobile = computed(() => !props.disableMobileView && belowMd.value);
const showPopover = computed(() => isActive.value && !isMobile.value);

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  popoverRef,
  showPopover,
  { align: props.align }
);

const show = async () => {
  isActive.value = true;
  if (!isMobile.value) {
    await nextTick();
    updatePosition();
  }
  emit('show');
};

const hide = () => {
  if (!isActive.value) return;
  isActive.value = false;
  emit('hide');
};

const toggle = async () => {
  if (isActive.value) hide();
  else await show();
};

// Recalculate position when switching from mobile to desktop while open
watch(isMobile, async mobile => {
  if (!isActive.value || mobile) return;
  await nextTick();
  updatePosition();
});

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  hide();
};

// Selectors for teleported elements that should not trigger close
const clickOutsideIgnore = [
  'dialog.ProseMirror-prompt-backdrop',
  '[data-popover-content]',
];

useKeyboardEvents({
  Escape: {
    action: () => isActive.value && hide(),
    allowOnFocusedInput: true,
  },
});

defineExpose({ show, hide, toggle });
</script>

<template>
  <span ref="triggerRef" class="inline-flex" @click="toggle">
    <slot :is-open="isActive" />
  </span>

  <TeleportWithDirection to="body">
    <!-- Mobile: centered modal with backdrop -->
    <div
      v-if="isActive && isMobile"
      data-popover-backdrop
      class="fixed inset-0 z-[9999] flex items-start pt-[clamp(3rem,15vh,12rem)] justify-center bg-background/80 backdrop-blur-[8px]"
    >
      <div
        ref="mobileContentRef"
        v-on-click-outside="[
          handleClickOutside,
          { ignore: clickOutsideIgnore },
        ]"
        data-popover-content
        class="relative mx-4 flex max-h-[calc(100vh-4rem)] w-full max-w-lg flex-col overflow-hidden rounded-md border border-border bg-popover text-popover-foreground shadow-md"
      >
        <div
          class="min-h-0 flex-1 overflow-y-auto overscroll-contain rounded-md no-scrollbar"
        >
          <slot name="content" :hide="hide" />
        </div>
      </div>
    </div>

    <!-- Desktop: fixed popover -->
    <div
      v-else-if="showPopover"
      ref="popoverRef"
      v-on-click-outside="[handleClickOutside, { ignore: clickOutsideIgnore }]"
      data-popover-content
      :class="fixedPosition.class"
      :style="fixedPosition.style"
      class="flex flex-col rounded-md border border-border bg-popover text-popover-foreground shadow-md"
    >
      <div
        class="min-h-0 flex-1 overflow-y-auto overscroll-contain rounded-md no-scrollbar"
        :class="{ 'border border-border': showContentBorder }"
      >
        <slot name="content" :hide="hide" />
      </div>
    </div>
  </TeleportWithDirection>
</template>
