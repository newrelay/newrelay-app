<script>
export default {
  props: {
    headerTitle: { type: String, default: '' },
    headerContent: { type: String, default: '' },
  },
};
</script>

<template>
  <div class="mb-8 w-full border-b border-border/40 pb-4">
    <h3 class="capitalize mb-1 text-base font-medium text-foreground">
      {{ headerTitle }}
    </h3>
    <p
      v-dompurify-html="headerContent"
      class="text-[14px] leading-relaxed text-muted-foreground"
    />
  </div>
</template>
