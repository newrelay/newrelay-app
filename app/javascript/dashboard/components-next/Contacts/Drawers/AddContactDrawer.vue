<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store';
import CompanyAPI from 'dashboard/api/companies';
import {
  RelayButton,
  RelayCheckbox,
  RelayInput,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
  DROPDOWN_MENU_SEARCH_HEADER_CLASS,
  DROPDOWN_MENU_SEARCH_WRAPPER_CLASS,
  DROPDOWN_MENU_SEARCH_ICON_CLASS,
  DROPDOWN_MENU_SEARCH_INPUT_CLASS,
  DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS,
  DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS,
  DROPDOWN_MENU_MODAL_CONTENT_CLASS,
} from 'dashboard/components-next/relay';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';
import { RELAY_MODAL_BODY_CLASS } from 'dashboard/components-next/relay/modal/constants';
import timezones from 'dashboard/routes/dashboard/settings/inbox/helpers/timezones.json';

const emit = defineEmits(['create', 'update']);
const FORM_INPUT_CLASS =
  'h-9 w-full px-3 text-[14px] placeholder:text-muted-foreground/60 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';
const FORM_INPUT_ERROR_CLASS = 'border-destructive';
const DROPDOWN_TRIGGER_CLASS =
  'h-9 w-full justify-between rounded-md border border-border/80 bg-background px-4 text-[14px] font-normal text-foreground shadow-sm hover:bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30';
const MODAL_DROPDOWN_ITEM_CLASS =
  'flex cursor-default items-center justify-between rounded-sm px-3 py-2 text-[14px] text-foreground transition-colors hover:bg-accent hover:text-accent-foreground data-[highlighted]:bg-accent data-[highlighted]:text-accent-foreground';
const REMOVE_FIELD_BUTTON_CLASS =
  'flex size-10 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive';
const ADD_FIELD_BUTTON_CLASS =
  'flex w-fit cursor-pointer items-center gap-1.5 p-0 text-[13px] font-medium text-primary hover:underline';

const { t } = useI18n();

const agents = useMapGetter('agents/getAgents');
const modalPanelRef = ref(null);
const isOpen = ref(false);
const editId = ref(null);
const existingAdditional = ref({});
const isSaving = ref(false);
const showErrors = ref(false);
const avatarInput = ref(null);
const avatarPreview = ref('');
const avatarFile = ref(null);
const moreDetailsOpen = ref(false);
const contactTypeSearch = ref('');
const timeZoneSearch = ref('');
const companySearch = ref('');
const companyOptions = ref([]);
const isSearchingCompanies = ref(false);
const selectedCompany = ref(null);
const previousCompanyId = ref(null);

const form = reactive({
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  contactType: 'lead',
  timezone: 'Etc/UTC',
  tags: '',
  owner: '',
  prefs: {
    email: true,
    sms: true,
    whatsapp: true,
    marketingEmails: false,
  },
});

const additionalEmails = ref([]);
const additionalPhones = ref([]);

const contactTypeOptions = computed(() => [
  {
    label: t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CONTACT_TYPES.VISITOR'),
    value: 'visitor',
  },
  {
    label: t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CONTACT_TYPES.LEAD'),
    value: 'lead',
  },
  {
    label: t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CONTACT_TYPES.CUSTOMER'),
    value: 'customer',
  },
]);

const timezoneOptions = computed(() =>
  Object.entries(timezones).map(([label, value]) => ({ label, value }))
);

const filteredContactTypes = computed(() => {
  const q = contactTypeSearch.value.trim().toLowerCase();
  if (!q) return contactTypeOptions.value;
  return contactTypeOptions.value.filter(opt =>
    opt.label.toLowerCase().includes(q)
  );
});

const filteredTimezones = computed(() => {
  const q = timeZoneSearch.value.trim().toLowerCase();
  if (!q) return timezoneOptions.value;
  return timezoneOptions.value.filter(opt =>
    opt.label.toLowerCase().includes(q)
  );
});

const agentNames = computed(() =>
  (agents.value || []).map(agent => agent.name).filter(Boolean)
);

