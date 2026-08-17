<script setup>
import { computed } from 'vue';
import {
  TooltipRoot,
  TooltipTrigger,
  TooltipContent,
  TooltipPortal,
} from 'reka-ui';
import { TOOLTIP_CONTENT_CLASS } from './constants';

const props = defineProps({
  content: {
    type: [String, Number, Object],
    default: '',
  },
  side: {
    type: String,
    default: 'bottom',
    validator: value => ['top', 'bottom', 'left', 'right'].includes(value),
  },
  align: {
    type: String,
    default: 'center',
    validator: value => ['start', 'center', 'end'].includes(value),
  },
  sideOffset: {
    type: Number,
    default: 4,
  },
  delayDuration: {
    type: Number,
    default: undefined,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const tooltipText = computed(() => {
  const { content } = props;
  if (content == null || content === false) return '';
  if (typeof content === 'object') return content.content ?? '';
  return String(content);
});

const resolvedDelayDuration = computed(() => {
  if (props.delayDuration != null) return props.delayDuration;
  if (typeof props.content === 'object' && props.content?.delay?.show != null) {
    return props.content.delay.show;
  }
  return undefined;
});

const isVisible = computed(() => !props.disabled && Boolean(tooltipText.value));
</script>

<template>
  <TooltipRoot v-if="isVisible" :delay-duration="resolvedDelayDuration">
    <TooltipTrigger as-child>
      <slot />
    </TooltipTrigger>
    <TooltipPortal>
      <TooltipContent
        :side="side"
        :align="align"
        :side-offset="sideOffset"
        :class="TOOLTIP_CONTENT_CLASS"
      >
        {{ tooltipText }}
      </TooltipContent>
    </TooltipPortal>
  </TooltipRoot>
  <slot v-else />
</template>
