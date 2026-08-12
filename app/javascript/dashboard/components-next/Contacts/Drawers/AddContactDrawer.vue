<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import {
  RelayButton,
  RelayCheckbox,
  RelayInput,
} from 'dashboard/components-next/relay';
import timezones from 'dashboard/routes/dashboard/settings/inbox/helpers/timezones.json';

const emit = defineEmits(['create', 'update']);
const { t } = useI18n();

const agents = useMapGetter('agents/getAgents');
const isOpen = ref(false);
const editId = ref(null);
const existingAdditional = ref({});
const isSaving = ref(false);
const showErrors = ref(false);
const avatarInput = ref(null);
const avatarPreview = ref('');
const moreDetailsOpen = ref(false);
const openMenu = ref(null);
const contactTypeSearch = ref('');
const timeZoneSearch = ref('');

const form = reactive({
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  company: '',
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
  form.company = '';
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
  showErrors.value = false;
  moreDetailsOpen.value = false;
  openMenu.value = null;
  contactTypeSearch.value = '';
  timeZoneSearch.value = '';
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
  form.company = additional.company_name || '';
  form.timezone = additional.timezone || 'Etc/UTC';
  avatarPreview.value = contact.thumbnail || '';
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
  avatarPreview.value = URL.createObjectURL(file);
};

const toggleMenu = key => {
  openMenu.value = openMenu.value === key ? null : key;
};

const selectContactType = value => {
  form.contactType = value;
  openMenu.value = null;
  contactTypeSearch.value = '';
};

const selectTimezone = value => {
  form.timezone = value;
  openMenu.value = null;
  timeZoneSearch.value = '';
};

const selectOwner = name => {
  form.owner = name;
  openMenu.value = null;
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
        company_name: form.company.trim(),
        timezone: form.timezone,
      },
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
    additionalAttributes: {
      companyName: form.company.trim() || undefined,
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
      data-relay
      class="fixed inset-0 z-[60] flex items-center justify-center bg-background/80 p-4 backdrop-blur-sm transition-all duration-300"
      @click.self="close"
    >
      <div
        class="flex max-h-[90vh] w-full max-w-lg animate-in fade-in zoom-in-95 flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl duration-200"
        @click="openMenu = null"
      >
        <!-- Header -->
        <div
          class="flex shrink-0 items-center justify-between border-b border-border p-6"
        >
          <div>
            <h2 class="text-lg font-semibold tracking-tight text-foreground">
              {{ headerTitle }}
            </h2>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ headerSubtitle }}
            </p>
          </div>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 rounded-full text-muted-foreground hover:text-foreground"
            @click="close"
          >
            <span class="i-lucide-x size-4" />
          </RelayButton>
        </div>

        <!-- Body -->
        <div class="hide-scrollbar flex-1 space-y-6 overflow-y-auto p-6">
          <!-- Profile picture -->
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PROFILE_PICTURE') }}
            </label>
            <div class="mb-2 flex items-center gap-4">
              <button
                type="button"
                class="flex size-16 shrink-0 cursor-pointer items-center justify-center overflow-hidden rounded-xl border border-dashed border-border bg-muted/30 transition-colors hover:bg-muted/50"
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
                  class="i-lucide-upload size-5 text-muted-foreground/70"
                />
              </button>
              <div class="flex flex-col gap-1.5">
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="h-8 w-fit text-xs"
                  @click="avatarInput?.click()"
                >
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.UPLOAD_PICTURE') }}
                </RelayButton>
                <span class="text-[11px] text-muted-foreground">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.AVATAR_HINT') }}
                </span>
                <input
                  ref="avatarInput"
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="handleAvatarUpload"
                />
              </div>
            </div>
          </div>

          <!-- Name -->
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
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
                    ? 'h-10 w-full rounded-md border-destructive bg-background px-4 text-[14px] shadow-sm'
                    : 'h-10 w-full rounded-md border-border bg-background px-4 text-[14px] shadow-sm'
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
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
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
                    ? 'h-10 w-full rounded-md border-destructive bg-background px-4 text-[14px] shadow-sm'
                    : 'h-10 w-full rounded-md border-border bg-background px-4 text-[14px] shadow-sm'
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
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
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
                  ? 'h-10 w-full rounded-md border-destructive bg-background px-4 text-[14px] shadow-sm'
                  : 'h-10 w-full rounded-md border-border bg-background px-4 text-[14px] shadow-sm'
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
              class="mt-0.5 flex items-center gap-2"
            >
              <RelayInput
                v-model="additionalEmails[index]"
                type="email"
                :placeholder="
                  t(
                    'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADDITIONAL_EMAIL_PLACEHOLDER'
                  )
                "
                class-name="h-10 flex-1 rounded-md border-border bg-background px-4 text-[14px] shadow-sm"
              />
              <RelayButton
                variant="ghost"
                size="icon"
                class="size-10 shrink-0 text-muted-foreground hover:text-destructive"
                @click="additionalEmails.splice(index, 1)"
              >
                <span class="i-lucide-trash-2 size-4" />
              </RelayButton>
            </div>
            <button
              type="button"
              class="mt-1 flex items-center gap-1 self-start text-[13px] font-medium text-primary transition-colors hover:underline"
              @click="additionalEmails.push('')"
            >
              <span class="i-lucide-plus size-3.5" />
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADD_EMAIL') }}
            </button>
          </div>

          <!-- Phone -->
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PHONE') }}
            </label>
            <RelayInput
              v-model="form.phone"
              type="tel"
              :placeholder="
                t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PHONE_PLACEHOLDER')
              "
              class-name="h-10 w-full rounded-md border-border bg-background px-4 text-[14px] shadow-sm"
            />
            <div
              v-for="(_, index) in additionalPhones"
              :key="`phone-${index}`"
              class="mt-0.5 flex items-center gap-2"
            >
              <RelayInput
                v-model="additionalPhones[index]"
                type="tel"
                :placeholder="
                  t(
                    'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADDITIONAL_PHONE_PLACEHOLDER'
                  )
                "
                class-name="h-10 flex-1 rounded-md border-border bg-background px-4 text-[14px] shadow-sm"
              />
              <RelayButton
                variant="ghost"
                size="icon"
                class="size-10 shrink-0 text-muted-foreground hover:text-destructive"
                @click="additionalPhones.splice(index, 1)"
              >
                <span class="i-lucide-trash-2 size-4" />
              </RelayButton>
            </div>
            <button
              type="button"
              class="mt-1 flex items-center gap-1 self-start text-[13px] font-medium text-primary transition-colors hover:underline"
              @click="additionalPhones.push('')"
            >
              <span class="i-lucide-plus size-3.5" />
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.ADD_PHONE') }}
            </button>
          </div>

          <!-- Company -->
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY') }}
            </label>
            <div class="relative">
              <span
                class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <RelayInput
                v-model="form.company"
                :placeholder="
                  t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMPANY_PLACEHOLDER')
                "
                class-name="h-10 w-full rounded-md border-border bg-background pl-9 pr-4 text-[14px] shadow-sm"
              />
            </div>
          </div>

          <hr class="my-2 border-border" />

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
              <div
                v-on-click-outside="
                  () => openMenu === 'contactType' && (openMenu = null)
                "
                class="relative flex flex-col gap-1.5"
                @click.stop
              >
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CONTACT_TYPE') }}
                </label>
                <RelayButton
                  variant="outline"
                  class="h-10 w-full justify-between rounded-md border-border bg-background px-4 text-[14px] font-normal shadow-sm hover:bg-background"
                  @click="toggleMenu('contactType')"
                >
                  {{ selectedContactTypeLabel }}
                  <span class="i-lucide-chevron-down size-4 opacity-50" />
                </RelayButton>
                <div
                  v-if="openMenu === 'contactType'"
                  class="absolute left-0 top-full z-[70] mt-1 w-full overflow-hidden rounded-md border border-border bg-popover shadow-md"
                >
                  <div class="flex items-center border-b border-border px-3">
                    <span
                      class="i-lucide-search mr-2 size-4 shrink-0 opacity-50"
                    />
                    <input
                      v-model="contactTypeSearch"
                      type="text"
                      :placeholder="
                        t(
                          'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SEARCH_PLACEHOLDER'
                        )
                      "
                      class="h-10 w-full border-0 bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground focus:ring-0"
                    />
                  </div>
                  <div class="max-h-[240px] overflow-y-auto p-1">
                    <button
                      v-for="opt in filteredContactTypes"
                      :key="opt.value"
                      type="button"
                      class="flex w-full cursor-pointer items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent hover:text-accent-foreground"
                      @click="selectContactType(opt.value)"
                    >
                      <span>{{ opt.label }}</span>
                      <span
                        v-if="form.contactType === opt.value"
                        class="i-lucide-check size-4 text-primary"
                      />
                    </button>
                  </div>
                </div>
              </div>

              <!-- Time zone -->
              <div
                v-on-click-outside="
                  () => openMenu === 'timezone' && (openMenu = null)
                "
                class="relative flex flex-col gap-1.5"
                @click.stop
              >
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TIMEZONE') }}
                </label>
                <RelayButton
                  variant="outline"
                  class="h-10 w-full justify-between rounded-md border-border bg-background px-4 text-[14px] font-normal shadow-sm hover:bg-background"
                  @click="toggleMenu('timezone')"
                >
                  <span class="truncate">{{ selectedTimezoneLabel }}</span>
                  <span
                    class="i-lucide-chevron-down size-4 shrink-0 opacity-50"
                  />
                </RelayButton>
                <div
                  v-if="openMenu === 'timezone'"
                  class="absolute left-0 top-full z-[70] mt-1 w-full overflow-hidden rounded-md border border-border bg-popover shadow-md"
                >
                  <div class="flex items-center border-b border-border px-3">
                    <span
                      class="i-lucide-search mr-2 size-4 shrink-0 opacity-50"
                    />
                    <input
                      v-model="timeZoneSearch"
                      type="text"
                      :placeholder="
                        t(
                          'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.SEARCH_PLACEHOLDER'
                        )
                      "
                      class="h-10 w-full border-0 bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground focus:ring-0"
                    />
                  </div>
                  <div class="max-h-[240px] overflow-y-auto p-1">
                    <button
                      v-for="opt in filteredTimezones"
                      :key="opt.value"
                      type="button"
                      class="flex w-full cursor-pointer items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent hover:text-accent-foreground"
                      @click="selectTimezone(opt.value)"
                    >
                      <span class="truncate">{{ opt.label }}</span>
                      <span
                        v-if="form.timezone === opt.value"
                        class="ml-2 i-lucide-check size-4 shrink-0 text-primary"
                      />
                    </button>
                  </div>
                </div>
              </div>

              <!-- Tags -->
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TAGS') }}
                </label>
                <RelayInput
                  v-model="form.tags"
                  :placeholder="
                    t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.TAGS_PLACEHOLDER')
                  "
                  class-name="h-10 w-full rounded-md border-border bg-background px-4 text-[14px] shadow-sm"
                />
              </div>

              <!-- Owner -->
              <div
                v-on-click-outside="
                  () => openMenu === 'owner' && (openMenu = null)
                "
                class="relative flex flex-col gap-1.5"
                @click.stop
              >
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OWNER') }}
                </label>
                <RelayButton
                  variant="outline"
                  class="h-10 w-full justify-between rounded-md border-border bg-background px-4 text-[14px] font-normal shadow-sm hover:bg-background"
                  :class="
                    form.owner ? 'text-foreground' : 'text-muted-foreground'
                  "
                  @click="toggleMenu('owner')"
                >
                  {{
                    form.owner ||
                    t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OWNER_PLACEHOLDER')
                  }}
                  <span class="i-lucide-chevron-down size-4 opacity-50" />
                </RelayButton>
                <div
                  v-if="openMenu === 'owner'"
                  class="absolute left-0 top-full z-[70] mt-1 max-h-48 w-full overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
                >
                  <button
                    type="button"
                    class="flex w-full cursor-pointer items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent"
                    @click="selectOwner('')"
                  >
                    <span>{{
                      t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.OWNER_UNASSIGNED')
                    }}</span>
                    <span
                      v-if="!form.owner"
                      class="i-lucide-check size-4 text-primary"
                    />
                  </button>
                  <button
                    v-for="name in agentNames"
                    :key="`owner-${name}`"
                    type="button"
                    class="flex w-full cursor-pointer items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent"
                    @click="selectOwner(name)"
                  >
                    <span>{{ name }}</span>
                    <span
                      v-if="form.owner === name"
                      class="i-lucide-check size-4 text-primary"
                    />
                  </button>
                </div>
              </div>

              <!-- Communication preferences -->
              <div class="flex flex-col gap-3">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t(
                      'CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.COMMUNICATION_PREFERENCES'
                    )
                  }}
                </label>
                <div class="grid grid-cols-2 gap-3">
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.email" />
                    <span class="text-sm text-foreground">
                      {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_EMAIL') }}
                    </span>
                  </label>
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.sms" />
                    <span class="text-sm text-foreground">
                      {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_SMS') }}
                    </span>
                  </label>
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.whatsapp" />
                    <span class="text-sm text-foreground">
                      {{
                        t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.PREF_WHATSAPP')
                      }}
                    </span>
                  </label>
                  <label class="flex cursor-pointer items-center gap-3">
                    <RelayCheckbox v-model="form.prefs.marketingEmails" />
                    <span class="text-sm text-foreground">
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
          class="mt-auto flex shrink-0 gap-3 border-t border-border bg-muted/10 p-6"
        >
          <RelayButton
            variant="outline"
            class="w-full text-sm font-medium"
            @click="close"
          >
            {{ t('CONTACTS_LAYOUT.ADD_CONTACT_DRAWER.CANCEL') }}
          </RelayButton>
          <div class="w-full" @click="handleDisabledSubmitClick">
            <RelayButton
              class="w-full text-sm font-medium"
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