const selectedContactTypeLabel = computed(
  () =>
    contactTypeOptions.value.find(opt => opt.value === form.contactType)
      ?.label || form.contactType
);

const selectedTimezoneLabel = computed(
  () =>
    timezoneOptions.value.find(opt => opt.value === form.timezone)?.label ||
    form.timezone
);

const isEditMode = computed(() => editId.value !== null);

const isFormValid = computed(
  () =>
    form.firstName.trim() !== '' &&
    (isEditMode.value || form.lastName.trim() !== '') &&
    form.email.trim() !== ''
);

const headerTitle = computed(() =>
  isEditMode.value
    ? t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EDIT_TITLE')
    : t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TITLE')
);

const headerSubtitle = computed(() =>
  isEditMode.value
    ? t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EDIT_SUBTITLE')
    : t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SUBTITLE')
);

const submitLabel = computed(() =>
  isEditMode.value
    ? t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.UPDATE')
    : t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CREATE')
);

const resetForm = () => {
  form.firstName = '';
  form.lastName = '';
  form.email = '';
  form.phone = '';
  form.contactType = 'lead';
  form.timezone = 'Etc/UTC';
  form.tags = '';
  form.owner = '';
  form.prefs.email = true;
  form.prefs.sms = true;
  form.prefs.whatsapp = true;
  form.prefs.marketingEmails = false;
  additionalEmails.value = [];
  additionalPhones.value = [];
  avatarPreview.value = '';
  avatarFile.value = null;
  showErrors.value = false;
  moreDetailsOpen.value = false;
  contactTypeSearch.value = '';
  timeZoneSearch.value = '';
  companySearch.value = '';
  companyOptions.value = [];
  selectedCompany.value = null;
  previousCompanyId.value = null;
  editId.value = null;
  existingAdditional.value = {};
  if (avatarInput.value) avatarInput.value.value = '';
};

const prefillFromContact = contact => {
  const additional = contact.additional_attributes || {};
  existingAdditional.value = additional;
  editId.value = contact.id;
  const parts = (contact.name || '').trim().split(' ');
  form.firstName = parts.shift() || '';
  form.lastName = parts.join(' ');
  form.email = contact.email || '';
  form.phone = contact.phone_number || '';
  form.timezone = additional.timezone || 'Etc/UTC';
  avatarPreview.value = contact.thumbnail || '';
  selectedCompany.value = contact.company || null;
  previousCompanyId.value = contact.company?.id ?? null;
};

const open = contact => {
  resetForm();
  if (contact && contact.id) prefillFromContact(contact);
  isOpen.value = true;
};

const close = () => {
  if (!isOpen.value) return;
  isOpen.value = false;
  resetForm();
};

const handleAvatarUpload = event => {
  const file = event.target?.files?.[0];
  if (!file) return;
  avatarFile.value = file;
  avatarPreview.value = URL.createObjectURL(file);
};

const avatarPayload = () =>
  avatarFile.value ? { avatar: avatarFile.value, isFormData: true } : {};

const selectContactType = value => {
  form.contactType = value;
  contactTypeSearch.value = '';
};

const selectTimezone = value => {
  form.timezone = value;
  timeZoneSearch.value = '';
};

const selectOwner = name => {
  form.owner = name;
};

const runCompanySearch = async query => {
  if (!query) {
    companyOptions.value = [];
    return;
  }
  isSearchingCompanies.value = true;
  try {
    const {
      data: { payload },
    } = await CompanyAPI.search(query);
    companyOptions.value = payload;
  } finally {
    isSearchingCompanies.value = false;
  }
};

const debouncedCompanySearch = debounce(runCompanySearch, 300);

const handleCompanySearchInput = value => {
  companySearch.value = value;
  selectedCompany.value = null;
  debouncedCompanySearch(value.trim());
};

const selectCompany = company => {
  selectedCompany.value = company;
  companySearch.value = '';
  companyOptions.value = [];
};

const clearSelectedCompany = () => {
  selectedCompany.value = null;
};

const handleDisabledSubmitClick = () => {
  if (!isFormValid.value) showErrors.value = true;
};

