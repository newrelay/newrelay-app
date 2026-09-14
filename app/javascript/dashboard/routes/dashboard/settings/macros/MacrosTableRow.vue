<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
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
    class="group grid grid-cols-[1.5fr_1fr_1fr_1fr_80px] items-center px-6 py-3.5 transition-colors hover:bg-accent"
  >
    <div
      class="min-w-0 cursor-pointer truncate pr-4 text-[14px] font-medium text-foreground transition-colors hover:text-primary"
      @click="$emit('edit', macro.id)"
    >
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
    <div class="text-[13px] text-muted-foreground">
      {{ visibilityLabel }}
    </div>

    <!-- Actions -->
    <div
      class="flex items-center justify-end gap-1 opacity-0 transition-opacity group-hover:opacity-100"
    >
      <RelayTooltip :content="editTooltip" side="top">
        <button
          type="button"
          class="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          @click="$emit('edit', macro.id)"
        >
          <Icon icon="i-lucide-pencil" class="size-4" />
        </button>
      </RelayTooltip>
      <RelayTooltip :content="$t('MACROS.DELETE.TOOLTIP')" side="top">
        <button
          v-if="canManageMacro"
          type="button"
          class="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
          @click="$emit('delete')"
        >
          <Icon icon="i-lucide-trash-2" class="size-4" />
        </button>
      </RelayTooltip>
    </div>
  </div>
</template>
