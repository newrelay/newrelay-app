<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { frontendURL } from '../../../../helper/URLHelper';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  integrationId: {
    type: [String, Number],
    required: true,
  },
  integrationName: { type: String, default: '' },
  integrationDescription: { type: String, default: '' },
  integrationEnabled: { type: Boolean, default: false },
  integrationAction: { type: String, default: '' },
  actionButtonText: { type: String, default: '' },
  deleteConfirmationText: { type: Object, default: () => ({}) },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { replaceInstallationName } = useBranding();

const dialogRef = ref(null);

const accountId = computed(() => store.getters.getCurrentAccountId);

const openDeletePopup = () => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const closeDeletePopup = () => {
  if (dialogRef.value) {
    dialogRef.value.close();
  }
};

const deleteIntegration = async () => {
  try {
    await store.dispatch('integrations/deleteIntegration', props.integrationId);
    useAlert(t('INTEGRATION_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE'));
  }
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteIntegration();
  router.push({ name: 'settings_applications' });
};
</script>

<template>
  <div
    class="flex flex-col items-start justify-between gap-6 rounded-xl border border-border/60 bg-card p-6 lg:flex-row lg:items-center"
  >
    <div
      class="m-0 flex flex-1 flex-col items-start justify-start gap-6 lg:flex-row lg:items-center"
    >
      <div class="flex h-16 w-16 shrink-0 items-center justify-center">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="block max-w-full rounded-md border border-border bg-accent shadow-sm dark:hidden dark:bg-accent"
        />
        <img
          :src="`/dashboard/images/integrations/${integrationId}-dark.png`"
          class="hidden max-w-full rounded-md border border-border bg-accent shadow-sm dark:block dark:bg-accent"
        />
      </div>
      <div>
        <h3 class="mb-1 capitalize text-base font-semibold text-foreground">
          {{ integrationName }}
        </h3>
        <p class="text-[13px] leading-relaxed text-muted-foreground">
          {{ replaceInstallationName(integrationDescription) }}
        </p>
      </div>
    </div>
    <div class="mb-0 flex items-center justify-center">
      <router-link
        :to="
          frontendURL(
            `accounts/${accountId}/settings/integrations/` + integrationId
          )
        "
      >
        <div v-if="integrationEnabled">
          <RelayButton
            v-if="integrationAction === 'disconnect'"
            variant="ghost"
            class="h-9 px-4 text-[13px] font-semibold text-destructive hover:bg-destructive/10 hover:text-destructive"
            @click="openDeletePopup"
          >
            {{
              actionButtonText ||
              $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
            }}
          </RelayButton>
          <RelayButton v-else variant="outline" class="h-9 px-4 text-[13px]">
            {{ t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
          </RelayButton>
        </div>
      </router-link>
      <div v-if="!integrationEnabled">
        <slot name="action">
          <a :href="integrationAction">
            <RelayButton class="h-9 px-4 text-[13px]">
              {{ t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') }}
            </RelayButton>
          </a>
        </slot>
      </div>
    </div>
    <Dialog
      ref="dialogRef"
      type="alert"
      :title="
        deleteConfirmationText.title ||
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')
      "
      :description="
        deleteConfirmationText.message ||
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE')
      "
      :confirm-button-label="
        t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')
      "
      :cancel-button-label="t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </div>
</template>
