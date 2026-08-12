<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const agentName = ref('');
const agentEmail = ref('');
const selectedRoleId = ref('agent');

const rules = {
  agentName: { required },
  agentEmail: { required, email },
  selectedRoleId: { required },
};

const v$ = useVuelidate(rules, {
  agentName,
  agentEmail,
  selectedRoleId,
});

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');

const roles = computed(() => {
  const defaultRoles = [
    {
      id: 'administrator',
      name: 'administrator',
      label: t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
    },
    {
      id: 'agent',
      name: 'agent',
      label: t('AGENT_MGMT.AGENT_TYPES.AGENT'),
    },
  ];

  const customRoles = getCustomRoles.value.map(role => ({
    id: role.id,
    name: `custom_${role.id}`,
    label: role.name,
  }));

  return [...defaultRoles, ...customRoles];
});

const selectedRole = computed(() =>
  roles.value.find(
    role =>
      role.id === selectedRoleId.value || role.name === selectedRoleId.value
  )
);

const selectClass =
  'flex h-10 w-full appearance-none rounded-md border border-border/80 bg-background px-4 text-[14px] text-foreground shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';

const addAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const payload = {
      name: agentName.value,
      email: agentEmail.value,
    };

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
    }

    await store.dispatch('agents/create', payload);
    useAlert(t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    const {
      response: {
        data: {
          error: errorResponse = '',
          attributes: attributes = [],
          message: attrError = '',
        } = {},
      } = {},
    } = error;

    let errorMessage = '';
    if (error?.response?.status === 422 && !attributes.includes('base')) {
      errorMessage = t('AGENT_MGMT.ADD.API.EXIST_MESSAGE');
    } else {
      errorMessage = t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
    }
    useAlert(errorResponse || attrError || errorMessage);
  }
};
</script>

<template>
  <form @submit.prevent="addAgent">
    <div class="space-y-5 px-7 pb-2">
      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="add-agent-name"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ $t('AGENT_MGMT.ADD.FORM.NAME.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="add-agent-name"
          v-model="agentName"
          type="text"
          :placeholder="$t('AGENT_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.agentName.$touch"
        />
        <p v-if="v$.agentName.$error" class="text-xs text-destructive">
          {{ $t('AGENT_MGMT.ADD.FORM.NAME.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="add-agent-role"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
        </RelayLabel>
        <div class="relative">
          <select
            id="add-agent-role"
            v-model="selectedRoleId"
            :class="selectClass"
            @change="v$.selectedRoleId.$touch"
          >
            <option v-for="role in roles" :key="role.id" :value="role.id">
              {{ role.label }}
            </option>
          </select>
          <Icon
            icon="i-lucide-chevron-down"
            class="pointer-events-none absolute top-1/2 size-4 -translate-y-1/2 text-muted-foreground/60 ltr:right-3 rtl:left-3"
          />
        </div>
        <p v-if="v$.selectedRoleId.$error" class="text-xs text-destructive">
          {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="add-agent-email"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="add-agent-email"
          v-model="agentEmail"
          type="email"
          :placeholder="$t('AGENT_MGMT.ADD.FORM.EMAIL.PLACEHOLDER')"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.agentEmail.$touch"
        />
        <p v-if="v$.agentEmail.$error" class="text-xs text-destructive">
          {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.ERROR') }}
        </p>
      </div>
    </div>

    <div class="flex justify-end gap-3 border-t border-border/40 px-7 py-6">
      <RelayButton
        type="button"
        variant="outline"
        class="h-9 border-border bg-muted px-5 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/80"
        @click="emit('close')"
      >
        {{ $t('AGENT_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
      </RelayButton>
      <RelayButton
        type="submit"
        class="h-9 px-5 text-[13px] font-medium shadow-sm"
        :disabled="v$.$invalid || uiFlags.isCreating"
      >
        {{ $t('AGENT_MGMT.ADD.FORM.SUBMIT') }}
      </RelayButton>
    </div>
  </form>
</template>
