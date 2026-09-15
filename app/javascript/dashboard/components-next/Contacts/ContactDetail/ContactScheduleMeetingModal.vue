<script setup>
import { computed, reactive, ref } from 'vue';
import { format, isValid, parse, startOfDay } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  RelayButton,
  RelayCalendar,
  RelayInput,
  RelayTextarea,
  RelayTimePicker,
  DATE_PICKER_TRIGGER_CLASS,
} from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

defineProps({
  contactName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const form = reactive({
  title: '',
  date: '',
  time: '',
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
    return t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.DATE');
  }
  return format(selectedDate.value, 'dd-MM-yyyy');
});

const canSubmit = computed(
  () => Boolean(form.title.trim()) && Boolean(form.date)
);

const selectDate = date => {
  form.date = date ? format(date, 'dd-MM-yyyy') : '';
  showDateCalendar.value = false;
};

const submit = () => {
  useAlert(t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.GAP_MESSAGE'));
  emit('close');
};
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      class="flex items-center justify-center p-4"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="emit('close')"
    >
      <div
        class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-y-auto rounded-xl border border-border bg-card shadow-2xl animate-in fade-in zoom-in-95 duration-200"
      >
        <RelayModalHeader
          :title="t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE')"
          :description="
            t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.SUBTITLE', {
              name: contactName,
            })
          "
          @close="emit('close')"
        />

        <div class="space-y-6 px-6 pb-6 pt-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.MEETING_TITLE') }}
            </label>
            <RelayInput
              v-model="form.title"
              :placeholder="
                t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE_PLACEHOLDER')
              "
              class-name="h-9 px-3 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.DATE') }}
              </label>
              <button
                type="button"
                :class="DATE_PICKER_TRIGGER_CLASS"
                @click="showDateCalendar = !showDateCalendar"
              >
                <span
                  :class="
                    selectedDate
                      ? 'text-foreground'
                      : 'text-muted-foreground/60'
                  "
                >
                  {{ dateLabel }}
                </span>
                <span class="i-lucide-calendar size-4 text-muted-foreground" />
              </button>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TIME') }}
              </label>
              <RelayTimePicker
                v-model="form.time"
                trigger-class="h-9 w-full cursor-pointer px-3 text-[14px] rounded-md border border-border/80 bg-background text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
              />
            </div>
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
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.NOTES') }}
            </label>
            <RelayTextarea
              v-model="form.notes"
              :placeholder="
                t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.NOTES_PLACEHOLDER')
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
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="w-full text-sm font-medium"
            :disabled="!canSubmit"
            @click="submit"
          >
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.SUBMIT') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
