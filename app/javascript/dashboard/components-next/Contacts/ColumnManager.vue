<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  visibleColumns: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:visibleColumns']);

const { t } = useI18n();
const customAttributes = useMapGetter('attributes/getContactAttributes');

const standardColumns = [
  { key: 'email', label: t('CONTACTS_LAYOUT.FILTER.EMAIL') },
  { key: 'phoneNumber', label: t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER') },
  { key: 'company', label: t('CONTACTS_LAYOUT.FILTER.COMPANY') },
  { key: 'createdAt', label: t('CONTACTS_LAYOUT.FILTER.CREATED_AT') },
  { key: 'lastActivity', label: t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY') },
  { key: 'tags', label: t('CONTACTS_LAYOUT.FILTER.TAGS') },
];

const allColumns = computed(() => {
  const dynamicCols = (customAttributes.value || []).map(attr => ({
    key: `custom_${attr.attributeKey}`,
    label: attr.attributeDisplayName || attr.attributeKey,
  }));
  return [...standardColumns, ...dynamicCols];
});

const toggleColumn = (key, checked) => {
  let updated = [...props.visibleColumns];
  if (checked) {
    if (!updated.includes(key)) updated.push(key);
  } else {
    updated = updated.filter(c => c !== key);
  }
  emit('update:visibleColumns', updated);
};

const itemClass =
  'flex w-full cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-left text-sm text-foreground transition-colors hover:bg-accent hover:text-accent-foreground';
</script>

<template>
  <div class="min-w-48 p-1">
    <div
      class="flex cursor-not-allowed items-center gap-2 rounded-sm px-2 py-1.5 text-sm text-muted-foreground opacity-70"
    >
      <span class="i-lucide-check size-4 text-foreground" />
      <span>{{ t('CONTACTS_LAYOUT.FILTER.NAME') }}</span>
    </div>

    <button
      v-for="col in allColumns"
      :key="col.key"
      type="button"
      :class="itemClass"
      @click="toggleColumn(col.key, !visibleColumns.includes(col.key))"
    >
      <span
        class="i-lucide-check size-4 text-foreground"
        :class="visibleColumns.includes(col.key) ? 'opacity-100' : 'opacity-0'"
      />
      <span>{{ col.label }}</span>
    </button>
  </div>
</template>
