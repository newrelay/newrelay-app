<script setup>
import { useAlert } from 'dashboard/composables';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import SettingsLayout from '../SettingsLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  generateTranslationPayload,
  generateLogActionKey,
} from 'dashboard/helper/auditlogHelper';
import { computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';

const getters = useStoreGetters();
const store = useStore();
const router = useRouter();
const records = computed(() => getters['auditlogs/getAuditLogs'].value);
const uiFlags = computed(() => getters['auditlogs/getUIFlags'].value);
const meta = computed(() => getters['auditlogs/getMeta'].value);
const agentList = computed(() => getters['agents/getAgents'].value);

const { t } = useI18n();
const route = useRoute();

const routerPage = computed(() => Number(route.query.page ?? 1));

const currentPage = computed(() => Number(meta.value.currentPage) || 1);
const perPage = computed(() => Number(meta.value.perPage) || 25);
const totalEntries = computed(() => Number(meta.value.totalEntries) || 0);
const totalPages = computed(() =>
  Math.max(1, Math.ceil(totalEntries.value / perPage.value))
);
const startItem = computed(() =>
  totalEntries.value === 0 ? 0 : (currentPage.value - 1) * perPage.value + 1
);
const endItem = computed(() =>
  Math.min(startItem.value + perPage.value - 1, totalEntries.value)
);
const isFirstPage = computed(() => currentPage.value <= 1);
const isLastPage = computed(() => currentPage.value >= totalPages.value);
const showPagination = computed(() => totalEntries.value > perPage.value);

const fetchAuditLogs = page => {
  try {
    store.dispatch('auditlogs/fetch', { page });
  } catch (error) {
    const errorMessage = error?.message || t('AUDIT_LOGS.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const generateLogText = auditLogItem => {
  const payload = generateTranslationPayload(auditLogItem, agentList.value);
  const translationKey = generateLogActionKey(auditLogItem);

  const joinIfArray = value => {
    return Array.isArray(value) ? value.join(', ') : value;
  };

  const mergedPayload = {
    ...payload,
    attributes: joinIfArray(payload.attributes),
    values: joinIfArray(payload.values),
  };
  return t(translationKey, mergedPayload);
};

const onPageChange = page => {
  router.push({ name: 'auditlogs_list', query: { page } });
};

onMounted(() => {
  store.dispatch('agents/get');
  fetchAuditLogs(routerPage.value);
});

watch(routerPage, (newPage, oldPage) => {
  if (newPage !== oldPage) {
    fetchAuditLogs(newPage);
  }
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('AUDIT_LOGS.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div class="space-y-6">
        <div
          class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <div
            v-if="!records.length"
            class="flex flex-col items-center justify-center bg-muted/10 py-20"
          >
            <div
              class="mb-5 flex size-16 items-center justify-center rounded-full border border-border/50 bg-muted/50 shadow-xs"
            >
              <Icon
                icon="i-lucide-file-check"
                class="size-8 text-muted-foreground/60"
              />
            </div>
            <h4 class="mb-1.5 text-base font-medium text-foreground">
              {{ $t('AUDIT_LOGS.LIST.EMPTY_TITLE') }}
            </h4>
            <p class="max-w-sm text-center text-[14px] text-muted-foreground">
              {{ $t('AUDIT_LOGS.LIST.404') }}
            </p>
          </div>

          <template v-else>
            <div class="overflow-x-auto">
              <table class="w-full border-collapse text-left">
                <thead>
                  <tr class="border-b border-border/40">
                    <th
                      class="bg-transparent px-6 py-4 text-sm font-medium text-foreground"
                    >
                      {{ $t('AUDIT_LOGS.LIST.TABLE_HEADER.ACTIVITY') }}
                    </th>
                    <th
                      class="w-48 bg-transparent px-6 py-4 text-sm font-medium text-foreground"
                    >
                      {{ $t('AUDIT_LOGS.LIST.TABLE_HEADER.TIME') }}
                    </th>
                    <th
                      class="w-48 bg-transparent px-6 py-4 text-sm font-medium text-foreground"
                    >
                      {{ $t('AUDIT_LOGS.LIST.TABLE_HEADER.IP_ADDRESS') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border/40">
                  <tr
                    v-for="auditLogItem in records"
                    :key="auditLogItem.id"
                    class="transition-colors hover:bg-muted/10"
                  >
                    <td class="px-6 py-4 text-sm text-foreground">
                      {{ generateLogText(auditLogItem) }}
                    </td>
                    <td
                      class="whitespace-nowrap px-6 py-4 text-sm text-muted-foreground"
                    >
                      {{
                        messageTimestamp(
                          auditLogItem.created_at,
                          'MMM dd, yyyy hh:mm a'
                        )
                      }}
                    </td>
                    <td
                      class="whitespace-nowrap px-6 py-4 text-sm text-muted-foreground"
                    >
                      {{ auditLogItem.remote_address || '—' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div
              v-if="showPagination"
              class="flex items-center justify-between border-t border-border/60 bg-muted/10 p-3 text-xs text-muted-foreground"
            >
              <span class="pl-2">
                {{
                  $t(
                    'AUDIT_LOGS.PAGINATION_FOOTER.SHOWING',
                    {
                      startItem,
                      endItem,
                      totalItems: totalEntries,
                    },
                    totalEntries
                  )
                }}
              </span>
              <div class="flex items-center gap-1.5">
                <button
                  type="button"
                  class="h-7 rounded-md px-3 text-xs font-medium transition-colors hover:bg-accent disabled:pointer-events-none disabled:opacity-40"
                  :disabled="isFirstPage"
                  @click="onPageChange(currentPage - 1)"
                >
                  {{ $t('AUDIT_LOGS.PAGINATION_FOOTER.PREVIOUS') }}
                </button>
                <button
                  type="button"
                  class="h-7 rounded-md px-3 text-xs font-medium transition-colors hover:bg-accent disabled:pointer-events-none disabled:opacity-40"
                  :disabled="isLastPage"
                  @click="onPageChange(currentPage + 1)"
                >
                  {{ $t('AUDIT_LOGS.PAGINATION_FOOTER.NEXT') }}
                </button>
              </div>
            </div>
          </template>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
