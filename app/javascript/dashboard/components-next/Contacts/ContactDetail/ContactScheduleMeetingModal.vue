<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

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
    class="fixed inset-0 z-[100] flex items-center justify-center bg-n-alpha-black2 p-4 backdrop-blur-[4px] animate-in fade-in duration-200"
    @click.self="emit('close')"
  >
    <div
      class="flex w-full max-w-md flex-col overflow-hidden rounded-xl border border-border bg-card shadow-lg"
    >
      <div
        class="flex items-center justify-between border-b border-border bg-muted/30 px-6 py-4"
      >
        <h2
          class="flex items-center gap-2 text-lg font-semibold text-foreground"
        >
          <span class="i-lucide-calendar size-5 text-primary" />
          {{ t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.TITLE') }}
        </h2>
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 text-muted-foreground hover:text-foreground"
          @click="emit('close')"
        >
          <span class="i-lucide-x size-4" />
        </RelayButton>
      </div>
      <div class="flex flex-col gap-5 p-6">
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-foreground">{{
            t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.DATE')
          }}</label>
          <input
            v-model="form.date"
            type="date"
            class="w-full rounded-md border border-input bg-background p-2.5 text-sm text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-foreground">{{
            t('CONVERSATION.REPLYBOX.SCHEDULE_MEETING.TIME')
          }}</label>
          <input
            v-model="form.time"
            type="time"
            class="w-full rounded-md border border-input bg-background p-2.5 text-sm text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
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
    class="fixed inset-0 z-[60] flex items-center justify-center bg-n-alpha-black2 p-4 backdrop-blur-[4px]"
    @click.self="emit('close')"
  >
    <div
      class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl animate-in fade-in zoom-in-95 duration-200"
    >
      <div
        class="flex shrink-0 items-center justify-between border-b border-border/40 px-8 pb-0 pt-8"
      >
        <div>
          <h2 class="text-base font-semibold leading-6 text-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE') }}
          </h2>
          <p class="mt-1 text-sm text-muted-foreground">
            {{
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.SUBTITLE', {
                name: contactName,
              })
            }}
          </p>
        </div>
        <RelayButton
          variant="ghost"
          size="icon"
          class="size-8 rounded-full text-muted-foreground hover:text-foreground"
          @click="emit('close')"
        >
          <span class="i-lucide-x size-4" />
        </RelayButton>
      </div>

      <div class="flex-1 space-y-6 overflow-y-auto px-8 pb-8 pt-4">
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.MEETING_TITLE') }}
          </label>
          <RelayInput
            v-model="form.title"
            :placeholder="
              t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TITLE_PLACEHOLDER')
            "
            class-name="h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.DATE') }}
            </label>
            <input
              v-model="form.date"
              type="date"
              class="flex h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.SCHEDULE_MEETING.TIME') }}
            </label>
            <input
              v-model="form.time"
              type="time"
              class="flex h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
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
            class="min-h-[100px] w-full resize-none rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
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
