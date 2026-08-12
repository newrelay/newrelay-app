<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, url, minLength } from '@vuelidate/validators';
import wootConstants from 'dashboard/constants/globals';
import { getI18nKey } from 'dashboard/routes/dashboard/settings/helper/settingsHelper';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayCheckbox,
} from 'dashboard/components-next/relay';

const props = defineProps({
  value: {
    type: Object,
    default: () => ({}),
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
  submitLabel: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();
const { EXAMPLE_WEBHOOK_URL } = wootConstants;
const { inboxEventsEnabled } = useConfig();

const SUPPORTED_WEBHOOK_EVENTS = [
  'conversation_created',
  'conversation_status_changed',
  'conversation_updated',
  'message_created',
  'message_updated',
  'webwidget_triggered',
  'contact_created',
  'contact_updated',
  'conversation_typing_on',
  'conversation_typing_off',
];

const webhookUrl = ref(props.value.url || '');
const name = ref(props.value.name || '');
const subscriptions = ref([...(props.value.subscriptions || [])]);
const secretVisible = ref(false);

const supportedWebhookEvents = inboxEventsEnabled
  ? [...SUPPORTED_WEBHOOK_EVENTS, 'inbox_updated']
  : SUPPORTED_WEBHOOK_EVENTS;

const rules = {
  webhookUrl: { required, minLength: minLength(7), url },
  subscriptions: { required },
};

const v$ = useVuelidate(rules, { webhookUrl, subscriptions });

const hasSecret = computed(() => !!props.value.secret);

const webhookURLInputPlaceholder = computed(() =>
  t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.PLACEHOLDER', {
    webhookExampleURL: EXAMPLE_WEBHOOK_URL,
  })
);

const isEventChecked = event => subscriptions.value.includes(event);

const setEvent = (event, checked) => {
  if (checked) {
    if (!isEventChecked(event)) {
      subscriptions.value = [...subscriptions.value, event];
    }
    return;
  }
  subscriptions.value = subscriptions.value.filter(item => item !== event);
};

const onSubmit = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;
  emit('submit', {
    url: webhookUrl.value,
    name: name.value,
    subscriptions: subscriptions.value,
  });
};

const copySecret = async () => {
  await copyTextToClipboard(props.value.secret);
  useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.COPY_SUCCESS'));
};
</script>

<template>
  <form class="flex w-full flex-col gap-5" @submit.prevent="onSubmit">
    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.LABEL') }}
      </label>
      <RelayInput
        v-model="webhookUrl"
        type="text"
        :placeholder="webhookURLInputPlaceholder"
        class-name="h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        @blur="v$.webhookUrl.$touch()"
      />
      <p v-if="v$.webhookUrl.$error" class="text-[12.5px] text-destructive">
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.FORM.END_POINT.ERROR') }}
      </p>
    </div>

    <div class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.FORM.NAME.LABEL') }}
      </label>
      <RelayInput
        v-model="name"
        type="text"
        :placeholder="t('INTEGRATION_SETTINGS.WEBHOOK.FORM.NAME.PLACEHOLDER')"
        class-name="h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
      />
    </div>

    <div v-if="hasSecret" class="flex flex-col gap-1.5">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.LABEL') }}
      </label>
      <div class="flex items-center gap-2">
        <div class="relative min-w-0 flex-1">
          <input
            :value="
              secretVisible ? value.secret : '••••••••••••••••••••••••••••••••'
            "
            type="text"
            readonly
            class="h-10 w-full rounded-md border border-border/80 bg-background pl-3 pr-10 font-mono text-[14px] text-foreground shadow-sm focus:outline-none"
          />
          <button
            type="button"
            class="absolute top-1/2 -translate-y-1/2 p-1 text-muted-foreground transition-colors hover:text-foreground ltr:right-2.5 rtl:left-2.5"
            @click="secretVisible = !secretVisible"
          >
            <Icon
              :icon="secretVisible ? 'i-lucide-eye-off' : 'i-lucide-eye'"
              class="size-4"
            />
          </button>
        </div>
        <RelayButton
          type="button"
          variant="outline"
          class="h-10 shrink-0 border-border/80 bg-card px-3 hover:bg-muted"
          @click="copySecret"
        >
          <Icon icon="i-lucide-copy" class="size-4" />
        </RelayButton>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <label class="text-[13.5px] font-medium text-foreground">
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.LABEL') }}
      </label>
      <div class="flex flex-col gap-2.5">
        <div
          v-for="event in supportedWebhookEvents"
          :key="event"
          class="flex items-center gap-3 text-[13.5px] text-foreground"
        >
          <RelayCheckbox
            :model-value="isEventChecked(event)"
            @update:model-value="checked => setEvent(event, checked)"
          />
          <span>
            {{
              `${t(
                getI18nKey(
                  'INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS',
                  event
                )
              )} (${event})`
            }}
          </span>
        </div>
      </div>
    </div>

    <div
      class="mt-2 flex items-center justify-end gap-3 border-t border-border/40 pt-4"
    >
      <RelayButton
        type="button"
        variant="ghost"
        class="h-10 border border-border/40 px-5 font-semibold text-muted-foreground hover:border-transparent hover:bg-muted"
        @click="emit('cancel')"
      >
        {{ t('INTEGRATION_SETTINGS.WEBHOOK.FORM.CANCEL') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="h-10 px-6 font-semibold"
        :disabled="v$.$invalid || isSubmitting"
      >
        {{ submitLabel }}
      </RelayButton>
    </div>
  </form>
</template>
