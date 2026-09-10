<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import { FormKit } from '@formkit/vue';
import { useBranding } from 'shared/composables/useBranding';

import { RelayModal, RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    FormKit,
    RelayButton,
    RelayModal,
  },
  props: {
    integrationId: {
      type: String,
      required: true,
    },
    show: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['close'],
  setup(props) {
    const { integration, isHookTypeInbox } = useIntegrationHook(
      props.integrationId
    );
    const { replaceInstallationName } = useBranding();

    return { integration, isHookTypeInbox, replaceInstallationName };
  },
  data() {
    return {
      endPoint: '',
      alertMessage: '',
      values: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
      dialogFlowEnabledInboxes: 'inboxes/dialogFlowEnabledInboxes',
    }),
    inboxes() {
      return this.dialogFlowEnabledInboxes
        .filter(inbox => {
          if (!this.isIntegrationDialogflow) {
            return true;
          }
          return !this.connectedDialogflowInboxIds.includes(inbox.id);
        })
        .map(inbox => ({ label: inbox.name, value: inbox.id }));
    },

    connectedDialogflowInboxIds() {
      if (!this.isIntegrationDialogflow) {
        return [];
      }
      return this.integration.hooks.map(hook => hook.inbox?.id);
    },
    formItems() {
      return this.integration.settings_form_schema;
    },
    isIntegrationDialogflow() {
      return this.integration.id === 'dialogflow';
    },
    submitButtonLabel() {
      if (this.integration.id === 'openai' && this.uiFlags.isCreatingHook) {
        return this.$t('INTEGRATION_APPS.ADD.FORM.VALIDATING_OPENAI');
      }

      return this.$t('INTEGRATION_APPS.ADD.FORM.SUBMIT');
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    buildHookPayload() {
      const hookPayload = {
        app_id: this.integration.id,
        settings: {},
      };

      hookPayload.settings = Object.keys(this.values).reduce((acc, key) => {
        if (key !== 'inbox') {
          acc[key] = this.values[key];
        }
        return acc;
      }, {});

      this.formItems.forEach(item => {
        if (item.validation?.includes('JSON')) {
          hookPayload.settings[item.name] = JSON.parse(
            hookPayload.settings[item.name]
          );
        }
      });

      if (this.isHookTypeInbox && this.values.inbox) {
        hookPayload.inbox_id = this.values.inbox;
      }

      return hookPayload;
    },
    async submitForm() {
      try {
        await this.$store.dispatch(
          'integrations/createHook',
          this.buildHookPayload()
        );
        this.alertMessage = this.$t('INTEGRATION_APPS.ADD.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.ADD.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="integration.name"
    :description="replaceInstallationName(integration.short_description)"
    flush
    @close="onClose"
  >
    <FormKit
      v-model="values"
      type="form"
      form-class="w-full grid gap-4 px-6 pb-2 integration-hooks"
      :submit-attrs="{
        inputClass: 'hidden',
        wrapperClass: 'hidden',
      }"
      :incomplete-message="false"
      @submit="submitForm"
    >
      <FormKit v-for="item in formItems" :key="item.name" v-bind="item" />
      <FormKit
        v-if="isHookTypeInbox"
        :options="inboxes"
        type="select"
        name="inbox"
        input-class="reset-base"
        :placeholder="$t('INTEGRATION_APPS.ADD.FORM.INBOX.LABEL')"
        :label="$t('INTEGRATION_APPS.ADD.FORM.INBOX.PLACEHOLDER')"
        validation="required"
        validation-name="Inbox"
      />
      <div
        class="-mx-6 mt-2 flex flex-row justify-end gap-3 border-t border-border/40 px-6 py-5"
      >
        <RelayButton
          variant="outline"
          type="reset"
          size="lg"
          @click.prevent="onClose"
        >
          {{ $t('INTEGRATION_APPS.ADD.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton type="submit" size="lg" :disabled="uiFlags.isCreatingHook">
          {{ submitButtonLabel }}
        </RelayButton>
      </div>
    </FormKit>
  </RelayModal>
</template>

<style lang="css">
.formkit-outer {
  @apply mt-2;
}

.formkit-form > .formkit-wrapper > ul.formkit-messages {
  @apply hidden;
}

.formkit-form .formkit-help {
  @apply text-muted-foreground text-sm font-normal mt-2 w-full;
}

/* equivalent of .reset-base */
.formkit-input {
  margin-bottom: 0px !important;
}

[data-invalid] .formkit-message {
  @apply text-destructive block text-xs font-normal my-1 w-full;
}

.formkit-outer[data-type='checkbox'] .formkit-wrapper {
  @apply flex items-center gap-2 px-0.5;
}

.formkit-messages {
  @apply list-none m-0 p-0;
}

.formkit-actions {
  @apply hidden;
}
</style>
