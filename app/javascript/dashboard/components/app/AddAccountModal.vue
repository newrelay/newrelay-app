<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayModal,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay';

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  hasAccounts: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['closeAccountCreateModal']);
const { t } = useI18n();
const route = useRoute();
const store = useStore();
const uiFlags = useMapGetter('agents/getUIFlags');

const accountName = ref('');
const v$ = useVuelidate(
  {
    accountName: { required, minLength: minLength(1) },
  },
  { accountName }
);

const close = () => emit('closeAccountCreateModal');

const addAccount = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const accountId = await store.dispatch('accounts/create', {
      account_name: accountName.value,
      parent_id: route.params.accountId,
    });
    close();
    useAlert(t('CREATE_ACCOUNT.API.SUCCESS_MESSAGE'));
    window.location = `/app/accounts/${accountId}/dashboard`;
  } catch (error) {
    if (error.response?.status === 422) {
      useAlert(t('CREATE_ACCOUNT.API.EXIST_MESSAGE'));
    } else {
      useAlert(t('CREATE_ACCOUNT.API.ERROR_MESSAGE'));
    }
  }
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="t('CREATE_ACCOUNT.NEW_ACCOUNT')"
    :description="t('CREATE_ACCOUNT.SELECTOR_SUBTITLE')"
    @close="close"
  >
    <form class="flex flex-col gap-5" @submit.prevent="addAccount">
      <div
        v-if="!hasAccounts"
        class="flex items-center gap-3 rounded-md border border-destructive/30 bg-destructive/10 px-3 py-2 text-[13.5px] text-foreground"
      >
        <span
          class="i-lucide-triangle-alert size-4 shrink-0 text-destructive"
        />
        {{ t('CREATE_ACCOUNT.NO_ACCOUNT_WARNING') }}
      </div>

      <div :class="RELAY_FORM_FIELD_CLASS">
        <RelayLabel :class="RELAY_FORM_LABEL_CLASS">
          {{ t('CREATE_ACCOUNT.FORM.NAME.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="accountName"
          type="text"
          :placeholder="t('CREATE_ACCOUNT.FORM.NAME.PLACEHOLDER')"
          class-name="h-9 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.accountName.$touch"
        />
      </div>

      <div class="flex justify-end gap-3">
        <RelayButton
          type="button"
          variant="outline"
          class="h-9 border-border bg-muted px-5 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/80"
          @click="close"
        >
          {{ t('CREATE_ACCOUNT.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton
          type="submit"
          class="h-9 px-5 text-[13px] font-medium shadow-sm"
          :disabled="v$.accountName.$invalid || uiFlags.isCreating"
        >
          {{ t('CREATE_ACCOUNT.FORM.SUBMIT') }}
        </RelayButton>
      </div>
    </form>
  </RelayModal>
</template>
