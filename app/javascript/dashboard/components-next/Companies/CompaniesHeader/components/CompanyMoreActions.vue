<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayActionDropdown } from 'dashboard/components-next/relay';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['create']);

const { t } = useI18n();

const menuItems = computed(() => [
  {
    label: t('COMPANIES.ACTIONS.CREATE'),
    action: 'create',
    value: 'create',
    icon: 'i-lucide-plus',
  },
]);

const handleAction = ({ action }) => {
  if (action === 'create') emit('create');
};
</script>

<template>
  <RelayActionDropdown
    :menu-items="menuItems"
    align="end"
    content-class="w-52"
    @action="handleAction"
  >
    <template #trigger>
      <Button
        icon="i-lucide-ellipsis-vertical"
        color="slate"
        variant="ghost"
        size="sm"
      />
    </template>
  </RelayActionDropdown>
</template>
