<script setup>
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Policy from 'dashboard/components/policy.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CompaniesDetailsLayout from 'dashboard/components-next/Companies/CompaniesDetailsLayout.vue';
import CompanyProfileCard from 'dashboard/components-next/Companies/CompanyDetail/CompanyProfileCard.vue';
import CompanyContactsSidebar from 'dashboard/components-next/Companies/CompanyDetail/CompanyContactsSidebar.vue';
import CompanyHistorySidebar from 'dashboard/components-next/Companies/CompanyDetail/CompanyHistorySidebar.vue';
import CompanyNotesSidebar from 'dashboard/components-next/Companies/CompanyDetail/CompanyNotesSidebar.vue';
import ConfirmCompanyDeleteDialog from 'dashboard/components-next/Companies/CompanyDetail/ConfirmCompanyDeleteDialog.vue';
import {
  RelayBadge,
  RelayButton,
  RelayInput,
} from 'dashboard/components-next/relay';
import { useCompaniesStore } from 'dashboard/stores/companies';

const route = useRoute();
const router = useRouter();
const companiesStore = useCompaniesStore();
const { t } = useI18n();

const confirmDeleteDialogRef = ref(null);
const selectedCandidate = ref(null);
const activeTab = ref('overview');
const isEditingDetails = ref(false);

const DETAIL_TABS = [
  { value: 'overview', labelKey: 'COMPANIES.DETAIL.TABS.OVERVIEW' },
  { value: 'contacts', labelKey: 'COMPANIES.DETAIL.TABS.CONTACTS' },
  { value: 'history', labelKey: 'COMPANIES.DETAIL.TABS.HISTORY' },
  { value: 'notes', labelKey: 'COMPANIES.DETAIL.TABS.NOTES' },
];

const detailsForm = reactive({
  phone: '',
  email: '',
  website: '',
  address: '',
  state: '',
  city: '',
  description: '',
});

const companyId = computed(() => Number(route.params.companyId));
const company = computed(() => companiesStore.getRecord(companyId.value));
const companyContacts = computed(() => companiesStore.companyContacts);
const companyContactsMeta = computed(() => companiesStore.companyContactsMeta);
const companyConversations = computed(
  () => companiesStore.companyConversations || []
);
const companyNotes = computed(() => companiesStore.companyNotes || []);
const contactSearchResults = computed(
  () => companiesStore.contactSearchResults
);
const uiFlags = computed(() => companiesStore.getUIFlags);

const isFetchingCompany = computed(() => uiFlags.value.fetchingItem);
const isFetchingContacts = computed(() => uiFlags.value.fetchingContacts);
const isFetchingConversations = computed(
  () => uiFlags.value.fetchingConversations
);
const isFetchingNotes = computed(() => uiFlags.value.fetchingNotes);
const isSearchingContacts = computed(() => uiFlags.value.searchingContacts);
const isManagingContacts = computed(
  () => uiFlags.value.creatingContact || uiFlags.value.removingContact
);
const isDeletingCompany = computed(() => uiFlags.value.deletingItem);
const isUpdating = computed(() => uiFlags.value.updatingItem);
const hasCompany = computed(() => Boolean(company.value?.id));
const showInitialLoadingState = computed(
  () =>
    !hasCompany.value && (isFetchingCompany.value || isFetchingContacts.value)
);

const emptyValue = computed(() => t('COMPANIES.EMPTY_VALUE'));
const attrs = computed(() => company.value?.additionalAttributes || {});
const displayName = computed(
  () => company.value?.name || t('COMPANIES.UNNAMED')
);
const aboutText = computed(() => {
  const name = displayName.value;
  const fallback = t('COMPANIES.DETAIL.ABOUT.FALLBACK', { name });
  if (company.value?.description) {
    return `${company.value.description} ${fallback}`;
  }
  return fallback;
});

const websiteHref = computed(() => {
  const value = detailsForm.website || company.value?.domain;
  if (!value) return null;
  return value.startsWith('http') ? value : `https://${value}`;
});