const handleSubmit = async () => {
  if (!isFormValid.value) {
    showErrors.value = true;
    return;
  }

  isSaving.value = true;

  const name = `${form.firstName.trim()} ${form.lastName.trim()}`.trim();

  if (isEditMode.value) {
    emit('update', {
      id: editId.value,
      name,
      email: form.email.trim(),
      phone_number: form.phone.trim(),
      additional_attributes: {
        ...existingAdditional.value,
        timezone: form.timezone,
      },
      companyId: selectedCompany.value?.id ?? null,
      previousCompanyId: previousCompanyId.value,
      ...avatarPayload(),
    });
    isSaving.value = false;
    close();
    return;
  }

  const emails = [
    form.email.trim(),
    ...additionalEmails.value.map(e => e.trim()).filter(Boolean),
  ];
  const phones = [
    form.phone.trim(),
    ...additionalPhones.value.map(p => p.trim()).filter(Boolean),
  ].filter(Boolean);

  emit('create', {
    name: `${form.firstName.trim()} ${form.lastName.trim()}`.trim(),
    email: form.email.trim(),
    phoneNumber: form.phone.trim() || undefined,
    companyId: selectedCompany.value?.id ?? undefined,
    additionalAttributes: {
      emails,
      phoneNumbers: phones,
      timezone: form.timezone,
      contactType: form.contactType,
      tags: form.tags.trim() || undefined,
      owner: form.owner.trim() || undefined,
      communicationPreferences: {
        email: form.prefs.email,
        sms: form.prefs.sms,
        whatsapp: form.prefs.whatsapp,
        marketingEmails: form.prefs.marketingEmails,
      },
      dndSettings: {
        email: !form.prefs.email,
        sms: !form.prefs.sms,
        calls: false,
        inbound: false,
      },
    },
    ...avatarPayload(),
  });

  isSaving.value = false;
  close();
};

