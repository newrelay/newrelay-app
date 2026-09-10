<script>
import { RELAY_RADIO_INPUT_CLASS } from 'dashboard/components-next/relay';

export default {
  props: {
    name: {
      type: String,
      default: 'string',
    },
    label: {
      type: String,
      default: '',
    },
    items: {
      type: Array,
      default: () => [],
    },
    action: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    return { RELAY_RADIO_INPUT_CLASS };
  },
};
</script>

<template>
  <div>
    <label class="mb-1 block text-[13.5px] font-[500] text-foreground">{{
      label
    }}</label>
    <div class="mb-2 flex flex-wrap gap-x-3 gap-y-1">
      <label
        v-for="item in items"
        :key="item.id"
        class="flex cursor-pointer items-center gap-2.5 text-[13.5px] font-[500] text-foreground"
      >
        <input
          :class="RELAY_RADIO_INPUT_CLASS"
          :name="`${name} -radio-input`"
          type="radio"
          :checked="item.checked"
          @change="action({ ...item, checked: true })"
        />
        <span>{{ item.title }}</span>
      </label>
    </div>
  </div>
</template>
