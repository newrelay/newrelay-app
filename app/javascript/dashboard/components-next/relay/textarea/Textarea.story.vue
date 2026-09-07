<script setup>
import { ref } from 'vue';
import Textarea from './Textarea.vue';
import Label from '../label/Label.vue';

const value = ref('');
</script>

<template>
  <Story title="Relay/Textarea" :layout="{ type: 'grid', width: '480px' }">
    <Variant title="Default">
      <div class="flex flex-col gap-2 p-4 bg-background">
        <Textarea v-model="value" placeholder="Write a message…" :rows="4" />
        <p class="text-xs text-muted-foreground">Value: {{ value || '—' }}</p>
      </div>
    </Variant>

    <Variant title="With label">
      <div class="flex flex-col gap-2 p-4 bg-background">
        <Label html-for="relay-note">Note</Label>
        <Textarea id="relay-note" placeholder="Add internal note…" :rows="3" />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="p-4 bg-background">
        <Textarea disabled model-value="Read only value" :rows="3" />
      </div>
    </Variant>
  </Story>
</template>
