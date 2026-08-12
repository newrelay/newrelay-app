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
    <h3 class="mb-1 text-lg font-semibold text-foreground">
      {{ headerTitle }}
    </h3>
    <p
      v-dompurify-html="headerContent"
      class="text-[13px] leading-relaxed text-muted-foreground"
    />
  </div>
</template>
