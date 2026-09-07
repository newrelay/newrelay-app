<script setup>
import { ref } from 'vue';
import Calendar from './Calendar.vue';

const selected = ref(new Date());
</script>

<template>
  <Story title="Relay/Calendar" :layout="{ type: 'grid', width: '320px' }">
    <Variant title="Default">
      <div class="p-4 bg-background">
        <Calendar v-model="selected" />
      </div>
    </Variant>

    <Variant title="Compact, no footer">
      <div class="p-4 bg-background">
        <Calendar :model-value="selected" compact :show-footer="false" />
      </div>
    </Variant>
  </Story>
</template>
