<script setup>
import { ref } from 'vue';
import TimePicker from './TimePicker.vue';

const time = ref('');
</script>

<template>
  <Story title="Relay/TimePicker" :layout="{ type: 'grid', width: '320px' }">
    <Variant title="Default">
      <div class="flex flex-col gap-2 p-8 bg-background">
        <TimePicker v-model="time" />
        <p class="text-xs text-muted-foreground">Value: {{ time || '—' }}</p>
      </div>
    </Variant>
  </Story>
</template>
