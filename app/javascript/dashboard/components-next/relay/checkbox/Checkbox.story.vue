<script setup>
import { ref } from 'vue';
import Checkbox from './Checkbox.vue';
import Label from '../label/Label.vue';

const checked = ref(true);
const indeterminate = ref('indeterminate');
const disabledChecked = ref(true);
</script>

<template>
  <Story title="Relay/Checkbox" :layout="{ type: 'grid', width: '400px' }">
    <Variant title="Default">
      <div class="flex items-center gap-3 p-4 bg-n-background">
        <Checkbox id="relay-check" v-model="checked" />
        <Label html-for="relay-check">Accept terms</Label>
      </div>
    </Variant>

    <Variant title="Indeterminate">
      <div class="flex items-center gap-3 p-4 bg-n-background">
        <Checkbox v-model="indeterminate" />
        <span class="text-[13.5px] font-medium text-foreground">
          Partial selection
        </span>
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="flex items-center gap-3 p-4 bg-n-background">
        <Checkbox v-model="disabledChecked" disabled />
        <span class="text-[13.5px] font-medium text-muted-foreground">
          Disabled checked
        </span>
      </div>
    </Variant>
  </Story>
</template>
