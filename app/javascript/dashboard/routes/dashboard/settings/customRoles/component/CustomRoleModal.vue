<script setup>
import { ref, reactive, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import {
  AVAILABLE_CUSTOM_ROLE_PERMISSIONS,
  MANAGE_ALL_CONVERSATION_PERMISSIONS,
  CONVERSATION_UNASSIGNED_PERMISSIONS,
  CONVERSATION_PARTICIPATING_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelayCheckbox,
  RelayModal,
} from 'dashboard/components-next/relay';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  mode: {
    type: String,
    default: 'add',
    validator: value => ['add', 'edit'].includes(value),
  },
  selectedRole: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const name = ref('');
const description = ref('');
const selectedPermissions = ref([]);

const addCustomRole = reactive({
  showLoading: false,
  message: '',
});

const rules = computed(() => ({
  name: { required, minLength: minLength(2) },
  description: { required },
  selectedPermissions: { required, minLength: minLength(1) },
}));

const v$ = useVuelidate(rules, { name, description, selectedPermissions });

const resetForm = () => {
  name.value = '';
  description.value = '';
  selectedPermissions.value = [];
  v$.value.$reset();
};

const populateEditForm = () => {
  name.value = props.selectedRole.name || '';
  description.value = props.selectedRole.description || '';
  selectedPermissions.value = props.selectedRole.permissions || [];
};

watch(
  selectedPermissions,
  (newValue, oldValue) => {
    const hasAddedManageAllConversation =
      newValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS) &&
      !oldValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS);
    const hasRemovedManageAllConversation =
      oldValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS) &&
      !newValue.includes(MANAGE_ALL_CONVERSATION_PERMISSIONS);

    if (hasAddedManageAllConversation) {
      selectedPermissions.value = [
        ...new Set([
          ...selectedPermissions.value,
          CONVERSATION_UNASSIGNED_PERMISSIONS,
          CONVERSATION_PARTICIPATING_PERMISSIONS,
        ]),
      ];
    } else if (hasRemovedManageAllConversation) {
      selectedPermissions.value = selectedPermissions.value.filter(
        p => p !== MANAGE_ALL_CONVERSATION_PERMISSIONS
      );
    }
  },
  { deep: true }
);

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      if (props.mode === 'edit') {
        populateEditForm();
      } else {
        resetForm();
      }
    }
  }
);

const getTranslationKey = base => {
  return props.mode === 'edit'
    ? `CUSTOM_ROLE.EDIT.${base}`
    : `CUSTOM_ROLE.ADD.${base}`;
};

const modalTitle = computed(() => t(getTranslationKey('TITLE')));
const modalDescription = computed(() => t(getTranslationKey('DESC')));
const submitButtonText = computed(() => t(getTranslationKey('SUBMIT')));

const isPermissionChecked = permission =>
  selectedPermissions.value.includes(permission);

const setPermission = (permission, checked) => {
  if (checked) {
    if (!selectedPermissions.value.includes(permission)) {
      selectedPermissions.value = [...selectedPermissions.value, permission];
    }
  } else {
    selectedPermissions.value = selectedPermissions.value.filter(
      p => p !== permission
    );
  }
  v$.value.selectedPermissions.$touch();
};

const handleCustomRole = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  addCustomRole.showLoading = true;
  try {
    const roleData = {
      name: name.value,
      description: description.value,
      permissions: selectedPermissions.value,
    };

    if (props.mode === 'edit') {
      await store.dispatch('customRole/updateCustomRole', {
        id: props.selectedRole.id,
        ...roleData,
      });
      useAlert(t('CUSTOM_ROLE.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('customRole/createCustomRole', roleData);
      useAlert(t('CUSTOM_ROLE.ADD.API.SUCCESS_MESSAGE'));
    }

    resetForm();
    emit('close');
  } catch (error) {
    const errorMessage =
      error?.message || t(`CUSTOM_ROLE.FORM.API.ERROR_MESSAGE`);
    useAlert(errorMessage);
  } finally {
    addCustomRole.showLoading = false;
  }
};

const isSubmitDisabled = computed(
  () => v$.value.$invalid || addCustomRole.showLoading
);
</script>

<template>
  <RelayModal
    :show="show"
    :title="modalTitle"
    :description="modalDescription"
    size="lg"
    @close="emit('close')"
  >
    <form @submit.prevent="handleCustomRole">
      <div class="space-y-5 px-7 pb-2">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="custom-role-name"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('CUSTOM_ROLE.FORM.NAME.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="custom-role-name"
            v-model="name"
            type="text"
            :placeholder="$t('CUSTOM_ROLE.FORM.NAME.PLACEHOLDER')"
            class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            @blur="v$.name.$touch"
          />
          <p v-if="v$.name.$error" class="text-xs text-destructive">
            {{ $t('CUSTOM_ROLE.FORM.NAME.ERROR') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="custom-role-description"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ $t('CUSTOM_ROLE.FORM.DESCRIPTION.LABEL') }}
          </RelayLabel>
          <textarea
            id="custom-role-description"
            v-model="description"
            rows="3"
            :placeholder="$t('CUSTOM_ROLE.FORM.DESCRIPTION.PLACEHOLDER')"
            class="min-h-[90px] w-full resize-none rounded-md border border-border/80 bg-background p-3 text-[14px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
            @blur="v$.description.$touch"
          />
          <p v-if="v$.description.$error" class="text-xs text-destructive">
            {{ $t('CUSTOM_ROLE.FORM.DESCRIPTION.ERROR') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5 pt-2">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ $t('CUSTOM_ROLE.FORM.PERMISSIONS.LABEL') }}
          </RelayLabel>
          <div class="space-y-3">
            <label
              v-for="permission in AVAILABLE_CUSTOM_ROLE_PERMISSIONS"
              :key="permission"
              class="flex cursor-pointer items-center gap-3"
            >
              <RelayCheckbox
                :model-value="isPermissionChecked(permission)"
                @update:model-value="
                  checked => setPermission(permission, checked)
                "
              />
              <span class="text-[13px] font-normal text-foreground">
                {{ $t(`CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`) }}
              </span>
            </label>
          </div>
          <p
            v-if="v$.selectedPermissions.$error"
            class="text-xs text-destructive"
          >
            {{ $t('CUSTOM_ROLE.FORM.PERMISSIONS.ERROR') }}
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
          {{ $t('CUSTOM_ROLE.FORM.CANCEL_BUTTON_TEXT') }}
        </RelayButton>
        <RelayButton
          type="submit"
          class="h-9 px-5 text-[13px] font-medium shadow-sm"
          :disabled="isSubmitDisabled"
        >
          {{ submitButtonText }}
        </RelayButton>
      </div>
    </form>
  </RelayModal>
</template>
