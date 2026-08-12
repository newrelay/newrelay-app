<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import WebhookForm from './WebhookForm.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  onClose: {
    type: Function,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { replaceInstallationName } = useBranding();

const createdWebhook = ref(null);
const showSecret = ref(false);

const uiFlags = computed(() => store.getters['webhooks/getUIFlags']);

const onSubmit = async webhook => {
  try {
    const result = await store.dispatch('webhooks/create', { webhook });
    createdWebhook.value = result;
  } catch (error) {
    const message =
      error.response?.data?.message ||
      t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
    useAlert(message);
  }
};

const handleCopySecret = async () => {
  await copyTextToClipboard(createdWebhook.value.secret);
  useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.COPY_SUCCESS'));
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <template v-if="createdWebhook">
      <div class="relative -mt-2 flex items-center justify-between">
        <h3 class="text-base font-semibold text-foreground">
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.ADD.API.SUCCESS_MESSAGE') }}
        </h3>
        <button
          type="button"
          class="text-muted-foreground transition-colors hover:text-foreground"
          @click="props.onClose()"
        >
          <Icon icon="i-lucide-x" class="size-5" />
        </button>
      </div>

      <div>
        <p class="mb-3 text-[13.5px] leading-relaxed text-muted-foreground">
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.CREATED_DESC') }}
        </p>
        <p class="mb-2 text-[13.5px] font-medium text-foreground">
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.LABEL') }}
        </p>
        <div class="flex items-center gap-2">
          <div class="relative flex-1">
            <input
              :type="showSecret ? 'text' : 'password'"
              :value="
                showSecret
                  ? createdWebhook.secret
                  : '••••••••••••••••••••••••••••••••'
              "
              readonly
              class="h-10 w-full rounded-md border border-border/80 bg-background pl-3 pr-10 font-mono text-[14px] text-foreground shadow-sm focus:outline-none"
            />
            <button
              type="button"
              class="absolute top-1/2 -translate-y-1/2 p-1 text-muted-foreground transition-colors hover:text-foreground ltr:right-2.5 rtl:left-2.5"
              @click="showSecret = !showSecret"
            >
              <Icon
                :icon="showSecret ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                class="size-4"
              />
            </button>
          </div>
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 shrink-0 border-border/80 bg-card px-3 hover:bg-muted"
            @click="handleCopySecret"
          >
            <Icon icon="i-lucide-copy" class="size-4" />
          </RelayButton>
        </div>
      </div>

      <div class="flex justify-end border-t border-border/40 pt-4">
        <RelayButton class="h-10 px-6" @click="props.onClose()">
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.DONE') }}
        </RelayButton>
      </div>
    </template>

    <template v-else>
      <div class="relative -mt-2 flex items-start justify-between gap-4">
        <div>
          <h3 class="text-base font-semibold text-foreground">
            {{ t('INTEGRATION_SETTINGS.WEBHOOK.ADD.TITLE') }}
          </h3>
          <p class="mt-1 text-[13.5px] leading-relaxed text-muted-foreground">
            {{
              replaceInstallationName(
                t('INTEGRATION_SETTINGS.WEBHOOK.FORM.DESC')
              )
            }}
          </p>
        </div>
        <button
          type="button"
          class="shrink-0 text-muted-foreground transition-colors hover:text-foreground"
          @click="props.onClose()"
        >
          <Icon icon="i-lucide-x" class="size-5" />
        </button>
      </div>

      <WebhookForm
        :is-submitting="uiFlags.creatingItem"
        :submit-label="t('INTEGRATION_SETTINGS.WEBHOOK.FORM.ADD_SUBMIT')"
        @submit="onSubmit"
        @cancel="props.onClose()"
      />
    </template>
  </div>
</template>
