<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  open: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['add', 'cancel', 'update:open']);

const { t } = useI18n();

const state = reactive({
  id: '',
  title: '',
  description: '',
  instruction: '',
});

const rules = {
  title: { required, minLength: minLength(1) },
  description: { required },
  instruction: { required },
};

const v$ = useVuelidate(rules, state);

const titleError = computed(() =>
  v$.value.title.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.ERROR')
    : ''
);

const descriptionError = computed(() =>
  v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.ERROR')
    : ''
);

const instructionError = computed(() =>
  v$.value.instruction.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.ERROR')
    : ''
);

const resetState = () => {
  Object.assign(state, {
    id: '',
    title: '',
    description: '',
    instruction: '',
  });
  v$.value.$reset();
};

watch(
  () => props.open,
  isOpen => {
    if (isOpen) {
      resetState();
    }
  }
);

const onClickAdd = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  await emit('add', { ...state });
  resetState();
  emit('update:open', false);
};

const onClickCancel = () => {
  resetState();
  emit('cancel');
  emit('update:open', false);
};
</script>

<template>
  <div>
    <div
      v-if="open"
      class="mb-6 rounded-xl border border-border bg-card p-6 shadow-sm"
    >
      <div class="flex flex-col gap-6">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="new-scenario-title"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="new-scenario-title"
            v-model="state.title"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
            "
            class-name="rounded-md border-border/80 bg-background text-[14px] shadow-sm"
          />
          <p v-if="titleError" class="text-xs text-destructive">
            {{ titleError }}
          </p>
        </div>

        <TextArea
          v-model="state.description"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.PLACEHOLDER'
            )
          "
          :message="descriptionError"
          :message-type="descriptionError ? 'error' : 'info'"
          show-character-count
        />
        <Editor
          v-model="state.instruction"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.PLACEHOLDER'
            )
          "
          :message="instructionError"
          :message-type="instructionError ? 'error' : 'info'"
          :show-character-count="false"
          enable-captain-tools
        />

        <div class="flex items-center gap-2">
          <RelayButton
            variant="outline"
            class="h-9 px-4"
            @click="onClickCancel"
          >
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="h-9 px-6"
            :disabled="!state.title"
            @click="onClickAdd"
          >
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CREATE') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
