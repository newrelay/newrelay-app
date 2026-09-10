<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RELAY_MODAL_FORM_FOOTER_CLASS,
  RELAY_MODAL_INPUT_CLASS,
} from 'dashboard/components-next/relay';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const emit = defineEmits(['close', 'success']);

const { t } = useI18n();

const COMPANY_SIZE_OPTIONS = [
  { value: '1-10', label: '1-10 employees' },
  { value: '11-50', label: '11-50 employees' },
  { value: '51-200', label: '51-200 employees' },
  { value: '201-500', label: '201-500 employees' },
  { value: '500+', label: '500+ employees' },
];

const FEATURE_OPTIONS = [
  { value: 'sla', label: 'SLA Policies' },
  { value: 'custom_roles', label: 'Custom Roles & Permissions' },
  { value: 'saml', label: 'SAML SSO' },
  { value: 'audit_logs', label: 'Audit Logs' },
  { value: 'disable_branding', label: 'Remove newrelay Branding' },
  { value: 'white_labeling', label: 'White Labeling' },
  { value: 'custom_domain', label: 'Custom Domain' },
  { value: 'api_access', label: 'API Access' },
  { value: 'advanced_search', label: 'Advanced Search' },
  { value: 'captain_integration', label: 'Relay AI' },
  { value: 'custom_tools', label: 'Relay AI Custom Tools' },
  { value: 'reseller_dashboard', label: 'Reseller Dashboard' },
];

const dialogRef = ref(null);
const isLoading = ref(false);

const companySize = ref('');
const teamSize = ref('');
const desiredFeatures = ref([]);
const message = ref('');

const resetForm = () => {
  companySize.value = '';
  teamSize.value = '';
  desiredFeatures.value = [];
  message.value = '';
};

const open = () => {
  resetForm();
  isLoading.value = false;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleClose = () => {
  emit('close');
};

const handleSubmit = async () => {
  isLoading.value = true;
  try {
    const response = await EnterpriseAccountAPI.submitEnterpriseInquiry({
      company_size: companySize.value,
      team_size: teamSize.value,
      desired_features: desiredFeatures.value,
      message: message.value,
    });

    close();
    emit('success');
    useAlert(
      response.data.message || t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.SUCCESS')
    );
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.ERROR')
    );
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.TITLE')"
    :description="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.DESCRIPTION')"
    width="lg"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.COMPANY_SIZE.LABEL') }}
        </RelayLabel>
        <Select
          v-model="companySize"
          class="w-full"
          :placeholder="
            $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.COMPANY_SIZE.PLACEHOLDER')
          "
          :options="COMPANY_SIZE_OPTIONS"
        />
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.TEAM_SIZE.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="teamSize"
          type="number"
          min="1"
          :placeholder="
            $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.TEAM_SIZE.PLACEHOLDER')
          "
          :class-name="RELAY_MODAL_INPUT_CLASS"
        />
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.FEATURES.LABEL') }}
        </RelayLabel>
        <TagMultiSelectComboBox
          v-model="desiredFeatures"
          :options="FEATURE_OPTIONS"
          :placeholder="
            $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.FEATURES.PLACEHOLDER')
          "
        />
      </div>

      <TextArea
        v-model="message"
        :label="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.MESSAGE.LABEL')"
        :placeholder="
          $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.MESSAGE.PLACEHOLDER')
        "
      />
    </div>

    <template #footer>
      <div :class="RELAY_MODAL_FORM_FOOTER_CLASS">
        <RelayButton
          type="button"
          variant="outline"
          size="lg"
          :disabled="isLoading"
          @click="close"
        >
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.CANCEL') }}
        </RelayButton>
        <RelayButton
          type="button"
          size="lg"
          :disabled="isLoading"
          @click="handleSubmit"
        >
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.SUBMIT') }}
        </RelayButton>
      </div>
    </template>
  </Dialog>
</template>
