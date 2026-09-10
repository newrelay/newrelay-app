<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import WebhookForm from './WebhookForm.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayModal,
  RELAY_MODAL_FORM_FOOTER_CLASS,
} from 'dashboard/components-next/relay';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const { replaceInstallationName } = useBranding();

const createdWebhook = ref(null);
const showSecret = ref(false);

const uiFlags = computed(() => store.getters['webhooks/getUIFlags']);

const modalTitle = computed(() =>
  createdWebhook.value
    ? t('INTEGRATION_SETTINGS.WEBHOOK.ADD.API.SUCCESS_MESSAGE')
    : t('INTEGRATION_SETTINGS.WEBHOOK.ADD.TITLE')
);

const modalDescription = computed(() => {
  if (createdWebhook.value) {
    return t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.CREATED_DESC');
  }
  return replaceInstallationName(t('INTEGRATION_SETTINGS.WEBHOOK.FORM.DESC'));
});

watch(
  () => props.show,
  visible => {
    if (visible) {
      createdWebhook.value = null;
      showSecret.value = false;
    }
  }
);

const handleClose = () => emit('close');

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
  <RelayModal
    :show="show"
    :title="modalTitle"
    :description="modalDescription"
    size="lg"
    flush
    @close="handleClose"
  >
    <template v-if="createdWebhook">
      <div class="space-y-5 px-6 pb-2">
        <div>
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
                class="h-10 w-full rounded-md border border-border/80 bg-background pl-3 pr-10 font-mono text-[14px] text-foreground shadow-sm focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
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
              size="lg"
              class="shrink-0 px-3"
              @click="handleCopySecret"
            >
              <Icon icon="i-lucide-copy" class="size-4" />
            </RelayButton>
          </div>
        </div>
      </div>

      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton size="lg" @click="handleClose">
          {{ t('INTEGRATION_SETTINGS.WEBHOOK.SECRET.DONE') }}
        </RelayButton>
      </div>
    </template>

    <WebhookForm
      v-else
      :is-submitting="uiFlags.creatingItem"
      :submit-label="t('INTEGRATION_SETTINGS.WEBHOOK.FORM.ADD_SUBMIT')"
      @submit="onSubmit"
      @cancel="handleClose"
    />
  </RelayModal>
</template>
