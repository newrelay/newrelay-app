<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import ConfirmDeletePolicyDialog from './components/ConfirmDeletePolicyDialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const store = useStore();
const { t } = useI18n();
const router = useRouter();

const agentCapacityPolicies = useMapGetter(
  'agentCapacityPolicies/getAgentCapacityPolicies'
);
const uiFlags = useMapGetter('agentCapacityPolicies/getUIFlags');
const confirmDeletePolicyDialogRef = ref(null);

const policies = computed(() => agentCapacityPolicies.value || []);

const onClickCreatePolicy = () => {
  router.push({ name: 'agent_capacity_policy_create' });
};

const onClickEditPolicy = id => {
  router.push({
    name: 'agent_capacity_policy_edit',
    params: { id },
  });
};

const handleDelete = id => {
  confirmDeletePolicyDialogRef.value.openDialog(id);
};

const handleDeletePolicy = async policyId => {
  try {
    await store.dispatch('agentCapacityPolicies/delete', policyId);
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.DELETE_POLICY.SUCCESS_MESSAGE')
    );
    confirmDeletePolicyDialogRef.value.closeDialog();
  } catch (error) {
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.DELETE_POLICY.ERROR_MESSAGE')
    );
  }
};

onMounted(() => {
  store.dispatch('agentCapacityPolicies/get');
});
</script>

<template>
  <div>
    <div class="mb-6 flex items-center justify-between gap-3">
      <h3 class="text-[15px] font-medium text-foreground">
        {{
          $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.CAPACITY_LIMITS')
        }}
      </h3>
      <RelayButton class="h-9 shadow-sm" @click="onClickCreatePolicy">
        <Icon icon="i-lucide-plus" class="size-4" />
        {{
          $t(
            'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.HEADER.CREATE_POLICY'
          )
        }}
      </RelayButton>
    </div>

    <woot-loading-state
      v-if="uiFlags.isFetching"
      :message="$t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.LOADING')"
    />

    <div
      v-else-if="!policies.length"
      class="flex flex-col items-center justify-center rounded-xl border border-dashed border-border/60 bg-card/30 p-16 text-center shadow-xs"
    >
      <div
        class="mb-5 flex size-16 items-center justify-center rounded-full bg-emerald-500/10"
      >
        <Icon icon="i-lucide-shield-alert" class="size-7 text-emerald-600" />
      </div>
      <h3 class="mb-2 text-[16px] font-semibold text-foreground">
        {{ $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.EMPTY_TITLE') }}
      </h3>
      <p
        class="mx-auto mb-6 max-w-md text-[14px] leading-relaxed text-muted-foreground"
      >
        {{ $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.EMPTY_DESC') }}
      </p>
      <RelayButton class="h-9 shadow-sm" @click="onClickCreatePolicy">
        {{ $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.SET_UP_LIMITS') }}
      </RelayButton>
    </div>

    <div v-else class="grid grid-cols-1 gap-4 lg:grid-cols-2">
      <div
        v-for="policy in policies"
        :key="policy.id"
        class="group relative overflow-hidden rounded-xl border border-border/60 bg-card p-5 shadow-xs transition-all hover:border-emerald-500/30"
      >
        <div class="absolute left-0 top-0 h-full w-1 bg-emerald-500" />
        <div class="mb-4 flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h4 class="text-[15px] font-semibold text-foreground">
              {{ policy.name }}
            </h4>
            <p class="mt-1 text-[13px] text-muted-foreground">
              {{
                policy.description ||
                $t(
                  'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.NO_DESCRIPTION'
                )
              }}
            </p>
          </div>
          <div
            class="flex items-center gap-1 opacity-0 transition-all group-hover:opacity-100"
          >
            <RelayButton
              v-tooltip.top="
                $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.CARD.EDIT')
              "
              variant="outline"
              size="icon"
              class="size-8 border-border/60 bg-background p-0 text-muted-foreground shadow-none hover:bg-muted/50 hover:text-foreground"
              @click="onClickEditPolicy(policy.id)"
            >
              <Icon icon="i-lucide-pencil" class="size-3.5" />
            </RelayButton>
            <RelayButton
              v-tooltip.top="
                $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.CARD.DELETE')
              "
              variant="outline"
              size="icon"
              class="size-8 border-border/60 bg-background p-0 text-muted-foreground shadow-none hover:bg-destructive/10 hover:text-destructive"
              @click="handleDelete(policy.id)"
            >
              <Icon icon="i-lucide-trash-2" class="size-3.5" />
            </RelayButton>
          </div>
        </div>

        <div class="mt-5 border-t border-border/40 pt-4">
          <span
            class="mb-2 block text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
          >
            {{
              $t(
                'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.AGENTS_ASSIGNED'
              )
            }}
          </span>
          <p class="text-[13px] text-muted-foreground">
            <template v-if="policy.assignedAgentCount">
              {{
                $t(
                  'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.AGENTS_COUNT',
                  { n: policy.assignedAgentCount }
                )
              }}
            </template>
            <template v-else>
              {{
                $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.AGENTS_NONE')
              }}
            </template>
          </p>
        </div>
      </div>
    </div>

    <ConfirmDeletePolicyDialog
      ref="confirmDeletePolicyDialogRef"
      @delete="handleDeletePolicy"
    />
  </div>
</template>
