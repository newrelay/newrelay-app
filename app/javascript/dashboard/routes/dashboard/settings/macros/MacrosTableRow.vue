<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
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
    class="group grid grid-cols-[1.5fr_1fr_1fr_1fr_100px] items-center px-6 py-4 transition-colors hover:bg-muted/20"
  >
    <!-- Name -->
    <div class="truncate pr-4 text-[14px] font-medium text-foreground">
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
      <span class="truncate text-[13.5px] text-muted-foreground">{{
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
      <span class="truncate text-[13.5px] text-muted-foreground">{{
        updatedByName || '--'
      }}</span>
    </div>

    <!-- Visibility -->
    <div>
      <span
        class="inline-flex items-center rounded-full border border-border/60 bg-muted px-2 py-0.5 text-[11px] font-medium capitalize text-muted-foreground"
      >
        {{ visibilityLabel }}
      </span>
    </div>

    <!-- Actions -->
    <div
      class="flex items-center justify-end gap-1 opacity-0 transition-opacity group-hover:opacity-100"
    >
      <RelayButton
        v-tooltip.top="editTooltip"
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
        @click="$emit('edit', macro.id)"
      >
        <Icon icon="i-lucide-pencil" class="size-3.5" />
      </RelayButton>
      <RelayButton
        v-if="canManageMacro"
        v-tooltip.top="$t('MACROS.DELETE.TOOLTIP')"
        variant="ghost"
        size="icon"
        class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-destructive/20 hover:bg-destructive/10 hover:text-destructive"
        @click="$emit('delete')"
      >
        <Icon icon="i-lucide-trash-2" class="size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
