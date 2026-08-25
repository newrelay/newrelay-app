<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import CampaignAnalyticsAPI from 'dashboard/api/campaignAnalytics';
import camelcaseKeys from 'camelcase-keys';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import Spinner from 'shared/components/Spinner.vue';
import DealMetricsRow from 'dashboard/components-next/Deals/DealMetricsRow.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineOptions({ name: 'CampaignAnalyticsIndex' });

const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();

const loading = ref(true);
const searchQuery = ref('');
const summary = ref({
  totalCampaigns: 0,
  active: 0,
  completed: 0,
  processing: 0,
  attributedConversations: 0,
});
const campaigns = ref([]);

const metrics = computed(() => [
  {
    key: 'total',
    label: t('CAMPAIGN_ANALYTICS.METRICS.TOTAL'),
    value: String(summary.value.totalCampaigns || 0),
  },
  {
    key: 'active',
    label: t('CAMPAIGN_ANALYTICS.METRICS.ACTIVE'),
    value: String(summary.value.active || 0),
  },
  {
    key: 'completed',
    label: t('CAMPAIGN_ANALYTICS.METRICS.COMPLETED'),
    value: String(summary.value.completed || 0),
  },
  {
    key: 'conversations',
    label: t('CAMPAIGN_ANALYTICS.METRICS.CONVERSATIONS'),
    value: String(summary.value.attributedConversations || 0),
  },
]);

const filteredCampaigns = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return campaigns.value;
  return campaigns.value.filter(campaign =>
    [campaign.title, campaign.description, campaign.inbox?.name]
      .filter(Boolean)
      .some(value => String(value).toLowerCase().includes(query))
  );
});

const formatDate = value => {
  if (!value) return '—';
  return new Date(value).toLocaleDateString();
};

const statusLabel = status => {
  if (!status) return '—';
  const key = `CAMPAIGN_ANALYTICS.STATUS.${status}`;
  const label = t(key);
  return label === key ? status : label;
};

const typeLabel = type => {
  if (!type) return '—';
  const key = `CAMPAIGN_ANALYTICS.TYPE.${type}`;
  const label = t(key);
  return label === key ? type : label;
};

const channelLabel = inbox => {
  if (!inbox) return '—';
  return inbox.name || inbox.channelType || '—';
};

const load = async () => {
  loading.value = true;
  try {
    const { data } = await CampaignAnalyticsAPI.get();
    const payload = camelcaseKeys(data.payload || {}, { deep: true });
    summary.value = payload.summary || summary.value;
    campaigns.value = payload.campaigns || [];
  } catch (error) {
    useAlert(error?.message || t('CAMPAIGN_ANALYTICS.ERROR'));
  } finally {
    loading.value = false;
  }
};

const goToCampaigns = () => {
  router.push({
    name: 'campaigns_livechat_index',
    params: { accountId: accountId.value },
  });
};

onMounted(load);
</script>

<template>
  <div class="flex h-full min-h-0 flex-col bg-background">
    <div
      class="flex flex-wrap items-start justify-between gap-4 border-b border-border bg-card px-6 py-6"
    >
      <div>
        <h1 class="text-base font-medium text-foreground">
          {{ $t('CAMPAIGN_ANALYTICS.HEADER') }}
        </h1>
        <p class="mt-1 text-[13px] font-medium text-muted-foreground">
          {{ $t('CAMPAIGN_ANALYTICS.DESCRIPTION') }}
        </p>
      </div>
      <RelayButton
        variant="outline"
        class="h-9 border-border px-4 text-[13px] font-medium hover:border-transparent"
        @click="goToCampaigns"
      >
        {{ $t('CAMPAIGN_ANALYTICS.EMPTY.CTA') }}
      </RelayButton>
    </div>

    <DealMetricsRow :metrics="metrics" />

    <div
      class="flex items-center gap-3 border-b border-border bg-card px-6 py-3"
    >
      <div class="relative w-full max-w-xs">
        <Icon
          icon="i-lucide-search"
          class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <RelayInput
          v-model="searchQuery"
          class="pl-9 text-[13px]"
          :placeholder="$t('CAMPAIGN_ANALYTICS.SEARCH_PLACEHOLDER')"
        />
      </div>
    </div>

    <div class="min-h-0 flex-1 overflow-auto p-6">
      <div v-if="loading" class="flex items-center justify-center py-20">
        <Spinner />
      </div>

      <div
        v-else-if="!filteredCampaigns.length"
        class="flex flex-col items-center justify-center gap-3 rounded-xl border border-border/60 bg-card px-6 py-16 text-center"
      >
        <h2 class="text-[20px] font-[600] text-foreground">
          {{ $t('CAMPAIGN_ANALYTICS.EMPTY.TITLE') }}
        </h2>
        <p class="max-w-md text-[14px] text-muted-foreground">
          {{ $t('CAMPAIGN_ANALYTICS.EMPTY.DESCRIPTION') }}
        </p>
        <RelayButton class="mt-2 h-9 px-4 text-[13px]" @click="goToCampaigns">
          {{ $t('CAMPAIGN_ANALYTICS.EMPTY.CTA') }}
        </RelayButton>
      </div>

      <div
        v-else
        class="overflow-hidden rounded-xl border border-border/60 bg-card"
      >
        <table class="min-w-full table-auto">
          <thead>
            <tr class="border-b border-border text-left">
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.TITLE') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.STATUS') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.TYPE') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.CHANNEL') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.AUDIENCE') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.CONVERSATIONS') }}
              </th>
              <th
                class="px-4 py-3 text-[12px] font-medium text-muted-foreground"
              >
                {{ $t('CAMPAIGN_ANALYTICS.TABLE.CREATED') }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="campaign in filteredCampaigns"
              :key="campaign.id"
              class="border-b border-border/60 last:border-0 hover:bg-muted/40"
            >
              <td class="px-4 py-3">
                <div class="text-[14px] font-medium text-foreground">
                  {{ campaign.title }}
                </div>
                <div
                  v-if="campaign.description"
                  class="mt-0.5 text-[12px] text-muted-foreground"
                >
                  {{ campaign.description }}
                </div>
              </td>
              <td class="px-4 py-3">
                <span
                  class="inline-flex rounded-md bg-primary/10 px-2 py-0.5 text-[12px] font-medium text-primary"
                >
                  {{ statusLabel(campaign.campaignStatus) }}
                </span>
              </td>
              <td class="px-4 py-3 text-[13px] capitalize text-foreground">
                {{ typeLabel(campaign.campaignType) }}
              </td>
              <td class="px-4 py-3 text-[13px] text-muted-foreground">
                {{ channelLabel(campaign.inbox) }}
              </td>
              <td class="px-4 py-3 text-[13px] text-foreground">
                {{ campaign.audienceCount || 0 }}
              </td>
              <td class="px-4 py-3 text-[13px] text-foreground">
                {{ campaign.conversationsCount || 0 }}
              </td>
              <td class="px-4 py-3 text-[13px] text-muted-foreground">
                {{ formatDate(campaign.createdAt) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
