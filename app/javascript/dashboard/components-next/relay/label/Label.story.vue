<script setup>
import Label from './Label.vue';
import Input from '../input/Input.vue';
</script>

<template>
  <Story title="Relay/Label" :layout="{ type: 'grid', width: '400px' }">
    <Variant title="Default">
      <div class="flex flex-col gap-2 p-4 bg-n-background">
        <Label html-for="relay-name">Full name</Label>
        <Input id="relay-name" placeholder="Jane Doe" />
      </div>
    </Variant>
  </Story>
</template>