defineExpose({ open, close });
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="flex items-center justify-center p-4 transition-all duration-300"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="close"
    >
      <div
        ref="modalPanelRef"
        data-relay
        class="font-geist relative flex max-h-[90vh] w-full max-w-lg animate-in fade-in zoom-in-95 flex-col overflow-hidden rounded-xl border border-border/80 bg-background shadow-xl duration-200"
      >
        <!-- Header -->
        <RelayModalHeader
          :title="headerTitle"
          :description="headerSubtitle"
          @close="close"
        />

        <!-- Body -->
        <div class="hide-scrollbar space-y-6" :class="[RELAY_MODAL_BODY_CLASS]">
          <!-- Profile picture -->
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PROFILE_PICTURE') }}
            </label>
            <div class="flex items-center gap-4">
              <button
                type="button"
                class="flex size-16 shrink-0 cursor-pointer items-center justify-center overflow-hidden rounded-xl border border-dashed border-border/80 bg-muted/30 transition-colors hover:bg-accent"
                @click="avatarInput?.click()"
              >
                <img
                  v-if="avatarPreview"
                  :src="avatarPreview"
                  alt=""
                  class="size-full object-cover"
                />
                <span
                  v-else
                  class="i-lucide-upload size-6 text-muted-foreground/70"
                  aria-hidden="true"
                />
              </button>
              <div class="flex flex-col gap-1.5">
                <button
                  type="button"
                  class="inline-flex h-8 w-fit items-center justify-center rounded-md border border-input bg-background px-3 text-xs font-medium shadow-xs transition-colors hover:border-transparent hover:bg-accent hover:text-accent-foreground"
                  @click="avatarInput?.click()"
                >
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.UPLOAD_PICTURE') }}
                </button>
                <span class="text-[11px] text-muted-foreground">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.AVATAR_HINT') }}
                </span>
                <input
                  ref="avatarInput"
                  type="file"
                  accept="image/*"
                  class="hidden text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
                  @change="handleAvatarUpload"
                />
              </div>
            </div>
          </div>

          <!-- Name -->
          <div class="grid grid-cols-2 gap-4">
            <div :class="RELAY_FORM_FIELD_CLASS">
              <label :class="RELAY_FORM_LABEL_CLASS">
                {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.FIRST_NAME') }}
                <span class="text-destructive">{{
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.REQUIRED_MARK')
                }}</span>
              </label>
              <RelayInput
                v-model="form.firstName"
                :placeholder="
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.FIRST_NAME_PLACEHOLDER')
                "
                :class-name="
                  showErrors && !form.firstName.trim()
                    ? `${FORM_INPUT_CLASS} ${FORM_INPUT_ERROR_CLASS}`
                    : FORM_INPUT_CLASS
                "
                @update:model-value="showErrors = false"
              />
              <span
                v-if="showErrors && !form.firstName.trim()"
                class="text-[12px] text-destructive"
              >
                {{
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.FIRST_NAME_REQUIRED')
                }}
              </span>
            </div>
            <div :class="RELAY_FORM_FIELD_CLASS">
              <label :class="RELAY_FORM_LABEL_CLASS">
                {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.LAST_NAME') }}
                <span class="text-destructive">{{
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.REQUIRED_MARK')
                }}</span>
              </label>
              <RelayInput
                v-model="form.lastName"
                :placeholder="
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.LAST_NAME_PLACEHOLDER')
                "
                :class-name="
                  showErrors && !form.lastName.trim()
                    ? `${FORM_INPUT_CLASS} ${FORM_INPUT_ERROR_CLASS}`
                    : FORM_INPUT_CLASS
                "
                @update:model-value="showErrors = false"
              />
              <span
                v-if="showErrors && !form.lastName.trim()"
                class="text-[12px] text-destructive"
              >
                {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.LAST_NAME_REQUIRED') }}
              </span>
            </div>
          </div>

          <!-- Email -->
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EMAIL') }}
              <span class="text-destructive">{{
                t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.REQUIRED_MARK')
              }}</span>
            </label>
            <RelayInput
              v-model="form.email"
              type="email"
              :placeholder="
                t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EMAIL_PLACEHOLDER')
              "
              :class-name="
                showErrors && !form.email.trim()
                  ? `${FORM_INPUT_CLASS} ${FORM_INPUT_ERROR_CLASS}`
                  : FORM_INPUT_CLASS
              "
              @update:model-value="showErrors = false"
            />
            <span
              v-if="showErrors && !form.email.trim()"
              class="text-[12px] text-destructive"
            >
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.EMAIL_REQUIRED') }}
            </span>
            <div
              v-for="(_, index) in additionalEmails"
              :key="`email-${index}`"
              class="flex items-center gap-3"
            >
              <RelayInput
                v-model="additionalEmails[index]"
                type="email"
                :placeholder="
                  t(
                    'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADDITIONAL_EMAIL_PLACEHOLDER'
                  )
                "
                class-name="h-10 flex-1 px-3 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
              />
              <button
                type="button"
                :class="REMOVE_FIELD_BUTTON_CLASS"
                @click="additionalEmails.splice(index, 1)"
              >
                <span class="i-lucide-trash-2 size-4" />
              </button>
            </div>
            <button
              type="button"
              :class="ADD_FIELD_BUTTON_CLASS"
              @click="additionalEmails.push('')"
            >
              <span class="i-lucide-plus size-3.5" />
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADD_EMAIL') }}
            </button>
          </div>

          <!-- Phone -->
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PHONE') }}
            </label>
            <RelayInput
              v-model="form.phone"
              type="tel"
              :placeholder="
                t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PHONE_PLACEHOLDER')
              "
              :class-name="FORM_INPUT_CLASS"
            />
            <div
              v-for="(_, index) in additionalPhones"
              :key="`phone-${index}`"
              class="flex items-center gap-3"
            >
              <RelayInput
                v-model="additionalPhones[index]"
                type="tel"
                :placeholder="
                  t(
                    'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADDITIONAL_PHONE_PLACEHOLDER'
                  )
                "
                class-name="h-10 flex-1 px-3 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
              />
              <button
                type="button"
                :class="REMOVE_FIELD_BUTTON_CLASS"
                @click="additionalPhones.splice(index, 1)"
              >
                <span class="i-lucide-trash-2 size-4" />
              </button>
            </div>
            <button
              type="button"
              :class="ADD_FIELD_BUTTON_CLASS"
              @click="additionalPhones.push('')"
            >
              <span class="i-lucide-plus size-3.5" />
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADD_PHONE') }}
            </button>
          </div>

          <!-- Company -->
          <div :class="[RELAY_FORM_FIELD_CLASS]">
            <label :class="RELAY_FORM_LABEL_CLASS">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY') }}
            </label>
            <div
              v-if="selectedCompany"
              class="flex h-10 w-full items-center justify-between rounded-md border border-border/80 bg-background px-3 text-[14px]"
            >
              <span class="truncate text-foreground">{{
                selectedCompany.name
              }}</span>
              <button
                type="button"
                :class="REMOVE_FIELD_BUTTON_CLASS"
                class="!size-6"
                :aria-label="
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY_REMOVE')
                "
                @click="clearSelectedCompany"
              >
                <span class="i-lucide-x size-3.5" />
              </button>
            </div>
            <RelayDropdownMenu v-else :modal="false">
              <RelayDropdownMenuTrigger as-child>
                <RelayButton
                  variant="outline"
                  class="text-muted-foreground"
                  :class="[DROPDOWN_TRIGGER_CLASS]"
                >
                  {{
                    t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY_PLACEHOLDER')
                  }}
                  <span class="i-lucide-search size-4 opacity-50" />
                </RelayButton>
              </RelayDropdownMenuTrigger>
              <RelayDropdownMenuContent
                align="start"
                :portal-to="modalPanelRef"
                :collision-boundary="modalPanelRef"
                :collision-padding="12"
                :class="DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS"
              >
                <div :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
                  <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
                    <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
                    <input
                      :value="companySearch"
                      type="text"
                      data-slot="input"
                      :placeholder="
                        t(
                          'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY_SEARCH_PLACEHOLDER'
                        )
                      "
                      :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
                      @input="handleCompanySearchInput($event.target.value)"
                    />
                  </div>
                </div>
                <div :class="DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS">
                  <div
                    v-if="!companySearch.trim()"
                    class="px-3 py-2 text-sm text-muted-foreground"
                  >
                    {{
                      t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY_INITIAL')
                    }}
                  </div>
                  <div
                    v-else-if="isSearchingCompanies"
                    class="px-3 py-2 text-sm text-muted-foreground"
                  >
                    {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SEARCHING') }}
                  </div>
                  <div
                    v-else-if="!companyOptions.length"
                    class="px-3 py-2 text-sm text-muted-foreground"
                  >
                    {{
                      t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY_NOT_FOUND')
                    }}
                  </div>
                  <RelayDropdownMenuItem
                    v-for="company in companyOptions"
                    :key="company.id"
                    :class="MODAL_DROPDOWN_ITEM_CLASS"
                    @click="selectCompany(company)"
                  >
                    <span class="truncate">{{ company.name }}</span>
                  </RelayDropdownMenuItem>
                </div>
              </RelayDropdownMenuContent>
            </RelayDropdownMenu>
          </div>

          <hr class="my-6 border-border/50" />

          <!-- More details -->
          <div>
            <button
              type="button"
              class="mb-4 flex w-full cursor-pointer items-center justify-between text-sm font-medium text-foreground outline-none transition-colors hover:text-primary"
              @click="moreDetailsOpen = !moreDetailsOpen"
            >
              <span class="flex items-center gap-2">
                <span
                  class="i-lucide-chevron-down size-4 transition-transform duration-200"
                  :class="{ '-rotate-180': moreDetailsOpen }"
                />
                {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.MORE_DETAILS') }}
              </span>
            </button>

            <div v-if="moreDetailsOpen" class="space-y-6 pb-2 pt-2">
              <!-- Contact type -->
              <div :class="RELAY_FORM_FIELD_CLASS">
                <label :class="RELAY_FORM_LABEL_CLASS">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CONTACT_TYPE') }}
                </label>
                <RelayDropdownMenu :modal="false">
                  <RelayDropdownMenuTrigger as-child>
                    <RelayButton
                      variant="outline"
                      :class="DROPDOWN_TRIGGER_CLASS"
                    >
                      {{ selectedContactTypeLabel }}
                      <span class="i-lucide-chevron-down size-4 opacity-50" />
                    </RelayButton>
                  </RelayDropdownMenuTrigger>
                  <RelayDropdownMenuContent
                    align="start"
                    :portal-to="modalPanelRef"
                    :collision-boundary="modalPanelRef"
                    :collision-padding="12"
                    :class="DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS"
                  >
                    <div :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
                      <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
                        <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
                        <input
                          v-model="contactTypeSearch"
                          type="text"
                          data-slot="input"
                          :placeholder="
                            t(
                              'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SEARCH_PLACEHOLDER'
                            )
                          "
                          :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
                        />
                      </div>
                    </div>
                    <div :class="DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS">
                      <RelayDropdownMenuItem
                        v-for="opt in filteredContactTypes"
                        :key="opt.value"
                        :class="[
                          MODAL_DROPDOWN_ITEM_CLASS,
                          form.contactType === opt.value ? 'font-medium' : '',
                        ]"
                        @click="selectContactType(opt.value)"
                      >
                        <span>{{ opt.label }}</span>
                        <span
                          v-if="form.contactType === opt.value"
                          class="i-lucide-check size-4 text-primary"
                        />
                      </RelayDropdownMenuItem>
                    </div>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>
              </div>

              <!-- Time zone -->
              <div :class="RELAY_FORM_FIELD_CLASS">
                <label :class="RELAY_FORM_LABEL_CLASS">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TIMEZONE') }}
                </label>
                <RelayDropdownMenu :modal="false">
                  <RelayDropdownMenuTrigger as-child>
                    <RelayButton
                      variant="outline"
                      :class="DROPDOWN_TRIGGER_CLASS"
                    >
                      <span class="truncate">{{ selectedTimezoneLabel }}</span>
                      <span
                        class="i-lucide-chevron-down size-4 shrink-0 opacity-50"
                      />
                    </RelayButton>
                  </RelayDropdownMenuTrigger>
                  <RelayDropdownMenuContent
                    align="start"
                    :portal-to="modalPanelRef"
                    :collision-boundary="modalPanelRef"
                    :collision-padding="12"
                    :class="DROPDOWN_MENU_MODAL_SEARCHABLE_CONTENT_CLASS"
                  >
                    <div :class="DROPDOWN_MENU_SEARCH_HEADER_CLASS">
                      <div :class="DROPDOWN_MENU_SEARCH_WRAPPER_CLASS">
                        <span :class="DROPDOWN_MENU_SEARCH_ICON_CLASS" />
                        <input
                          v-model="timeZoneSearch"
                          type="text"
                          data-slot="input"
                          :placeholder="
                            t(
                              'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SEARCH_PLACEHOLDER'
                            )
                          "
                          :class="DROPDOWN_MENU_SEARCH_INPUT_CLASS"
                        />
                      </div>
                    </div>
                    <div :class="DROPDOWN_MENU_MODAL_SEARCHABLE_LIST_CLASS">
                      <RelayDropdownMenuItem
                        v-for="opt in filteredTimezones"
                        :key="opt.value"
                        :class="[
                          MODAL_DROPDOWN_ITEM_CLASS,
                          form.timezone === opt.value ? 'font-medium' : '',
                        ]"
                        @click="selectTimezone(opt.value)"
                      >
                        <span class="truncate">{{ opt.label }}</span>
                        <span
                          v-if="form.timezone === opt.value"
                          class="i-lucide-check ml-2 size-4 shrink-0 text-primary"
                        />
                      </RelayDropdownMenuItem>
                    </div>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>
              </div>

              <!-- Tags -->
              <div :class="RELAY_FORM_FIELD_CLASS">
                <label :class="RELAY_FORM_LABEL_CLASS">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TAGS') }}
                </label>
                <RelayInput
                  v-model="form.tags"
                  :placeholder="
                    t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TAGS_PLACEHOLDER')
                  "
                  :class-name="FORM_INPUT_CLASS"
                />
              </div>

              <!-- Owner -->
              <div :class="RELAY_FORM_FIELD_CLASS">
                <label :class="RELAY_FORM_LABEL_CLASS">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OWNER') }}
                </label>
                <RelayDropdownMenu :modal="false">
                  <RelayDropdownMenuTrigger as-child>
                    <RelayButton
                      variant="outline"
                      :class="[
                        DROPDOWN_TRIGGER_CLASS,
                        form.owner
                          ? 'text-foreground'
                          : 'text-muted-foreground',
                      ]"
                    >
                      {{
                        form.owner ||
                        t(
                          'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OWNER_PLACEHOLDER'
                        )
                      }}
                      <span class="i-lucide-chevron-down size-4 opacity-50" />
                    </RelayButton>
                  </RelayDropdownMenuTrigger>
                  <RelayDropdownMenuContent
                    align="start"
                    :portal-to="modalPanelRef"
                    :collision-boundary="modalPanelRef"
                    :collision-padding="12"
                    :class="DROPDOWN_MENU_MODAL_CONTENT_CLASS"
                  >
                    <RelayDropdownMenuItem
                      :class="MODAL_DROPDOWN_ITEM_CLASS"
                      @click="selectOwner('')"
                    >
                      <span>{{
                        t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OWNER_UNASSIGNED')
                      }}</span>
                      <span
                        v-if="!form.owner"
                        class="i-lucide-check size-4 text-primary"
                      />
                    </RelayDropdownMenuItem>
                    <RelayDropdownMenuItem
                      v-for="name in agentNames"
                      :key="`owner-${name}`"
                      :class="[
                        MODAL_DROPDOWN_ITEM_CLASS,
                        form.owner === name ? 'font-medium' : '',
                      ]"
                      @click="selectOwner(name)"
                    >
                      <span>{{ name }}</span>
                      <span
                        v-if="form.owner === name"
                        class="i-lucide-check size-4 text-primary"
                      />
                    </RelayDropdownMenuItem>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>
              </div>

              <!-- Communication preferences -->
              <div :class="RELAY_FORM_FIELD_CLASS">
                <label :class="RELAY_FORM_LABEL_CLASS">
                  {{
                    t(
                      'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMMUNICATION_PREFERENCES'
                    )
                  }}
                </label>
                <div class="grid grid-cols-2 gap-x-6 gap-y-3">
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.email" />
                    <span class="text-[13.5px] font-medium text-foreground">
                      {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_EMAIL') }}
                    </span>
                  </label>
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.sms" />
                    <span class="text-[13.5px] font-medium text-foreground">
                      {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_SMS') }}
                    </span>
                  </label>
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.whatsapp" />
                    <span class="text-[13.5px] font-medium text-foreground">
                      {{
                        t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_WHATSAPP')
                      }}
                    </span>
                  </label>
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.marketingEmails" />
                    <span class="text-[13.5px] font-medium text-foreground">
                      {{
                        t(
                          'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_MARKETING_EMAILS'
                        )
                      }}
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div
          class="mt-auto flex shrink-0 gap-3 border-t border-border/80 p-6 pt-5"
        >
          <RelayButton
            type="button"
            variant="ghost"
            class="h-10 flex-1 rounded-xl border border-border bg-background text-[14px] font-medium shadow-sm transition-all hover:border-transparent hover:bg-accent"
            @click="close"
          >
            {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CANCEL') }}
          </RelayButton>
          <div class="flex-1" @click="handleDisabledSubmitClick">
            <RelayButton
              type="button"
              class="h-10 w-full rounded-xl text-[14px] font-medium shadow-sm"
              :class="
                !isFormValid || isSaving
                  ? 'cursor-not-allowed bg-primary/50 text-primary-foreground opacity-50 hover:bg-primary/50'
                  : 'bg-primary text-primary-foreground hover:bg-primary/90'
              "
              :disabled="!isFormValid || isSaving"
              @click="handleSubmit"
            >
              {{ submitLabel }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
