<script setup>
import { ref } from 'vue';
import DatePicker from './DatePicker.vue';

const date = ref(null);
</script>

<template>
  <Story title="Relay/DatePicker" :layout="{ type: 'grid', width: '320px' }">
    <Variant title="Default">
      <div class="flex flex-col gap-2 p-8 bg-background">
        <DatePicker v-model="date" placeholder="Select a date" />
        <p class="text-xs text-muted-foreground">
          Value: {{ date ? date.toString() : '—' }}
        </p>
      </div>
    </Variant>
  </Story>
</template>
