<script>
export default {
  props: {
    title: { type: String, required: true },
    value: { type: [String, Number], default: '' },
  },
};
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <div class="flex items-center justify-between">
      <span class="text-[12px] font-semibold leading-normal text-foreground">
        {{ title }}
      </span>
      <slot name="button" />
    </div>
    <div
      class="break-words text-[13px] leading-normal"
      :class="value ? 'text-foreground' : 'text-muted-foreground'"
    >
      <slot>
        {{ value || '---' }}
      </slot>
    </div>
  </div>
</template>
