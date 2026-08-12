<script setup>
import Spinner from './Spinner.vue';
</script>

<template>
  <Story title="Components/Spinner" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <Spinner size="24" class="text-muted-foreground" />
      <Spinner size="32" class="text-destructive" />
      <Spinner size="40" class="text-warning" />
      <Spinner size="48" class="text-success" />
      <Spinner size="64" class="text-primary" />
    </Variant>
  </Story>
</template>
