<script>
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
        class="flex cursor-pointer items-center text-[13.5px] font-[500] text-foreground"
      >
        <input
          class="mr-2.5 text-[14px] border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 shadow-sm rounded-md"
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
