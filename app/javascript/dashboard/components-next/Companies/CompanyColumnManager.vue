<script setup>
import { useI18n } from 'vue-i18n';

const props = defineProps({
  visibleColumns: {
    type: Object,
    default: () => ({
      company: true,
      industry: true,
      phone: true,
      email: true,
      contacts: true,
      website: true,
      owner: true,
    }),
  },
});

const emit = defineEmits(['update:visibleColumns']);
const { t } = useI18n();

const columns = [
  { key: 'company', labelKey: 'COMPANIES.COLUMNS.COMPANY', locked: true },
  { key: 'industry', labelKey: 'COMPANIES.COLUMNS.INDUSTRY' },
  { key: 'phone', labelKey: 'COMPANIES.COLUMNS.PHONE' },
  { key: 'email', labelKey: 'COMPANIES.COLUMNS.EMAIL' },
  { key: 'website', labelKey: 'COMPANIES.COLUMNS.WEBSITE' },
  { key: 'owner', labelKey: 'COMPANIES.COLUMNS.OWNER' },
  { key: 'contacts', labelKey: 'COMPANIES.COLUMNS.CONTACTS' },
];

const toggleColumn = key => {
  if (key === 'company') return;
  emit('update:visibleColumns', {
    ...props.visibleColumns,
    [key]: !props.visibleColumns[key],
  });
};
</script>

<template>
  <div class="flex w-48 flex-col gap-0.5 p-1">
    <button
      v-for="col in columns"
      :key="col.key"
      type="button"
      class="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left text-sm text-foreground hover:bg-accent"
      :class="{ 'cursor-not-allowed opacity-70': col.locked }"
      :disabled="col.locked"
      @click="toggleColumn(col.key)"
    >
      <span
        class="i-lucide-check size-4"
        :class="visibleColumns[col.key] ? 'opacity-100' : 'opacity-0'"
      />
      <span>{{ t(col.labelKey) }}</span>
    </button>
  </div>
</template>
