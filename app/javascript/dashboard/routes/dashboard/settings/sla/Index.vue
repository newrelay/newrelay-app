<script>
import AddSLA from './AddSLA.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import SLAPaywallEnterprise from './SLAPaywallEnterprise.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayBadge,
  RelayModal,
  RelayConfirmModal,
} from 'dashboard/components-next/relay';

import { mapGetters } from 'vuex';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';

export default {
  components: {
    AddSLA,
    SettingsLayout,
    BaseSettingsHeader,
    SLAPaywallEnterprise,
    Icon,
    RelayButton,
    RelayBadge,
    RelayModal,
    RelayConfirmModal,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      searchQuery: '',
    };
  },
  computed: {
    ...mapGetters({
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      records: 'sla/getSLA',
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
      uiFlags: 'sla/getUIFlags',
    }),
    deleteConfirmText() {
      return this.$t('SLA.DELETE.CONFIRM.YES');
    },
    deleteRejectText() {
      return this.$t('SLA.DELETE.CONFIRM.NO');
    },
    deleteMessage() {
      return ` ${this.selectedResponse.name}`;
    },
    isBehindAPaywall() {
      return !this.isFeatureEnabledonAccount(this.accountId, 'sla');
    },
    isSuperAdmin() {
      return this.currentUser.type === 'SuperAdmin';
    },
    filteredRecords() {
      const query = this.searchQuery.trim();
      if (!query) return this.records;
      return picoSearch(this.records, query, ['name', 'description']);
    },
    emptyTableMessage() {
      if (!this.records.length) {
        return this.$t('SLA.LIST.404');
      }
      if (this.searchQuery && !this.filteredRecords.length) {
        return this.$t('SLA.SEARCH.NO_RESULTS');
      }
      return '';
    },
  },
  mounted() {
    this.$store.dispatch('sla/get');
  },
  methods: {
    openAddPopup() {
      if (this.isBehindAPaywall) {
        return;
      }
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteSla(this.selectedResponse.id);
    },
    deleteSla(id) {
      this.$store
        .dispatch('sla/delete', id)
        .then(() => {
          useAlert(this.$t('SLA.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          useAlert(this.$t('SLA.DELETE.API.ERROR_MESSAGE'));
        })
        .finally(() => {
          this.loading[this.selectedResponse.id] = false;
        });
    },
    displayTime(threshold) {
      const { time, unit } = convertSecondsToTimeUnit(threshold, {
        minute: 'm',
        hour: 'h',
        day: 'd',
      });
      if (!time) return '-';
      return `${time}${unit}`;
    },
    onClickCTA() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
  },
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('SLA.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('SLA.HEADER')"
        :description="$t('SLA.DESCRIPTION')"
        :link-text="$t('SLA.LEARN_MORE')"
        :search-placeholder="
          isBehindAPaywall ? '' : $t('SLA.SEARCH_PLACEHOLDER')
        "
        feature-name="sla"
      >
        <template v-if="!isBehindAPaywall && records?.length" #count>
          <span class="text-sm text-muted-foreground">
            {{ $t('SLA.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template v-if="!isBehindAPaywall" #actions>
          <RelayButton size="sm" @click="openAddPopup">
            {{ $t('SLA.ADD_ACTION') }}
          </RelayButton>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <SLAPaywallEnterprise
        v-if="isBehindAPaywall"
        :is-super-admin="isSuperAdmin"
        :is-on-chatwoot-cloud="isOnChatwootCloud"
        @upgrade="onClickCTA"
      />
      <div
        v-else
        class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div v-if="emptyTableMessage" class="py-20">
          <p class="text-center text-sm text-muted-foreground">
            {{ emptyTableMessage }}
          </p>
        </div>
        <div v-else class="overflow-x-auto">
          <table class="w-full border-collapse text-left">
            <thead>
              <tr class="border-b border-border/40 bg-background">
                <th
                  class="px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('SLA.LIST.TABLE_HEADER.SLA') }}
                </th>
                <th
                  class="w-40 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('SLA.LIST.TABLE_HEADER.BUSINESS_HOURS') }}
                </th>
                <th
                  class="w-24 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span>
                      {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.FRT') }}
                    </span>
                    <Icon
                      v-tooltip.left="$t('SLA.LIST.RESPONSE_TYPES.FRT')"
                      icon="i-lucide-info"
                      class="size-3.5 cursor-help text-muted-foreground"
                    />
                  </div>
                </th>
                <th
                  class="w-24 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span>
                      {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.NRT') }}
                    </span>
                    <Icon
                      v-tooltip.left="$t('SLA.LIST.RESPONSE_TYPES.NRT')"
                      icon="i-lucide-info"
                      class="size-3.5 cursor-help text-muted-foreground"
                    />
                  </div>
                </th>
                <th
                  class="w-24 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span>
                      {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.RT') }}
                    </span>
                    <Icon
                      v-tooltip.left="$t('SLA.LIST.RESPONSE_TYPES.RT')"
                      icon="i-lucide-info"
                      class="size-3.5 cursor-help text-muted-foreground"
                    />
                  </div>
                </th>
                <th
                  class="w-32 px-6 py-3.5 text-[13px] font-medium text-muted-foreground"
                >
                  {{ $t('INTEGRATION_APPS.LIST.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border/40">
              <tr
                v-for="sla in filteredRecords"
                :key="sla.id"
                class="bg-card transition-colors hover:bg-muted/10"
              >
                <td class="px-6 py-4">
                  <div class="flex min-w-0 flex-col gap-1">
                    <span
                      class="truncate text-[14px] font-medium text-foreground"
                    >
                      {{ sla.name }}
                    </span>
                    <span
                      class="line-clamp-1 text-[13px] text-muted-foreground"
                    >
                      {{ sla.description }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <RelayBadge
                    variant="outline"
                    class="inline-flex items-center gap-1.5 border-border bg-muted/30 text-foreground"
                    :class="
                      sla.only_during_business_hours
                        ? 'border-primary/20 bg-primary/10 text-primary'
                        : ''
                    "
                  >
                    <Icon
                      :icon="
                        sla.only_during_business_hours
                          ? 'i-lucide-alarm-clock-check'
                          : 'i-lucide-alarm-clock-off'
                      "
                      class="size-3.5"
                    />
                    {{
                      sla.only_during_business_hours
                        ? $t('SLA.LIST.BUSINESS_HOURS_ON')
                        : $t('SLA.LIST.BUSINESS_HOURS_OFF')
                    }}
                  </RelayBadge>
                </td>
                <td class="px-6 py-4 text-[14px] text-foreground">
                  {{ displayTime(sla.first_response_time_threshold) }}
                </td>
                <td class="px-6 py-4 text-[14px] text-foreground">
                  {{ displayTime(sla.next_response_time_threshold) }}
                </td>
                <td class="px-6 py-4 text-[14px] text-foreground">
                  {{ displayTime(sla.resolution_time_threshold) }}
                </td>
                <td class="px-6 py-4">
                  <div
                    class="flex items-center justify-end gap-1.5 opacity-60 transition-opacity hover:opacity-100"
                  >
                    <RelayButton
                      v-tooltip.top="$t('SLA.FORM.DELETE')"
                      variant="ghost"
                      size="icon"
                      class="size-7 border border-transparent text-muted-foreground hover:border-border hover:bg-muted/50 hover:text-destructive"
                      :disabled="loading[sla.id]"
                      @click="openDeletePopup(sla)"
                    >
                      <Icon icon="i-lucide-trash-2" class="size-3.5" />
                    </RelayButton>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <RelayModal
        :show="showAddPopup"
        :title="$t('SLA.ADD.TITLE')"
        :description="$t('SLA.ADD.DESC')"
        size="lg"
        @close="hideAddPopup"
      >
        <AddSLA @close="hideAddPopup" />
      </RelayModal>

      <RelayConfirmModal
        :show="showDeleteConfirmationPopup"
        :title="$t('SLA.DELETE.CONFIRM.TITLE')"
        :message="$t('SLA.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="deleteConfirmText"
        :cancel-text="deleteRejectText"
        @close="closeDeletePopup"
        @confirm="confirmDeletion"
      />
    </template>
  </SettingsLayout>
</template>
