<script setup>
import { computed, inject } from 'vue';
import { useMacros } from 'dashboard/composables/useMacros';
import { useI18n } from 'vue-i18n';
import ActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';

const props = defineProps({
  singleNode: {
    type: Boolean,
    default: false,
  },
  errorKey: {
    type: String,
    default: '',
  },
  fileName: {
    type: String,
    default: '',
  },
});

defineEmits(['resetAction', 'deleteNode']);

const { t } = useI18n();
const macroActionTypes = inject('macroActionTypes');
const { getMacroDropdownValues } = useMacros();

const actionData = defineModel({
  type: Object,
  required: true,
});

const errorMessage = computed(() => {
  if (!props.errorKey) return '';
  return t(`MACROS.ERRORS.${props.errorKey}`);
});

const showActionInput = computed(() => {
  if (
    actionData.value.action_name === 'send_email_to_team' ||
    actionData.value.action_name === 'send_message'
  )
    return false;
  const type = macroActionTypes.value.find(
    action => action.key === actionData.value.action_name
  ).inputType;
  return !!type;
});

const dropdownValues = () => {
  return getMacroDropdownValues(actionData.value.action_name);
};
</script>

<template>
  <div
    class="w-full max-w-[600px] bg-slate-50/40 dark:bg-slate-900/40 border border-border/60 rounded-xl py-2.5 px-4 shadow-sm relative group transition-colors hover:border-primary/25 flex items-center justify-between gap-3 mx-auto"
    :class="
      errorKey ? 'animate-shake bg-destructive/10 border-destructive/40' : ''
    "
  >
    <!-- Drag Handle -->
    <div
      v-if="!singleNode"
      class="px-1 text-muted-foreground hover:text-foreground cursor-grab active:cursor-grabbing transition-colors macros__node-drag-handle shrink-0 flex items-center"
      :title="$t('MACROS.EDITOR.DRAG_TOOLTIP')"
    >
      <span class="i-lucide-menu size-4 block" />
    </div>

    <!-- Action Input Container -->
    <div class="flex-grow min-w-0 flex items-center">
      <ActionInput
        v-model="actionData"
        :action-types="macroActionTypes"
        :dropdown-values="dropdownValues()"
        :show-action-input="showActionInput"
        :show-remove-button="false"
        is-macro
        :error-message="errorMessage"
        :initial-file-name="fileName"
        @reset-action="$emit('resetAction')"
      />
    </div>

    <!-- Delete Action Button -->
    <button
      v-if="!singleNode"
      type="button"
      class="size-8 rounded-md bg-destructive/10 text-destructive/85 hover:text-destructive hover:bg-destructive/20 flex items-center justify-center transition-colors shrink-0 cursor-pointer border-0 outline-none"
      :title="$t('MACROS.EDITOR.DELETE_BTN_TOOLTIP')"
      @click="$emit('deleteNode')"
    >
      <span class="i-lucide-trash-2 size-4 block" />
    </button>
  </div>
</template>
