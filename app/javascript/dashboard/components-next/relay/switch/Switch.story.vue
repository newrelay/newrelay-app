<script setup>
import { ref } from 'vue';
import Switch from './Switch.vue';
import Label from '../label/Label.vue';

const enabled = ref(true);
const disabledOff = ref(false);
</script>

<template>
  <Story title="Relay/Switch" :layout="{ type: 'grid', width: '400px' }">
    <Variant title="Default">
      <div class="flex items-center gap-3 p-4 bg-background">
        <Switch id="relay-switch" v-model="enabled" />
        <Label html-for="relay-switch">
          {{ enabled ? 'On' : 'Off' }}
        </Label>
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="flex items-center gap-3 p-4 bg-background">
        <Switch v-model="disabledOff" disabled />
        <span class="text-sm text-muted-foreground">Disabled</span>
      </div>
    </Variant>
  </Story>
</template>
