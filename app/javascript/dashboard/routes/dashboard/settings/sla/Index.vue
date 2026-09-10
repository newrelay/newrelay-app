<script>
import { RelayTooltip } from 'dashboard/components-next/relay';
import AddSLA from './AddSLA.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SLAPaywallEnterprise from './SLAPaywallEnterprise.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayBadge,
  RelayInput,
  RelayModal,
  RelayConfirmModal,
} from 'dashboard/components-next/relay';

import { mapGetters } from 'vuex';
import { convertSecondsToTimeUnit } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';

export default {
  components: {
    RelayTooltip,
    AddSLA,
    SettingsLayout,
    SLAPaywallEnterprise,
    Icon,
    RelayButton,
    RelayBadge,
    RelayInput,
    RelayModal,
    RelayConfirmModal,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      slaToEdit: null,
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
      this.slaToEdit = null;
      this.showAddPopup = true;
    },
    openEditPopup(sla) {
      this.slaToEdit = sla;
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
      this.slaToEdit = null;
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
      <div v-else class="flex-1 w-full max-w-4xl min-w-0">
        <div class="max-w-3xl space-y-8">
          <div class="h-full">
            <div class="h-full animate-in fade-in duration-300">
              <div
                class="border border-border/60 bg-card rounded-xl shadow-xs overflow-hidden mb-8"
              >
                <!-- Header -->
                <div class="p-4 sm:p-6 border-b border-border/40">
                  <h3 class="text-base font-semibold text-foreground">
                    {{ $t('SLA.HEADER') }}
                  </h3>
                  <p class="text-sm text-muted-foreground mt-1 max-w-4xl">
                    {{ $t('SLA.DESCRIPTION') }}
                  </p>
                </div>

                <div class="p-4 sm:p-6 space-y-6">
                  <div
                    class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mt-8"
                  >
                    <div class="relative w-full max-w-md">
                      <Icon
                        icon="i-lucide-search"
                        class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                      />
                      <RelayInput
                        v-model="searchQuery"
                        type="search"
                        :placeholder="$t('SLA.SEARCH_PLACEHOLDER')"
                        class-name="pl-9 h-10 text-[14px] bg-muted/20 border-border/60 shadow-none focus-visible:ring-1 focus-visible:ring-primary/20"
                      />
                    </div>
                    <RelayButton
                      class="h-10 px-5 text-[13px] font-medium shadow-sm rounded-lg whitespace-nowrap"
                      @click="openAddPopup"
                    >
                      {{ $t('SLA.ADD_ACTION') }}
                    </RelayButton>
                  </div>

                  <!-- Content Area -->
                  <div class="mt-8">
                    <!-- Empty State -->
                    <div
                      v-if="emptyTableMessage"
                      class="py-20 flex flex-col items-center justify-center text-center"
                    >
                      <p class="text-[14px] text-muted-foreground font-medium">
                        {{ emptyTableMessage }}
                      </p>
                    </div>

                    <!-- SLA List Table -->
                    <div v-else class="min-w-full overflow-x-auto">
                      <!-- Header row -->
                      <div
                        class="grid grid-cols-[1.5fr_1fr_0.7fr_0.7fr_0.7fr_100px] items-center border-b border-border/40 px-4 py-3 bg-muted/20"
                      >
                        <div
                          class="text-[14px] font-medium text-muted-foreground"
                        >
                          {{ $t('SLA.LIST.TABLE_HEADER.SLA') }}
                        </div>
                        <div
                          class="text-[14px] font-medium text-muted-foreground"
                        >
                          {{ $t('SLA.LIST.TABLE_HEADER.BUSINESS_HOURS') }}
                        </div>
                        <div
                          class="flex items-center gap-1 text-[14px] font-medium text-muted-foreground"
                        >
                          {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.FRT') }}
                          <RelayTooltip
                            :content="$t('SLA.LIST.RESPONSE_TYPES.FRT')"
                            side="top"
                          >
                            <Icon
                              icon="i-lucide-info"
                              class="size-3.5 cursor-help"
                            />
                          </RelayTooltip>
                        </div>
                        <div
                          class="flex items-center gap-1 text-[14px] font-medium text-muted-foreground"
                        >
                          {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.NRT') }}
                          <RelayTooltip
                            :content="$t('SLA.LIST.RESPONSE_TYPES.NRT')"
                            side="top"
                          >
                            <Icon
                              icon="i-lucide-info"
                              class="size-3.5 cursor-help"
                            />
                          </RelayTooltip>
                        </div>
                        <div
                          class="flex items-center gap-1 text-[14px] font-medium text-muted-foreground"
                        >
                          {{ $t('SLA.LIST.RESPONSE_TYPES.SHORT_HAND.RT') }}
                          <RelayTooltip
                            :content="$t('SLA.LIST.RESPONSE_TYPES.RT')"
                            side="top"
                          >
                            <Icon
                              icon="i-lucide-info"
                              class="size-3.5 cursor-help"
                            />
                          </RelayTooltip>
                        </div>
                        <div
                          class="text-right text-[14px] font-medium text-muted-foreground"
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
                            <p
                              class="truncate text-[14px] font-medium text-foreground"
                            >
                              {{ sla.name }}
                            </p>
                            <p
                              class="line-clamp-1 text-[13px] text-muted-foreground"
                            >
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
                            class="flex items-center justify-end gap-1.5 opacity-0 transition-opacity group-hover:opacity-100"
                          >
                            <RelayTooltip
                              :content="$t('SLA.FORM.EDIT')"
                              side="top"
                            >
                              <button
                                type="button"
                                class="size-8 inline-flex items-center justify-center rounded-md border border-input bg-background shadow-xs hover:bg-accent hover:text-accent-foreground transition-colors disabled:opacity-50"
                                :disabled="loading[sla.id]"
                                @click="openEditPopup(sla)"
                              >
                                <Icon
                                  icon="i-lucide-pencil"
                                  class="size-3.5 text-muted-foreground"
                                />
                              </button>
                            </RelayTooltip>
                            <RelayTooltip
                              :content="$t('SLA.FORM.DELETE')"
                              side="top"
                            >
                              <button
                                type="button"
                                class="size-8 inline-flex items-center justify-center rounded-md border border-input bg-background shadow-xs hover:bg-destructive/10 hover:text-destructive hover:border-destructive/20 transition-colors disabled:opacity-50"
                                :disabled="loading[sla.id]"
                                @click="openDeletePopup(sla)"
                              >
                                <Icon
                                  icon="i-lucide-trash-2"
                                  class="size-3.5 text-muted-foreground hover:text-destructive"
                                />
                              </button>
                            </RelayTooltip>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <RelayModal
        :show="showAddPopup"
        :title="slaToEdit ? $t('SLA.EDIT.TITLE') : $t('SLA.ADD.TITLE')"
        :description="$t('SLA.ADD.DESC')"
        size="lg"
        flush
        @close="hideAddPopup"
      >
        <AddSLA :sla-to-edit="slaToEdit" @close="hideAddPopup" />
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
