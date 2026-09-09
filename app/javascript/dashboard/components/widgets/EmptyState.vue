<script>
export default {
  props: {
    title: { type: String, default: '' },
    message: { type: String, default: '' },
  },
};
</script>

<template>
  <div
    class="flex h-full min-h-0 flex-1 flex-col items-center justify-center px-1 py-16"
  >
    <h3
      v-if="title"
      class="capitalize text-foreground block text-center w-full text-[20px] font-[600]"
    >
      {{ title }}
    </h3>
    <p
      v-if="message"
      class="block text-center text-muted-foreground my-4 mx-auto w-[90%]"
    >
      {{ message }}
    </p>
    <slot />
  </div>
</template>
