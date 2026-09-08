<script setup>
import { computed, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  RelayButton,
  RelayInput,
  RelayDatePicker,
  RelayTimePicker,
} from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';

defineProps({
  contactName: {
    type: String,
    default: '',
  },
  variant: {
    type: String,
    default: 'default',
    validator: value => ['default', 'composer'].includes(value),
  },
});

const emit = defineEmits(['close', 'insert']);

const { t } = useI18n();

const form = reactive({
  title: '',
  date: '',
  time: '',
  notes: '',
});

const canSubmit = computed(
  () => Boolean(form.title.trim()) && Boolean(form.date)
);

const submitComposer = () => {
  const date =
    form.date || t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.DATE_FALLBACK');
  const time =
    form.time || t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.TIME_FALLBACK');
  const link = t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.MEETING_LINK');
  const text = t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.INSERT_TEMPLATE', {
    date,
    time,
    link,
  });
  emit('insert', `\n\n${text}`);
  emit('close');
};

const submit = () => {
  useAlert(t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.GAP_MESSAGE'));
  emit('close');
};
</script>

<template>
  <div
    v-if="variant === 'composer'"
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
            <span class="i-lucide-calendar size-5 text-primary" />
            {{ t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.TITLE') }}
          </h2>
        </template>
      </RelayModalHeader>
      <div class="flex flex-col gap-5" :class="[RELAY_MODAL_BODY_CLASS]">
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">{{
            t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.DATE')
          }}</label>
          <RelayDatePicker
            v-model="form.date"
            value-format="dd-MM-yyyy"
            display-format="dd-MM-yyyy"
            :placeholder="t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.DATE')"
          />
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">{{
            t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.TIME')
          }}</label>
          <RelayTimePicker v-model="form.time" />
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
          {{ t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.CANCEL') }}
        </RelayButton>
        <RelayButton class="text-sm font-medium" @click="submitComposer">
          {{ t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.INSERT_LINK') }}
        </RelayButton>
      </div>
    </div>
  </div>
  <div
    v-else
    class="flex items-center justify-center p-4"
    :class="[RELAY_DIALOG_OVERLAY_CLASS]"
    @click.self="emit('close')"
  >
    <div
      class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl animate-in fade-in zoom-in-95 duration-200"
    >
      <RelayModalHeader
        :title="t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE')"
        @close="emit('close')"
      >
        <template #description>
          <p class="mt-0.5 text-[13px] text-muted-foreground">
            {{
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.SUBTITLE', {
                name: contactName,
              })
            }}
          </p>
        </template>
      </RelayModalHeader>

      <div class="space-y-6" :class="[RELAY_MODAL_BODY_CLASS]">
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
            <RelayDatePicker
              v-model="form.date"
              value-format="dd-MM-yyyy"
              display-format="dd-MM-yyyy"
              :placeholder="t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.DATE')"
              trigger-class="h-9 w-full cursor-pointer px-3 text-[14px] rounded-md border border-border/80 bg-background text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TIME') }}
            </label>
            <RelayTimePicker
              v-model="form.time"
              trigger-class="h-9 w-full cursor-pointer px-3 text-[14px] rounded-md border border-border/80 bg-background text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
        </div>

        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.NOTES') }}
          </label>
          <textarea
            v-model="form.notes"
            :placeholder="
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.NOTES_PLACEHOLDER')
            "
            class="min-h-[100px] w-full resize-none rounded-md border border-border/80 bg-background px-3 py-2.5 text-[14px] placeholder:text-muted-foreground/60 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
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
</template>
