<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AgentCapacityPolicyForm from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/AgentCapacityPolicyForm.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const formRef = ref(null);
const uiFlags = useMapGetter('agentCapacityPolicies/getUIFlags');
const labelsList = useMapGetter('labels/getLabels');

const allLabels = computed(() =>
  labelsList.value?.map(({ title, color, id }) => ({
    id,
    name: title,
    color,
  }))
);

const breadcrumbItems = computed(() => [
  {
    label: t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.HEADER.TITLE'),
    routeName: 'agent_capacity_policy_index',
  },
  {
    label: t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.HEADER.TITLE'),
  },
]);

const handleBreadcrumbClick = item => {
  router.push({
    name: item.routeName,
  });
};

const handleCancel = () => {
  router.push({ name: 'agent_capacity_policy_index' });
};

const handleSubmit = async formState => {
  try {
    const policy = await store.dispatch(
      'agentCapacityPolicies/create',
      formState
    );
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.API.SUCCESS_MESSAGE')
    );
    formRef.value?.resetForm();

    router.push({
      name: 'agent_capacity_policy_edit',
      params: {
        id: policy.id,
      },
    });
  } catch (error) {
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.API.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <SettingsLayout class="w-full max-w-3xl ltr:mr-auto rtl:ml-auto">
    <template #header>
      <div class="mb-4 flex min-h-10 w-full items-center justify-between gap-2">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
      </div>
    </template>

    <template #body>
      <div
        class="mx-auto mt-2 flex w-full max-w-3xl flex-col overflow-hidden rounded-xl border border-border/60 bg-card shadow-sm"
      >
        <div
          class="flex items-center justify-between border-b border-border/40 bg-background/50 p-5"
        >
          <h3 class="text-[16px] font-semibold text-foreground">
            {{
              $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.HEADER.TITLE')
            }}
          </h3>
          <button
            type="button"
            class="text-muted-foreground transition-colors hover:text-foreground"
            :aria-label="
              $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.CANCEL_BUTTON')
            "
            @click="handleCancel"
          >
            <Icon icon="i-lucide-x" class="size-5" />
          </button>
        </div>
        <AgentCapacityPolicyForm
          ref="formRef"
          mode="CREATE"
          :is-loading="uiFlags.isCreating"
          :label-list="allLabels"
          @submit="handleSubmit"
          @cancel="handleCancel"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
