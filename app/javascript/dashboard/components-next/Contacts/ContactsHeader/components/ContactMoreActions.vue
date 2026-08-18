<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayActionDropdown } from 'dashboard/components-next/relay';
import { usePolicy } from 'dashboard/composables/usePolicy';

const emit = defineEmits(['add', 'import', 'export']);

const { t } = useI18n();
const { checkPermissions } = usePolicy();

const contactMenuItems = computed(() => [
  ...(checkPermissions(['administrator', 'contact_manage'])
    ? [
        {
          label: t(
            'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.IMPORT_CONTACT'
          ),
          action: 'import',
          value: 'import',
          icon: 'i-lucide-download',
        },
        {
          label: t(
            'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.EXPORT_CONTACT'
          ),
          action: 'export',
          value: 'export',
          icon: 'i-lucide-upload',
        },
      ]
    : []),
]);

const handleContactAction = ({ action }) => {
  if (action === 'export') {
    emit('export');
  } else if (action === 'add') {
    emit('add');
  } else if (action === 'import') {
    emit('import');
  }
};
</script>

<template>
  <RelayActionDropdown
    v-if="contactMenuItems.length"
    :menu-items="contactMenuItems"
    align="end"
    content-class="min-w-48"
    @action="handleContactAction"
  >
    <template #trigger>
      <button
        type="button"
        class="flex size-9 items-center justify-center rounded-lg border border-border bg-background text-muted-foreground shadow-sm transition-all hover:border-transparent hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-0"
      >
        <span class="i-lucide-ellipsis-vertical size-4" />
      </button>
    </template>
  </RelayActionDropdown>
</template>
