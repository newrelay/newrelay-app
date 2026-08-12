<script setup>
import { ref } from 'vue';
import Input from './Input.vue';
import Label from '../label/Label.vue';

const value = ref('');
</script>

<template>
  <Story title="Relay/Input" :layout="{ type: 'grid', width: '480px' }">
    <Variant title="Default">
      <div class="flex flex-col gap-2 p-4 bg-n-background">
        <Input v-model="value" placeholder="Enter text…" />
        <p class="text-xs text-n-slate-11">Value: {{ value || '—' }}</p>
      </div>
    </Variant>

    <Variant title="With label">
      <div class="flex flex-col gap-2 p-4 bg-n-background">
        <Label html-for="relay-email">Email</Label>
        <Input id="relay-email" type="email" placeholder="you@example.com" />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="p-4 bg-n-background">
        <Input disabled model-value="Read only value" />
      </div>
    </Variant>
  </Story>
</template>
