<script setup>
import { ref } from 'vue';
import ActionDropdown from './ActionDropdown.vue';
import Button from '../button/Button.vue';

const lastAction = ref('—');

const menuItems = [
  { label: 'Edit', value: 'edit', icon: 'i-lucide-pencil' },
  { label: 'Duplicate', value: 'duplicate', icon: 'i-lucide-copy' },
  { label: 'Delete', value: 'delete', icon: 'i-lucide-trash-2' },
];

const menuSections = [
  {
    label: 'Assign to',
    items: [
      { label: 'Alice', value: 'alice' },
      { label: 'Bob', value: 'bob' },
    ],
  },
  {
    label: 'Status',
    items: [
      { label: 'Open', value: 'open' },
      { label: 'Resolved', value: 'resolved' },
    ],
  },
];

const onAction = item => {
  lastAction.value = item.value ?? item.label;
};
</script>

<template>
  <Story
    title="Relay/ActionDropdown"
    :layout="{ type: 'grid', width: '480px' }"
  >
    <Variant title="Flat items">
      <div class="flex flex-col items-start gap-2 p-8 bg-background">
        <ActionDropdown :menu-items="menuItems" @action="onAction">
          <template #trigger>
            <Button variant="outline">Actions</Button>
          </template>
        </ActionDropdown>
        <p class="text-xs text-muted-foreground">
          Last action: {{ lastAction }}
        </p>
      </div>
    </Variant>

    <Variant title="Sections with search">
      <div class="flex flex-col items-start gap-2 p-8 bg-background">
        <ActionDropdown
          :menu-sections="menuSections"
          show-search
          search-placeholder="Search…"
          @action="onAction"
        >
          <template #trigger>
            <Button variant="outline">Assign</Button>
          </template>
        </ActionDropdown>
        <p class="text-xs text-muted-foreground">
          Last action: {{ lastAction }}
        </p>
      </div>
    </Variant>
  </Story>
</template>