const recentContacts = computed(() => companyContacts.value.slice(0, 3));
const recentConversations = computed(() =>
  companyConversations.value.slice(0, 3)
);

const contactInitials = contact => {
  const name = contact.name || '';
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }
  return (name.slice(0, 2) || '?').toUpperCase();
};

const syncDetailsForm = current => {
  const companyAttrs = current?.additionalAttributes || {};
  detailsForm.phone = companyAttrs.phone || '';
  detailsForm.email = companyAttrs.email || '';
  detailsForm.website = companyAttrs.website || current?.domain || '';
  detailsForm.address = companyAttrs.address || '';
  detailsForm.state = companyAttrs.state || '';
  detailsForm.city = companyAttrs.city || '';
  detailsForm.description = current?.description || '';
};

watch(
  company,
  current => {
    if (current?.id) syncDetailsForm(current);
  },
  { immediate: true, deep: true }
);

const goToCompaniesIndex = () => {
  router.push({
    name: 'companies_dashboard_index',
    params: { accountId: route.params.accountId },
    query: { page: '1' },
  });
};

const goToCompaniesList = () => {
  if (window.history.state?.back) {
    router.back();
    return;
  }
  goToCompaniesIndex();
};

const goToContacts = () => {
  activeTab.value = 'contacts';
};

const openContact = contactId => {
  router.push({
    name: 'contacts_edit',
    params: {
      accountId: route.params.accountId,
      contactId,
    },
  });
};

const loadCompanyContactsPage = async page => {
  if (!companyId.value) return;
  await companiesStore.getCompanyContacts(companyId.value, page);
};

const openDeleteCompanyDialog = () => {
  confirmDeleteDialogRef.value?.dialogRef.open();
};

const clearSelectedCandidate = () => {
  selectedCandidate.value = null;
};

const domainFromWebsite = website => {
  if (!website?.trim()) return null;
  return website
    .replace(/(https?:\/\/)?(www\.)?/i, '')
    .split('/')[0]
    .trim();
};

const handleSaveDetails = async () => {
  try {
    const updated = await companiesStore.update({
      id: companyId.value,
      domain: domainFromWebsite(detailsForm.website),
      description: detailsForm.description.trim() || null,
      additionalAttributes: {
        ...attrs.value,
        phone: detailsForm.phone.trim() || undefined,
        email: detailsForm.email.trim() || undefined,
        website: detailsForm.website.trim() || undefined,
        address: detailsForm.address.trim() || undefined,
        state: detailsForm.state.trim() || undefined,
        city: detailsForm.city.trim() || undefined,
      },
    });
    syncDetailsForm(updated);
    isEditingDetails.value = false;
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_SUCCESS'));
  } catch {
    syncDetailsForm(company.value);
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_ERROR'));
  }
};

const toggleEditDetails = () => {
  if (isEditingDetails.value) {
    handleSaveDetails();
    return;
  }
  isEditingDetails.value = true;
};

const handleContactSearch = async query => {
  await companiesStore.searchCompanyContactCandidates({
    companyId: companyId.value,
    search: query,
  });
};

const handleConfirmContactSelection = async () => {
  const candidate = selectedCandidate.value;
  if (!candidate) return;

  const isReassigning =
    candidate.company?.id && candidate.company.id !== companyId.value;
  const message = isReassigning
    ? t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REASSIGN_SUCCESS')
    : t('COMPANIES.DETAIL.CONTACTS.MESSAGES.ADD_SUCCESS');

  try {
    await companiesStore.attachContactToCompany(companyId.value, candidate.id);
    useAlert(message);
    clearSelectedCandidate();
  } catch {
    useAlert(
      isReassigning
        ? t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REASSIGN_ERROR')
        : t('COMPANIES.DETAIL.CONTACTS.MESSAGES.ADD_ERROR')
    );
  }
};

