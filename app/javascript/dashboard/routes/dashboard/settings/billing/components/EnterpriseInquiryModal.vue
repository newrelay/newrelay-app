<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
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
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.COMPANY_SIZE.LABEL') }}
        </label>
        <Select
          v-model="companySize"
          class="w-full"
          :placeholder="
            $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.COMPANY_SIZE.PLACEHOLDER')
          "
          :options="COMPANY_SIZE_OPTIONS"
        />
      </div>

      <Input
        v-model="teamSize"
        type="number"
        min="1"
        :label="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.TEAM_SIZE.LABEL')"
        :placeholder="
          $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.TEAM_SIZE.PLACEHOLDER')
        "
      />

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.FEATURES.LABEL') }}
        </label>
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
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.CANCEL')"
          class="w-full"
          type="button"
          :disabled="isLoading"
          @click="close"
        />
        <Button
          color="blue"
          :label="$t('BILLING_SETTINGS.ENTERPRISE_INQUIRY.SUBMIT')"
          class="w-full"
          :is-loading="isLoading"
          @click="handleSubmit"
        />
      </div>
    </template>
  </Dialog>
</template>
