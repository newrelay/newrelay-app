<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
  canManagePublicMacros: {
    type: Boolean,
    default: true,
  },
});
defineEmits(['delete', 'edit']);
const { t } = useI18n();

const createdByName = computed(() => {
  const createdBy = props.macro.created_by;
  return createdBy.available_name ?? createdBy.email ?? '';
});

const updatedByName = computed(() => {
  const updatedBy = props.macro.updated_by;
  return updatedBy.available_name ?? updatedBy.email ?? '';
});

const visibilityLabel = computed(() => {
  const i18nKey =
    props.macro.visibility === 'global'
      ? 'MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL'
      : 'MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL';
  return t(i18nKey);
});

const canManageMacro = computed(
  () => props.canManagePublicMacros || props.macro.visibility !== 'global'
);

const editTooltip = computed(() =>
  canManageMacro.value ? t('MACROS.EDIT.TOOLTIP') : t('MACROS.VIEW.TOOLTIP')
);
</script>

<template>
  <div
    class="grid grid-cols-[1.5fr_1fr_1fr_1fr_100px] items-center px-6 py-4 hover:bg-muted/20 transition-colors group"
  >
    <!-- Name -->
    <div class="font-medium text-[14px] text-foreground pr-4 truncate">
      {{ macro.name }}
    </div>

    <!-- Created By -->
    <div class="flex items-center gap-2.5">
      <Avatar
        v-if="macro.created_by"
        :name="createdByName"
        :src="macro.created_by.avatar_url"
        :size="24"
        rounded-full
        class="flex-shrink-0"
      />
      <span class="text-[13.5px] text-muted-foreground truncate">{{
        createdByName || '--'
      }}</span>
    </div>

    <!-- Last Updated By -->
    <div class="flex items-center gap-2.5">
      <Avatar
        v-if="macro.updated_by"
        :name="updatedByName"
        :src="macro.updated_by.avatar_url"
        :size="24"
        rounded-full
        class="flex-shrink-0"
      />
      <span class="text-[13.5px] text-muted-foreground truncate">{{
        updatedByName || '--'
      }}</span>
    </div>

    <!-- Visibility -->
    <div>
      <span
        class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-muted text-muted-foreground border border-border/60 capitalize"
      >
        {{ visibilityLabel }}
      </span>
    </div>

    <!-- Actions -->
    <div
      class="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
    >
      <button
        class="p-1.5 text-muted-foreground hover:text-foreground hover:bg-muted rounded-md transition-colors cursor-pointer border-0 bg-transparent"
        :title="editTooltip"
        @click="$emit('edit', macro.id)"
      >
        <span class="i-lucide-edit size-4 block" />
      </button>
      <button
        v-if="canManageMacro"
        class="p-1.5 text-muted-foreground hover:text-destructive hover:bg-destructive/10 rounded-md transition-colors cursor-pointer border-0 bg-transparent"
        :title="$t('MACROS.DELETE.TOOLTIP')"
        @click="$emit('delete')"
      >
        <span class="i-lucide-trash-2 size-4 block" />
      </button>
    </div>
  </div>
</template>