const handleRemoveContact = async contactId => {
  const currentPage = Number(companyContactsMeta.value.page || 1);
  const nextPage =
    currentPage > 1 && companyContacts.value.length === 1
      ? currentPage - 1
      : currentPage;

  try {
    await companiesStore.removeContactFromCompany(
      companyId.value,
      contactId,
      nextPage
    );
    useAlert(t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REMOVE_SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.DETAIL.CONTACTS.MESSAGES.REMOVE_ERROR'));
  }
};

const handleDeleteCompany = async () => {
  try {
    await companiesStore.delete(companyId.value);
    useAlert(t('COMPANIES.DETAIL.DELETE.MESSAGES.SUCCESS'));
    confirmDeleteDialogRef.value?.dialogRef.close();
    goToCompaniesIndex();
  } catch {
    useAlert(t('COMPANIES.DETAIL.DELETE.MESSAGES.ERROR'));
  }
};

watch(
  companyId,
  async id => {
    companiesStore.resetCompanyDetailState();
    clearSelectedCandidate();
    activeTab.value = 'overview';
    if (!id) return;
    await Promise.allSettled([
      companiesStore.show(id),
      companiesStore.getCompanyContacts(id),
      companiesStore.getCompanyConversations(id),
    ]);
  },
  { immediate: true }
);

watch(activeTab, tab => {
  if (!companyId.value) return;
  if (tab === 'notes') companiesStore.getCompanyNotes(companyId.value);
  if (tab === 'history') {
    companiesStore.getCompanyConversations(companyId.value);
  }
  if (tab === 'contacts') {
    companiesStore.getCompanyContacts(companyId.value);
  }
});

onBeforeUnmount(() => {
  companiesStore.resetCompanyDetailState();
});
</script>

<template>
  <CompaniesDetailsLayout @back="goToCompaniesList">
    <template #header>
      <CompanyProfileCard
        v-if="hasCompany"
        :company="company"
        :is-loading="isFetchingCompany"
        @back="goToCompaniesList"
      />
    </template>

    <div
      v-if="showInitialLoadingState"
      class="flex flex-col items-center justify-center gap-3 py-24 text-muted-foreground"
    >
      <Spinner />
      <span class="text-sm">{{ t('COMPANIES.DETAIL.LOADING') }}</span>
    </div>

    <div
      v-else-if="!hasCompany"
      class="mx-8 my-12 flex flex-col items-center justify-center gap-3 rounded-2xl border border-border bg-card px-6 py-24 text-center"
    >
      <span class="text-lg font-medium text-foreground">
        {{ t('COMPANIES.DETAIL.EMPTY_STATE.TITLE') }}
      </span>
      <p class="max-w-md text-sm text-muted-foreground">
        {{ t('COMPANIES.DETAIL.EMPTY_STATE.SUBTITLE') }}
      </p>
      <RelayButton variant="outline" class="mt-2" @click="goToCompaniesList">
        {{ t('COMPANIES.DETAIL.BACK') }}
      </RelayButton>
    </div>

    <div v-else class="flex h-full w-full flex-col">
      <!-- Detail tabs: absolute bar — global button { border-0 } kills border-b-2 -->
      <div class="border-b border-border bg-card px-8">
        <div
          class="flex h-14 w-full items-center justify-start gap-6"
          role="tablist"
        >
          <button
            v-for="tab in DETAIL_TABS"
            :key="tab.value"
            type="button"
            role="tab"
            :aria-selected="activeTab === tab.value"
            class="relative -mb-px h-full px-1 text-[14px] font-medium transition-colors"
            :class="
              activeTab === tab.value
                ? 'text-foreground'
                : 'text-muted-foreground hover:text-foreground'
            "
            @click="activeTab = tab.value"
          >
            <template v-if="tab.value === 'contacts'">
              {{
                t('COMPANIES.DETAIL.TABS.CONTACTS_WITH_COUNT', {
                  count: Number(companyContactsMeta.totalCount || 0),
                })
              }}
            </template>
            <template v-else>
              {{
                {
                  overview: t('COMPANIES.DETAIL.TABS.OVERVIEW'),
                  history: t('COMPANIES.DETAIL.TABS.HISTORY'),
                  notes: t('COMPANIES.DETAIL.TABS.NOTES'),
                }[tab.value]
              }}
            </template>
            <span
              v-if="activeTab === tab.value"
              class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
              aria-hidden="true"
            />
          </button>
        </div>
      </div>

      <div class="mx-auto w-full max-w-[1600px] p-8">
        <div v-if="activeTab === 'overview'" class="outline-none">
          <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
            <div class="flex flex-col gap-6 lg:col-span-2">
              <div
                class="rounded-xl border border-border bg-card p-6 shadow-sm"
              >
                <div class="mb-4 flex items-center gap-3">
                  <div
                    class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-muted"
                  >
                    <span class="i-lucide-building size-4 text-foreground/70" />
                  </div>
                  <h3
                    class="text-base font-medium tracking-tight text-foreground"
                  >
                    {{ t('COMPANIES.DETAIL.ABOUT.TITLE') }}
                  </h3>
                </div>
                <p class="text-[14px] leading-relaxed text-muted-foreground">
                  {{ aboutText }}
                </p>
              </div>

              <div
                class="flex flex-col rounded-xl border border-border bg-card p-6 shadow-sm"
              >
                <div class="mb-6 flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <div
                      class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-muted"
                    >
                      <span
                        class="i-lucide-contact size-4 text-foreground/70"
                      />
                    </div>
                    <h3
                      class="text-base font-medium tracking-tight text-foreground"
                    >
                      {{ t('COMPANIES.DETAIL.DETAILS_CARD.TITLE') }}
                    </h3>
                  </div>
                  <RelayButton
                    variant="secondary"
                    size="sm"
                    class="flex h-8 items-center rounded-md border border-transparent bg-muted/50 px-3 text-[12px] font-medium text-foreground hover:border-transparent hover:bg-muted"
                    :disabled="isUpdating"
                    @click="toggleEditDetails"
                  >
                    <span
                      :class="
                        isEditingDetails ? 'i-lucide-check' : 'i-lucide-pencil'
                      "
                      class="mr-1.5 size-3"
                    />
                    {{
                      isEditingDetails
                        ? t('COMPANIES.DETAIL.DETAILS_CARD.SAVE')
                        : t('COMPANIES.DETAIL.DETAILS_CARD.EDIT')
                    }}
                  </RelayButton>
                </div>

                <div
                  class="grid grid-cols-1 overflow-hidden rounded-xl border border-border bg-background sm:grid-cols-2"
                >
                  <div
                    class="flex items-start gap-4 border-b border-border p-5 sm:border-r"
                  >
                    <div
                      class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-phone size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <span
                        class="mb-1 text-[13px] font-medium text-foreground"
                      >
                        {{ t('COMPANIES.DETAIL.DETAILS_CARD.PHONE') }}
                      </span>
                      <span
                        v-if="!isEditingDetails"
                        class="text-[14px] text-muted-foreground"
                      >
                        {{ detailsForm.phone || emptyValue }}
                      </span>
                      <RelayInput
                        v-else
                        v-model="detailsForm.phone"
                        class-name="h-8 w-full text-[14px]"
                      />
                    </div>
                  </div>
                  <div
                    class="flex items-start gap-4 border-b border-border p-5"
                  >
                    <div
                      class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-mail size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <span
                        class="mb-1 text-[13px] font-medium text-foreground"
                      >
                        {{ t('COMPANIES.DETAIL.DETAILS_CARD.EMAIL') }}
                      </span>
                      <span
                        v-if="!isEditingDetails"
                        class="text-[14px] text-muted-foreground"
                      >
                        {{ detailsForm.email || emptyValue }}
                      </span>
                      <RelayInput
                        v-else
                        v-model="detailsForm.email"
                        class-name="h-8 w-full text-[14px]"
                      />
                    </div>
                  </div>
                  <div
                    class="flex items-start gap-4 border-b border-border p-5 sm:border-r sm:border-b-0"
                  >
                    <div
                      class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-globe size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <span
                        class="mb-1 text-[13px] font-medium text-foreground"
                      >
                        {{ t('COMPANIES.DETAIL.DETAILS_CARD.WEBSITE') }}
                      </span>
                      <a
                        v-if="!isEditingDetails && websiteHref"
                        :href="websiteHref"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="flex items-center gap-1.5 text-[14px] text-muted-foreground transition-colors hover:text-primary"
                      >
                        {{ detailsForm.website || company.domain }}
                        <span class="i-lucide-external-link size-3" />
                      </a>
                      <span
                        v-else-if="!isEditingDetails"
                        class="text-[14px] text-muted-foreground"
                      >
                        {{ emptyValue }}
                      </span>
                      <RelayInput
                        v-else
                        v-model="detailsForm.website"
                        class-name="h-8 w-full text-[14px]"
                      />
                    </div>
                  </div>
                  <div
                    class="flex items-start gap-4 border-b border-border p-5 sm:border-b-0"
                  >
                    <div
                      class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-map-pin size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <span
                        class="mb-1 text-[13px] font-medium text-foreground"
                      >
                        {{ t('COMPANIES.DETAIL.DETAILS_CARD.ADDRESS') }}
                      </span>
                      <span
                        v-if="!isEditingDetails"
                        class="text-[14px] text-muted-foreground"
                      >
                        {{ detailsForm.address || emptyValue }}
                      </span>
                      <RelayInput
                        v-else
                        v-model="detailsForm.address"
                        class-name="h-8 w-full text-[14px]"
                      />
                    </div>
                  </div>
                  <div
                    class="flex items-start gap-4 border-t border-border p-5 sm:border-r"
                  >
                    <div
                      class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-map size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <span
                        class="mb-1 text-[13px] font-medium text-foreground"
                      >
                        {{ t('COMPANIES.DETAIL.DETAILS_CARD.STATE') }}
                      </span>
                      <span
                        v-if="!isEditingDetails"
                        class="text-[14px] text-muted-foreground"
                      >
                        {{ detailsForm.state || emptyValue }}
                      </span>
                      <RelayInput
                        v-else
                        v-model="detailsForm.state"
                        class-name="h-8 w-full text-[14px]"
                      />
                    </div>
                  </div>
                  <div
                    class="flex items-start gap-4 border-t border-border p-5"
                  >
                    <div
                      class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-building-2 size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <span
                        class="mb-1 text-[13px] font-medium text-foreground"
                      >
                        {{ t('COMPANIES.DETAIL.DETAILS_CARD.CITY') }}
                      </span>
                      <span
                        v-if="!isEditingDetails"
                        class="text-[14px] text-muted-foreground"
                      >
                        {{ detailsForm.city || emptyValue }}
                      </span>
                      <RelayInput
                        v-else
                        v-model="detailsForm.city"
                        class-name="h-8 w-full text-[14px]"
                      />
                    </div>
                  </div>
                </div>
              </div>

              <div
                class="flex flex-1 flex-col rounded-xl border border-border bg-card p-6 shadow-sm"
              >
                <div class="mb-4 flex items-center gap-3">
                  <div
                    class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-muted"
                  >
                    <span
                      class="i-lucide-file-text size-4 text-foreground/70"
                    />
                  </div>
                  <h3
                    class="text-base font-medium tracking-tight text-foreground"
                  >
                    {{ t('COMPANIES.DETAIL.DESCRIPTION.TITLE') }}
                  </h3>
                </div>
                <p class="text-[14px] leading-relaxed text-muted-foreground">
                  {{
                    company.description ||
                    t('COMPANIES.DETAIL.DESCRIPTION.FALLBACK')
                  }}
                </p>
              </div>

              <Policy :permissions="['administrator']">
                <section
                  class="flex flex-col items-start gap-4 rounded-xl border border-border bg-card p-6 shadow-sm"
                >
                  <div class="flex flex-col gap-2">
                    <h6 class="text-base font-medium text-foreground">
                      {{ t('COMPANIES.DETAIL.DELETE.SECTION_TITLE') }}
                    </h6>
                    <span class="text-sm text-muted-foreground">
                      {{ t('COMPANIES.DETAIL.DELETE.SECTION_DESCRIPTION') }}
                    </span>
                  </div>
                  <RelayButton
                    variant="destructive"
                    :disabled="isDeletingCompany"
                    @click="openDeleteCompanyDialog"
                  >
                    {{ t('COMPANIES.DETAIL.DELETE.BUTTON') }}
                  </RelayButton>
                </section>
              </Policy>
            </div>

            <div class="flex flex-col gap-6">
              <div
                class="rounded-xl border border-border bg-muted/30 p-6 shadow-sm"
              >
                <div class="mb-6 flex items-center gap-2">
                  <span class="i-lucide-bar-chart-2 size-4 text-primary" />
                  <h3
                    class="text-base font-medium tracking-tight text-foreground"
                  >
                    {{ t('COMPANIES.DETAIL.SUMMARY.TITLE') }}
                  </h3>
                </div>
                <div
                  class="grid grid-cols-3 divide-x divide-border/60 text-center"
                >
                  <div class="flex flex-col gap-1.5">
                    <span class="text-[12px] font-medium text-muted-foreground">
                      {{ t('COMPANIES.DETAIL.SUMMARY.CONTACTS') }}
                    </span>
                    <span class="text-xl font-bold text-foreground">
                      {{ Number(company.contactsCount || 0) }}
                    </span>
                  </div>
                  <div class="flex flex-col gap-1.5">
                    <span class="text-[12px] font-medium text-muted-foreground">
                      {{ t('COMPANIES.DETAIL.SUMMARY.DEALS') }}
                    </span>
                    <span class="text-xl font-bold text-foreground">
                      {{ 0 }}
                    </span>
                  </div>
                  <div class="flex flex-col gap-1.5">
                    <span class="text-[12px] font-medium text-muted-foreground">
                      {{ t('COMPANIES.DETAIL.SUMMARY.OPEN_TASKS') }}
                    </span>
                    <span class="text-xl font-bold text-foreground">
                      {{ 0 }}
                    </span>
                  </div>
                </div>
              </div>

              <div
                class="flex flex-col rounded-xl border border-border bg-card p-6 shadow-sm"
              >
                <div class="mb-6 flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class="i-lucide-users size-4 text-primary" />
                    <h3
                      class="text-base font-medium tracking-tight text-foreground"
                    >
                      {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.TITLE') }}
                    </h3>
                  </div>
                  <RelayButton
                    variant="secondary"
                    size="sm"
                    class="h-8 rounded-md border border-transparent bg-muted/50 px-3 text-[12px] font-medium text-foreground hover:bg-muted"
                    @click="goToContacts"
                  >
                    {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.VIEW_ALL') }}
                  </RelayButton>
                </div>

                <div
                  v-if="recentContacts.length"
                  class="flex flex-col space-y-5"
                >
                  <button
                    v-for="(contact, index) in recentContacts"
                    :key="contact.id"
                    type="button"
                    class="flex w-full items-center justify-between text-left"
                    @click="openContact(contact.id)"
                  >
                    <div class="flex items-center gap-3">
                      <div
                        class="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary/10 font-semibold text-primary"
                      >
                        {{ contactInitials(contact) }}
                      </div>
                      <div class="flex flex-col">
                        <span class="text-[14px] font-medium text-foreground">
                          {{
                            contact.name ||
                            t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT')
                          }}
                        </span>
                        <span class="text-[13px] text-muted-foreground">
                          {{ contact.email || emptyValue }}
                        </span>
                      </div>
                    </div>
                    <RelayBadge
                      v-if="index === 0"
                      variant="secondary"
                      class="rounded-full border-transparent bg-primary/10 px-2.5 font-medium text-primary hover:bg-primary/20"
                    >
                      {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.OWNER') }}
                    </RelayBadge>
                  </button>
                </div>
                <p v-else class="text-sm text-muted-foreground">
                  {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.EMPTY') }}
                </p>
              </div>

              <div
                class="flex flex-col rounded-xl border border-border bg-card p-6 shadow-sm"
              >
                <div class="mb-6 flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class="i-lucide-activity size-4 text-primary" />
                    <h3
                      class="text-base font-medium tracking-tight text-foreground"
                    >
                      {{ t('COMPANIES.DETAIL.ACTIVITY.TITLE') }}
                    </h3>
                  </div>
                  <RelayButton
                    variant="secondary"
                    size="sm"
                    class="h-8 rounded-md border border-transparent bg-muted/50 px-3 text-[12px] font-medium text-foreground hover:bg-muted"
                    @click="activeTab = 'history'"
                  >
                    {{ t('COMPANIES.DETAIL.ACTIVITY.VIEW_ALL') }}
                  </RelayButton>
                </div>

                <div
                  v-if="recentConversations.length"
                  class="flex flex-col space-y-6"
                >
                  <div
                    v-for="conversation in recentConversations"
                    :key="conversation.id"
                    class="flex gap-4"
                  >
                    <div
                      class="relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary"
                    >
                      <span class="i-lucide-message-square size-4" />
                    </div>
                    <div class="flex w-full flex-col">
                      <div class="flex items-center justify-between">
                        <span class="text-[14px] font-medium text-foreground">
                          {{
                            t('COMPANIES.DETAIL.ACTIVITY.CONVERSATION', {
                              id: conversation.id,
                            })
                          }}
                        </span>
                        <span class="text-[12px] text-muted-foreground">
                          {{
                            conversation.timestamp
                              ? dynamicTime(conversation.timestamp)
                              : ''
                          }}
                        </span>
                      </div>
                      <span class="mt-0.5 text-[13px] text-muted-foreground">
                        {{
                          conversation.meta?.sender?.name ||
                          conversation.meta?.assignee?.name ||
                          emptyValue
                        }}
                      </span>
                    </div>
                  </div>
                </div>
                <p v-else class="text-sm text-muted-foreground">
                  {{ t('COMPANIES.DETAIL.ACTIVITY.EMPTY') }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div
          v-else-if="activeTab === 'contacts'"
          class="overflow-hidden rounded-xl border border-border bg-card outline-none"
        >
          <CompanyContactsSidebar
            :company="company"
            :contacts="companyContacts"
            :meta="companyContactsMeta"
            :is-loading="isFetchingContacts"
            :is-busy="isManagingContacts"
            :search-results="contactSearchResults"
            :is-searching="isSearchingContacts"
            :selected-contact="selectedCandidate"
            @cancel-contact-selection="clearSelectedCandidate"
            @confirm-contact-selection="handleConfirmContactSelection"
            @search="handleContactSearch"
            @select-contact="contact => (selectedCandidate = contact)"
            @remove-contact="handleRemoveContact"
            @update:current-page="loadCompanyContactsPage"
          />
        </div>

        <div
          v-else-if="activeTab === 'history'"
          class="overflow-hidden rounded-xl border border-border bg-card outline-none"
        >
          <CompanyHistorySidebar
            :conversations="companyConversations"
            :is-loading="isFetchingConversations"
          />
        </div>

        <div
          v-else-if="activeTab === 'notes'"
          class="overflow-hidden rounded-xl border border-border bg-card outline-none"
        >
          <CompanyNotesSidebar
            :notes="companyNotes"
            :is-loading="isFetchingNotes"
          />
        </div>
      </div>
    </div>

    <ConfirmCompanyDeleteDialog
      ref="confirmDeleteDialogRef"
      :company="company"
      :is-loading="isDeletingCompany"
      @confirm="handleDeleteCompany"
    />
  </CompaniesDetailsLayout>
</template>
