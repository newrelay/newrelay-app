<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import CompanyAPI from 'dashboard/api/companies';

const { t } = useI18n();

const companies = ref([]);
const isFetching = ref(false);
const searchQuery = ref('');
const isDrawerOpen = ref(false);
const isSaving = ref(false);

const editingCompany = ref(null);
const companyForm = ref({
  name: '',
  phone: '',
  email: '',
  website: '',
  address: '',
  state: '',
  city: '',
  description: '',
});

const fetchCompanies = async () => {
  isFetching.value = true;
  try {
    let response;
    if (searchQuery.value) {
      response = await CompanyAPI.search(searchQuery.value);
    } else {
      response = await CompanyAPI.get();
    }
    companies.value = response.data.payload || [];
  } catch {
    // Ignore error
  } finally {
    isFetching.value = false;
  }
};

const openAddDrawer = () => {
  editingCompany.value = null;
  companyForm.value = {
    name: '',
    phone: '',
    email: '',
    website: '',
    address: '',
    state: '',
    city: '',
    description: '',
  };
  isDrawerOpen.value = true;
};

const openEditDrawer = company => {
  editingCompany.value = company;
  const attrs = company.additional_attributes || {};
  companyForm.value = {
    name: company.name,
    phone: attrs.phone || '',
    email: attrs.email || '',
    website: attrs.website || '',
    address: attrs.address || '',
    state: attrs.state || '',
    city: attrs.city || '',
    description: company.description || '',
  };
  isDrawerOpen.value = true;
};

const closeDrawer = () => {
  isDrawerOpen.value = false;
};

const handleDeleteCompany = async id => {
  if (window.confirm('Are you sure you want to delete this company?')) {
    try {
      await CompanyAPI.delete(id);
      companies.value = companies.value.filter(c => c.id !== id);
    } catch {
      // Ignore error
    }
  }
};

const handleSaveCompany = async (addAnother = false) => {
  isSaving.value = true;
  const website = companyForm.value.website;
  const domain = website
    ? website.replace(/(https?:\/\/)?(www\.)?/, '').split('/')[0]
    : '';

  const payload = {
    name: companyForm.value.name,
    domain: domain,
    description: companyForm.value.description,
    additional_attributes: {
      phone: companyForm.value.phone,
      email: companyForm.value.email,
      website: companyForm.value.website,
      address: companyForm.value.address,
      state: companyForm.value.state,
      city: companyForm.value.city,
    },
  };

  try {
    if (editingCompany.value) {
      await CompanyAPI.update(editingCompany.value.id, payload);
    } else {
      await CompanyAPI.create(payload);
    }
    fetchCompanies();
    if (addAnother) {
      companyForm.value = {
        name: '',
        phone: '',
        email: '',
        website: '',
        address: '',
        state: '',
        city: '',
        description: '',
      };
    } else {
      closeDrawer();
    }
  } catch {
    // Ignore error
  } finally {
    isSaving.value = false;
  }
};

watch(searchQuery, () => {
  fetchCompanies();
});

