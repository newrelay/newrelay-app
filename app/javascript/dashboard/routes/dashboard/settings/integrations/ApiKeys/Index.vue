<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

import SettingsLayout from '../../SettingsLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');

const showToken = ref(false);
const isAccountIdCopied = ref(false);
const isResetConfirm = ref(false);

const accessToken = computed(() => currentUser.value?.access_token || '');
const accountId = computed(() => currentAccount.value?.id?.toString() || '');

const copyAccountId = async () => {
  await copyTextToClipboard(accountId.value);
  isAccountIdCopied.value = true;
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
  setTimeout(() => {
    isAccountIdCopied.value = false;
  }, 2000);
};

const copyAccessToken = async () => {
  await copyTextToClipboard(accessToken.value);
  useAlert(t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.COPY_SUCCESS'));
};

const resetAccessToken = async () => {
  if (!isResetConfirm.value) {
    isResetConfirm.value = true;
    return;
  }
  isResetConfirm.value = false;
  const success = await store.dispatch('resetAccessToken');
  if (success) {
    useAlert(t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.RESET_SUCCESS'));
  } else {
    useAlert(t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.RESET_ERROR'));
  }
};
</script>

<template>
  <SettingsLayout :no-records-found="false">
    <template #body>
      <div class="space-y-6">
        <div>
          <h2 class="text-base font-medium text-foreground">
            {{ t('INTEGRATION_SETTINGS.API_KEYS.HEADER') }}
          </h2>
          <p
            class="mt-1.5 max-w-4xl text-[13.5px] leading-relaxed text-muted-foreground"
          >
            {{ t('INTEGRATION_SETTINGS.API_KEYS.DESCRIPTION') }}
          </p>
        </div>

        <section
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <header class="flex gap-4 border-b border-border/40 p-4 sm:p-6">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
            >
              <Icon icon="i-lucide-code" class="size-5 text-primary" />
            </div>
            <div>
              <h3 class="text-base font-semibold text-foreground">
                {{
                  t('INTEGRATION_SETTINGS.API_KEYS.ACCOUNT_ID.SECTION_TITLE')
                }}
              </h3>
              <p class="mt-1 text-sm leading-relaxed text-muted-foreground">
                {{
                  t(
                    'INTEGRATION_SETTINGS.API_KEYS.ACCOUNT_ID.SECTION_DESCRIPTION'
                  )
                }}
              </p>
            </div>
          </header>
          <div class="flex flex-col gap-1.5 p-4 sm:p-6">
            <label
              for="api-account-id"
              class="text-[13.5px] font-medium text-foreground"
            >
              {{ t('INTEGRATION_SETTINGS.API_KEYS.ACCOUNT_ID.TITLE') }}
            </label>
            <div class="flex items-center gap-3">
              <RelayInput
                id="api-account-id"
                :model-value="accountId"
                readonly
                class-name="h-10 min-w-0 flex-1 shadow-xs"
              />
              <RelayButton
                type="button"
                variant="outline"
                size="lg"
                class="shrink-0"
                @click="copyAccountId"
              >
                <span
                  :class="
                    isAccountIdCopied
                      ? 'i-lucide-check size-3.5'
                      : 'i-lucide-copy size-3.5'
                  "
                />
                {{
                  isAccountIdCopied
                    ? t('INTEGRATION_SETTINGS.API_KEYS.ACCOUNT_ID.COPIED')
                    : t('INTEGRATION_SETTINGS.API_KEYS.ACCOUNT_ID.COPY')
                }}
              </RelayButton>
            </div>
            <p class="text-[13px] leading-relaxed text-muted-foreground">
              {{ t('INTEGRATION_SETTINGS.API_KEYS.ACCOUNT_ID.DESCRIPTION') }}
            </p>
          </div>
        </section>

        <section
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <header class="flex gap-4 border-b border-border/40 p-4 sm:p-6">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
            >
              <Icon icon="i-lucide-key-round" class="size-5 text-primary" />
            </div>
            <div>
              <h3 class="text-base font-semibold text-foreground">
                {{ t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.TITLE') }}
              </h3>
              <p class="mt-1 text-sm leading-relaxed text-muted-foreground">
                {{
                  t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.DESCRIPTION')
                }}
              </p>
            </div>
          </header>
          <div class="flex flex-col gap-3 p-4 sm:p-6">
            <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div class="relative min-w-0 flex-1">
                <RelayInput
                  :type="showToken ? 'text' : 'password'"
                  :model-value="accessToken"
                  readonly
                  class-name="h-10 font-mono ltr:pr-10 rtl:pl-10"
                />
                <button
                  type="button"
                  class="absolute top-1/2 -translate-y-1/2 p-1 text-muted-foreground transition-colors hover:text-foreground ltr:right-2.5 rtl:left-2.5"
                  @click="showToken = !showToken"
                >
                  <Icon
                    :icon="showToken ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                    class="size-4"
                  />
                </button>
              </div>
              <div class="flex shrink-0 items-center gap-2">
                <RelayButton
                  type="button"
                  variant="outline"
                  class="h-10 border-border/80 bg-card px-4 hover:bg-accent"
                  @click="copyAccessToken"
                >
                  <Icon icon="i-lucide-copy" class="size-4" />
                  {{ t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.COPY') }}
                </RelayButton>
                <RelayButton
                  type="button"
                  variant="outline"
                  class="h-10 border-border/80 bg-card px-4 hover:bg-accent"
                  :class="
                    isResetConfirm
                      ? 'border-destructive/40 text-destructive hover:bg-destructive/10'
                      : ''
                  "
                  @click="resetAccessToken"
                  @blur="isResetConfirm = false"
                >
                  <Icon icon="i-lucide-key-round" class="size-4" />
                  {{
                    isResetConfirm
                      ? t(
                          'INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.CONFIRM_RESET'
                        )
                      : t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.RESET')
                  }}
                </RelayButton>
              </div>
            </div>
            <p v-if="isResetConfirm" class="text-[12px] text-muted-foreground">
              {{ t('INTEGRATION_SETTINGS.API_KEYS.ACCESS_TOKEN.CONFIRM_HINT') }}
            </p>
          </div>
        </section>
      </div>
    </template>
  </SettingsLayout>
</template>
