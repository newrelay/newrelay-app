<script setup>
import { reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayButton, RelayTextarea } from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const emit = defineEmits(['close', 'save']);

const { t } = useI18n();

const composerForm = reactive({
  outcome: 'answered',
  notes: '',
});

const CALL_OUTCOMES = [
  {
    value: 'answered',
    labelKey: 'CONVERSATION.REPLYBOX.LOG_CALL.OUTCOMES.ANSWERED',
  },
  {
    value: 'voicemail',
    labelKey: 'CONVERSATION.REPLYBOX.LOG_CALL.OUTCOMES.VOICEMAIL',
  },
  {
    value: 'busy',
    labelKey: 'CONVERSATION.REPLYBOX.LOG_CALL.OUTCOMES.BUSY',
  },
];

const submitComposer = () => {
  emit('save', {
    outcome: composerForm.outcome,
    notes: composerForm.notes.trim(),
  });
  emit('close');
};
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      class="flex items-center justify-center p-4 animate-in fade-in duration-200"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="emit('close')"
    >
      <div
        class="flex w-full max-w-md flex-col overflow-hidden rounded-xl border border-border bg-card shadow-lg"
      >
        <RelayModalHeader @close="emit('close')">
          <template #title>
            <h2
              class="flex items-center gap-2 text-base font-medium tracking-tight text-foreground"
            >
              <span class="i-lucide-phone size-5 text-primary" />
              {{ t('CONVERSATION.REPLYBOX.LOG_CALL.TITLE') }}
            </h2>
          </template>
        </RelayModalHeader>
        <div class="flex flex-col gap-5" :class="[RELAY_MODAL_BODY_CLASS]">
          <div class="flex flex-col gap-2">
            <label class="text-foreground text-[13.5px] font-[500]">{{
              t('CONVERSATION.REPLYBOX.LOG_CALL.OUTCOME')
            }}</label>
            <div class="flex gap-2">
              <RelayButton
                v-for="outcome in CALL_OUTCOMES"
                :key="outcome.value"
                :variant="
                  composerForm.outcome === outcome.value ? 'default' : 'outline'
                "
                size="sm"
                class="h-9 flex-1 text-sm font-medium"
                @click="composerForm.outcome = outcome.value"
              >
                {{ t(outcome.labelKey) }}
              </RelayButton>
            </div>
          </div>
          <div class="flex flex-col gap-2">
            <label class="text-foreground text-[13.5px] font-[500]">{{
              t('CONVERSATION.REPLYBOX.LOG_CALL.NOTES')
            }}</label>
            <RelayTextarea
              v-model="composerForm.notes"
              :placeholder="
                t('CONVERSATION.REPLYBOX.LOG_CALL.NOTES_PLACEHOLDER')
              "
              class-name="min-h-[100px] resize-none"
            />
          </div>
        </div>
        <div
          class="flex justify-end gap-2 border-t border-border bg-muted/10 px-6 py-4"
        >
          <RelayButton
            variant="outline"
            class="border border-border text-sm font-medium hover:border-transparent"
            @click="emit('close')"
          >
            {{ t('CONVERSATION.REPLYBOX.LOG_CALL.CANCEL') }}
          </RelayButton>
          <RelayButton class="text-sm font-medium" @click="submitComposer">
            {{ t('CONVERSATION.REPLYBOX.LOG_CALL.SAVE') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