onMounted(() => {
  fetchCompanies();
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-hidden bg-n-surface-1">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-6 border-b border-n-slate-4 bg-n-surface-1"
    >
      <div class="flex items-center gap-3">
        <span class="text-xl font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.TITLE') }}
        </span>
        <span
          class="px-2 py-0.5 text-xs font-semibold rounded-full bg-n-brand text-white"
        >
          {{
            t('CONTACTS_LAYOUT.COMPANIES_VIEW.COMPANIES_COUNT', {
              count: companies.length,
            })
          }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <Button
          :label="t('CONTACTS_LAYOUT.COMPANIES_VIEW.ADD_COMPANY')"
          icon="i-lucide-plus"
          size="sm"
          @click="openAddDrawer"
        />
      </div>
    </div>

    <!-- Sub-tabs -->
    <div
      class="flex items-center justify-between border-b border-n-slate-4 bg-n-surface-2 px-6 py-2 shrink-0"
    >
      <div class="flex items-center gap-6">
        <button
          class="text-sm font-medium transition-colors hover:text-n-slate-12 px-1 py-1.5 relative cursor-pointer text-n-slate-12 font-semibold"
        >
          {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.TAB_ALL') }}
          <span
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-n-brand rounded-full"
          />
        </button>
        <button
          class="text-sm font-medium text-n-brand hover:underline flex items-center gap-1 cursor-pointer"
        >
          <span class="text-sm">+</span>
          {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.ADD_LIST') }}
        </button>
      </div>
    </div>

    <!-- Filters Row -->
    <div
      class="flex items-center justify-between border-b border-n-slate-4 bg-n-surface-1 px-6 py-3.5 shrink-0 gap-4"
    >
      <div class="flex items-center gap-3">
        <Button
          label="Advanced filters"
          icon="i-lucide-list-filter"
          variant="ghost"
          color="slate"
          size="sm"
        />
        <Button
          label="Sort"
          icon="i-lucide-arrow-up-down"
          variant="ghost"
          color="slate"
          size="sm"
        />
      </div>

      <div class="flex items-center gap-4">
        <div class="relative w-64">
          <Input
            v-model="searchQuery"
            type="search"
            placeholder="Search companies..."
            custom-input-class="h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8 w-full"
          >
            <template #prefix>
              <span
                class="i-lucide-search absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2"
              />
            </template>
          </Input>
        </div>
      </div>
    </div>

    <!-- Data Table -->
    <div class="flex-1 overflow-auto p-6">
      <div v-if="isFetching" class="flex items-center justify-center h-48">
        <Spinner />
      </div>
      <div
        v-else-if="!companies.length"
        class="flex flex-col items-center justify-center h-48 border border-dashed rounded-lg border-n-slate-4"
      >
        <span class="text-n-slate-11 text-sm">
          {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.NO_COMPANIES') }}
        </span>
      </div>
      <div
        v-else
        class="w-full border rounded-lg border-n-slate-4 bg-n-surface-1"
      >
        <table class="w-full text-left border-collapse table-auto">
          <thead>
            <tr
              class="border-b border-n-slate-4 bg-n-slate-2 text-n-slate-11 text-xs font-semibold uppercase tracking-wider"
            >
              <th class="p-3 w-10 text-center">
                <Checkbox />
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_COMPANY') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_PHONE') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_EMAIL') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_WEBSITE') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_ADDRESS') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_STATE') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_CITY') }}
              </th>
              <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_DESCRIPTION') }}
              </th>
              <th class="p-3 w-24 text-center">
                {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.COL_ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-slate-3 text-sm text-n-slate-12">
            <tr
              v-for="company in companies"
              :key="company.id"
              class="hover:bg-n-slate-2 transition-colors cursor-pointer"
              @click="openEditDrawer(company)"
            >
              <td class="p-3 text-center" @click.stop>
                <Checkbox />
              </td>
              <td class="p-3 font-medium flex items-center gap-2">
                <Avatar :name="company.name" :size="24" hide-offline-status />
                <span>{{ company.name }}</span>
              </td>
              <td class="p-3 text-n-slate-11">
                {{ company.additional_attributes?.phone || '-' }}
              </td>
              <td class="p-3 text-n-slate-11 font-mono text-xs">
                {{ company.additional_attributes?.email || '-' }}
              </td>
              <td class="p-3 text-n-slate-11">
                <a
                  v-if="company.additional_attributes?.website"
                  :href="company.additional_attributes.website"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-n-brand hover:underline"
                  @click.stop
                >
                  {{ company.additional_attributes.website }}
                </a>
                <span v-else>-</span>
              </td>
              <td class="p-3 text-n-slate-11">
                {{ company.additional_attributes?.address || '-' }}
              </td>
              <td class="p-3 text-n-slate-11">
                {{ company.additional_attributes?.state || '-' }}
              </td>
              <td class="p-3 text-n-slate-11">
                {{ company.additional_attributes?.city || '-' }}
              </td>
              <td class="p-3 text-n-slate-11 truncate max-w-xs">
                {{ company.description || '-' }}
              </td>
              <td class="p-3 text-center space-x-2" @click.stop>
                <Button
                  icon="i-lucide-pencil"
                  variant="ghost"
                  color="slate"
                  size="xs"
                  @click="openEditDrawer(company)"
                />
                <Button
                  icon="i-lucide-trash"
                  variant="ghost"
                  color="slate"
                  size="xs"
                  class="hover:text-red-600"
                  @click="handleDeleteCompany(company.id)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Add/Edit Company Slide-over Drawer -->
    <div
      v-show="isDrawerOpen"
      class="fixed inset-0 z-[100] flex justify-end bg-n-alpha-black2 backdrop-blur-sm"
      @click.self="closeDrawer"
    >
      <div
        class="w-full max-w-lg h-full bg-n-surface-1 shadow-2xl flex flex-col transition-transform duration-300 transform translate-x-0"
      >
        <!-- Header -->
        <div
          class="p-6 border-b border-n-slate-4 flex items-center justify-between"
        >
          <h2
            class="text-lg font-semibold text-n-slate-12 flex items-center gap-2"
          >
            <span class="i-lucide-plus-circle text-n-brand size-5" />
            {{
              editingCompany
                ? t('CONTACTS_LAYOUT.COMPANIES_VIEW.EDIT_COMPANY')
                : t('CONTACTS_LAYOUT.COMPANIES_VIEW.ADD_NEW_COMPANY')
            }}
          </h2>
          <Button
            icon="i-lucide-x"
            variant="ghost"
            color="slate"
            size="sm"
            @click="closeDrawer"
          />
        </div>

        <!-- Form Content -->
        <div class="flex-1 overflow-y-auto p-6 space-y-6">
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_NAME') }}
              <span class="text-red-500">*</span>
            </label>
            <Input
              v-model="companyForm.name"
              placeholder="Please input company name"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_PHONE') }}
            </label>
            <PhoneNumberInput
              v-model="companyForm.phone"
              placeholder="90123 45678"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_EMAIL') }}
            </label>
            <Input
              v-model="companyForm.email"
              placeholder="Please input"
              class="w-full"
            >
              <template #prefix>
                <span class="i-lucide-mail text-n-slate-9 size-4" />
              </template>
            </Input>
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_WEBSITE') }}
            </label>
            <Input
              v-model="companyForm.website"
              placeholder="Please input"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_ADDRESS') }}
            </label>
            <Input
              v-model="companyForm.address"
              placeholder="Please input"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_STATE') }}
            </label>
            <Input
              v-model="companyForm.state"
              placeholder="Please input"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_CITY') }}
            </label>
            <Input
              v-model="companyForm.city"
              placeholder="Please input"
              class="w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
              {{ t('CONTACTS_LAYOUT.COMPANIES_VIEW.FORM_DESCRIPTION') }}
            </label>
            <textarea
              v-model="companyForm.description"
              placeholder="Please input"
              class="w-full min-h-[80px] p-2 text-sm border rounded-lg border-n-slate-4 bg-transparent text-n-slate-12 outline-none focus:border-n-brand"
            />
          </div>
        </div>

        <!-- Footer -->
        <div
          class="p-6 border-t border-n-slate-4 bg-n-slate-2 flex items-center justify-between shrink-0"
        >
          <Button
            :label="t('CONTACTS_LAYOUT.COMPANIES_VIEW.CANCEL')"
            variant="ghost"
            color="slate"
            @click="closeDrawer"
          />
          <div class="flex items-center gap-3">
            <Button
              :label="t('CONTACTS_LAYOUT.COMPANIES_VIEW.SAVE_ADD_ANOTHER')"
              variant="outline"
              color="slate"
              :is-loading="isSaving"
              @click="handleSaveCompany(true)"
            />
            <Button
              :label="t('CONTACTS_LAYOUT.COMPANIES_VIEW.SAVE')"
              variant="solid"
              :is-loading="isSaving"
              @click="handleSaveCompany(false)"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
