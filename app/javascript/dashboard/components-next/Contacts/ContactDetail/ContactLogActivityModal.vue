<script setup>
import { computed, reactive, ref } from 'vue';
import { format, isValid, parse, startOfDay } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  RelayButton,
  RelayCalendar,
  RelayTextarea,
  DATE_PICKER_TRIGGER_CLASS,
} from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  contactName: {
    type: String,
    default: '',
  },
  initialType: {
    type: String,
    default: '',
  },
  variant: {
    type: String,
    default: 'default',
    validator: value => ['default', 'composer'].includes(value),
  },
});

const emit = defineEmits(['close', 'save']);

const { t } = useI18n();

const form = reactive({
  type: props.initialType || 'Call',
  date: '',
  notes: '',
});

const showDateCalendar = ref(false);

const selectedDate = computed(() => {
  if (!form.date) return null;
  const parsed = parse(form.date, 'dd-MM-yyyy', new Date());
  return isValid(parsed) ? startOfDay(parsed) : null;
});

const dateLabel = computed(() => {
  if (!selectedDate.value) {
    return t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.DATE');
  }
  return format(selectedDate.value, 'MMM d, yyyy');
});

const selectDate = date => {
  form.date = date ? format(date, 'dd-MM-yyyy') : '';
  showDateCalendar.value = false;
};

const ACTIVITY_TYPES = [
  {
    value: 'Call',
    labelKey: 'CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.TYPES.CALL',
    icon: 'i-lucide-phone',
  },
  {
    value: 'Meeting',
    labelKey: 'CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.TYPES.MEETING',
    icon: 'i-lucide-users',
  },
  {
    value: 'Email',
    labelKey: 'CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.TYPES.EMAIL',
    icon: 'i-lucide-mail',
  },
];

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

const canSubmit = computed(
  () => Boolean(form.date) && Boolean(form.notes.trim())
);

const submitComposer = () => {
  emit('save', {
    outcome: composerForm.outcome,
    notes: composerForm.notes.trim(),
  });
  emit('close');
};

const submit = () => {
  // Gap: no contact activity log API yet — UI shell only.
  useAlert(t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.GAP_MESSAGE'));
  emit('close');
};
</script>

<template>
  <TeleportWithDirection v-if="variant === 'composer'" to="body">
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
  <TeleportWithDirection v-else to="body">
    <div
      class="flex items-center justify-center p-4"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="emit('close')"
    >
      <div
        class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-y-auto rounded-xl border border-border bg-card shadow-2xl animate-in fade-in zoom-in-95 duration-200"
      >
        <RelayModalHeader
          :title="t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.TITLE')"
          :description="
            t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.SUBTITLE', {
              name: contactName,
            })
          "
          @close="emit('close')"
        />

        <div class="space-y-6" :class="[RELAY_MODAL_BODY_CLASS]">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.TYPE') }}
            </label>
            <div class="flex gap-3">
              <RelayButton
                v-for="activityType in ACTIVITY_TYPES"
                :key="activityType.value"
                :variant="
                  form.type === activityType.value ? 'default' : 'outline'
                "
                class="h-9 flex-1 text-sm font-medium"
                @click="form.type = activityType.value"
              >
                <span class="size-4" :class="activityType.icon" />
                {{ t(activityType.labelKey) }}
              </RelayButton>
            </div>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-[500] text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.DATE') }}
            </label>
            <button
              type="button"
              :class="DATE_PICKER_TRIGGER_CLASS"
              @click="showDateCalendar = !showDateCalendar"
            >
              <span
                :class="
                  selectedDate ? 'text-foreground' : 'text-muted-foreground/60'
                "
              >
                {{ dateLabel }}
              </span>
              <span class="i-lucide-calendar size-4 text-muted-foreground" />
            </button>
          </div>

          <div
            v-if="showDateCalendar"
            class="flex justify-center rounded-md border border-border p-4"
          >
            <RelayCalendar
              :model-value="selectedDate"
              @select="selectDate"
              @clear="() => selectDate(null)"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.NOTES') }}
            </label>
            <RelayTextarea
              v-model="form.notes"
              :placeholder="
                t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.NOTES_PLACEHOLDER')
              "
              class-name="min-h-[100px] resize-none"
            />
          </div>
        </div>

        <div
          class="mt-auto flex shrink-0 gap-3 border-t border-border bg-muted/10 p-6"
        >
          <RelayButton
            variant="outline"
            class="w-full border border-border text-sm font-medium hover:border-transparent"
            @click="emit('close')"
          >
            {{ t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="w-full text-sm font-medium"
            :disabled="!canSubmit"
            @click="submit"
          >
            {{ t('CONTACTS_LAYOUT.DETAIL.LOG_ACTIVITY.SUBMIT') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
