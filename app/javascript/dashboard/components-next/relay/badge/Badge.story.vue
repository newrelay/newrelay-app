<script setup>
import Badge from './Badge.vue';

const VARIANTS = ['default', 'secondary', 'destructive', 'outline'];
</script>

<template>
  <Story title="Relay/Badge" :layout="{ type: 'grid', width: '480px' }">
    <Variant title="Variants">
      <div class="flex flex-wrap gap-2 p-4 bg-n-background">
        <Badge v-for="variant in VARIANTS" :key="variant" :variant="variant">
          {{ variant }}
        </Badge>
      </div>
    </Variant>
  </Story>
</template>
