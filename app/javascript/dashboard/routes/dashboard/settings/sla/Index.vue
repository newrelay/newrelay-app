<script>
import AddSLA from './AddSLA.vue';
import SettingsLayout from '../SettingsLayout.vue';
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
    <template #body>
      <SLAPaywallEnterprise
        v-if="isBehindAPaywall"
        :is-super-admin="isSuperAdmin"
        :is-on-chatwoot-cloud="isOnChatwootCloud"
        @upgrade="onClickCTA"
      />
      <div
        v-else
        class="mb-8 overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <!-- Header -->
        <div class="border-b border-border/40 p-4 sm:p-6">
          <h3 class="text-base font-semibold text-foreground">
            {{ $t('SLA.HEADER') }}
          </h3>
          <p class="mt-1 max-w-4xl text-sm text-muted-foreground">
            {{ $t('SLA.DESCRIPTION') }}
          </p>
        </div>

        <div class="space-y-6 p-4 sm:p-6">
          <!-- Toolbar -->
          <div
            class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
          >
            <div class="relative w-full max-w-md">
              <Icon
                icon="i-lucide-search"
                class="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <input
                v-model="searchQuery"
                type="text"
                :placeholder="$t('SLA.SEARCH_PLACEHOLDER')"
                class="h-10 w-full rounded-lg border border-border/60 bg-muted/20 pl-9 text-sm text-foreground outline-none placeholder:text-muted-foreground focus:ring-1 focus:ring-primary/20"
              />
            </div>
            <RelayButton
              size="sm"
              class="h-10 whitespace-nowrap px-5"
              @click="openAddPopup"
            >
              {{ $t('SLA.ADD_ACTION') }}
            </RelayButton>
          </div>

          <!-- Empty state -->
          <div v-if="emptyTableMessage" class="py-20">
            <p class="text-center text-sm text-muted-foreground">
              {{ emptyTableMessage }}
            </p>
          </div>

          <!-- List -->
          <div v-else class="min-w-full">
            <!-- Header row -->
            <div
              class="grid grid-cols-[1.5fr_1fr_0.7fr_0.7fr_0.7fr_100px] items-center border-b border-border/40 px-4 py-3"
            >
              <div class="text-[12px] font-semibold text-muted-foreground">
                {{ $t('SLA.LIST.TABLE_HEADER.SLA') }}
              </div>
              <div class="text-[12px] font-semibold text-muted-foreground">
                {{ $t('SLA.LIST.TABLE_HEADER.BUSINESS_HOURS') }}
              </div>
              <div
                class="flex items-center gap-1 text-[12px] font-semibold text-muted-foreground"
              >
                {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.FRT') }}
                <Icon
                  v-tooltip.top="$t('SLA.LIST.RESPONSE_TYPES.FRT')"
                  icon="i-lucide-info"
                  class="size-3.5 cursor-help"
                />
              </div>
              <div
                class="flex items-center gap-1 text-[12px] font-semibold text-muted-foreground"
              >
                {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.NRT') }}
                <Icon
                  v-tooltip.top="$t('SLA.LIST.RESPONSE_TYPES.NRT')"
                  icon="i-lucide-info"
                  class="size-3.5 cursor-help"
                />
              </div>
              <div
                class="flex items-center gap-1 text-[12px] font-semibold text-muted-foreground"
              >
                {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.RT') }}
                <Icon
                  v-tooltip.top="$t('SLA.LIST.RESPONSE_TYPES.RT')"
                  icon="i-lucide-info"
                  class="size-3.5 cursor-help"
                />
              </div>
              <div
                class="text-right text-[12px] font-semibold text-muted-foreground"
              >
                {{ $t('INTEGRATION_APPS.LIST.ACTIONS') }}
              </div>
            </div>

            <!-- Body rows -->
            <div class="divide-y divide-border/40">
              <div
                v-for="sla in filteredRecords"
                :key="sla.id"
                class="group grid grid-cols-[1.5fr_1fr_0.7fr_0.7fr_0.7fr_100px] items-center px-4 py-4 transition-colors hover:bg-muted/10"
              >
                <div class="min-w-0 pr-4">
                  <p class="truncate text-[14px] font-medium text-foreground">
                    {{ sla.name }}
                  </p>
                  <p class="line-clamp-1 text-[13px] text-muted-foreground">
                    {{ sla.description }}
                  </p>
                </div>
                <div>
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
                </div>
                <div class="text-[14px] text-foreground">
                  {{ displayTime(sla.first_response_time_threshold) }}
                </div>
                <div class="text-[14px] text-foreground">
                  {{ displayTime(sla.next_response_time_threshold) }}
                </div>
                <div class="text-[14px] text-foreground">
                  {{ displayTime(sla.resolution_time_threshold) }}
                </div>
                <div
                  class="flex items-center justify-end opacity-0 transition-opacity group-hover:opacity-100"
                >
                  <RelayButton
                    v-tooltip.top="$t('SLA.FORM.DELETE')"
                    variant="ghost"
                    size="icon"
                    class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-destructive/20 hover:bg-destructive/10 hover:text-destructive"
                    :disabled="loading[sla.id]"
                    @click="openDeletePopup(sla)"
                  >
                    <Icon icon="i-lucide-trash-2" class="size-3.5" />
                  </RelayButton>
                </div>
              </div>
            </div>
          </div>
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
