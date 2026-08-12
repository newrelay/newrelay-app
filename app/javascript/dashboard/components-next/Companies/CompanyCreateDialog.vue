<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['create']);
const { t } = useI18n();

const agents = useMapGetter('agents/getAgents');
const isOpen = ref(false);
const showErrors = ref(false);
const logoInput = ref(null);
const logoPreview = ref('');
const openMenu = ref(null);

const form = reactive({
  name: '',
  phone: '',
  email: '',
  website: '',
  address: '',
  state: '',
  city: '',
  description: '',
  owner: '',
  members: '',
});

const isFormValid = computed(() => form.name.trim() !== '');

const agentNames = computed(() =>
  (agents.value || []).map(agent => agent.name).filter(Boolean)
);

const resetForm = () => {
  form.name = '';
  form.phone = '';
  form.email = '';
  form.website = '';
  form.address = '';
  form.state = '';
  form.city = '';
  form.description = '';
  form.owner = '';
  form.members = '';
  logoPreview.value = '';
  showErrors.value = false;
  openMenu.value = null;
};

const open = () => {
  isOpen.value = true;
};

const close = () => {
  isOpen.value = false;
  resetForm();
};

const handleLogoUpload = event => {
  const file = event.target?.files?.[0];
  if (!file) return;
  logoPreview.value = URL.createObjectURL(file);
};

const domainFromWebsite = website => {
  if (!website?.trim()) return null;
  return website
    .replace(/(https?:\/\/)?(www\.)?/i, '')
    .split('/')[0]
    .trim();
};

const handleDisabledSubmitClick = () => {
  if (!isFormValid.value) showErrors.value = true;
};

const handleSubmit = () => {
  if (!isFormValid.value) {
    showErrors.value = true;
    return;
  }

  emit('create', {
    name: form.name.trim(),
    domain: domainFromWebsite(form.website),
    description: form.description.trim() || null,
    additionalAttributes: {
      phone: form.phone.trim() || undefined,
      email: form.email.trim() || undefined,
      website: form.website.trim() || undefined,
      address: form.address.trim() || undefined,
      state: form.state.trim() || undefined,
      city: form.city.trim() || undefined,
      owner: form.owner.trim() || undefined,
      members: form.members.trim() || undefined,
    },
  });
};

const onSuccess = () => {
  resetForm();
  close();
};

const toggleMenu = key => {
  openMenu.value = openMenu.value === key ? null : key;
};

const selectAgent = (field, name) => {
  form[field] = name;
  openMenu.value = null;
};

const dialogRef = {
  open,
  close,
};

defineExpose({ dialogRef, open, close, onSuccess });
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
        class="flex max-h-[90vh] w-full max-w-2xl animate-in fade-in zoom-in-95 flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl duration-200"
        @click="openMenu = null"
      >
        <div
          class="flex shrink-0 items-center justify-between border-b border-border p-6"
        >
          <div>
            <h2 class="text-lg font-semibold tracking-tight text-foreground">
              {{ t('COMPANIES.CREATE.TITLE') }}
            </h2>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ t('COMPANIES.CREATE.SUBTITLE') }}
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

        <div
          class="hide-scrollbar grid flex-1 grid-cols-2 gap-x-6 gap-y-5 overflow-y-auto p-6"
        >
          <div class="col-span-2 flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.LOGO') }}
            </label>
            <div class="mb-2 flex items-center gap-4">
              <button
                type="button"
                class="flex size-16 shrink-0 cursor-pointer items-center justify-center overflow-hidden rounded-xl border border-dashed border-border bg-muted/30 transition-colors hover:bg-muted/50"
                @click="logoInput?.click()"
              >
                <img
                  v-if="logoPreview"
                  :src="logoPreview"
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
                  @click="logoInput?.click()"
                >
                  {{ t('COMPANIES.CREATE.ACTIONS.UPLOAD_LOGO') }}
                </RelayButton>
                <span class="text-[11px] text-muted-foreground">
                  {{ t('COMPANIES.CREATE.LOGO_HINT') }}
                </span>
                <input
                  ref="logoInput"
                  type="file"
                  accept="image/*"
                  class="hidden"
                  @change="handleLogoUpload"
                />
              </div>
            </div>
          </div>

          <div class="col-span-2 flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.NAME') }}
              <span class="text-destructive">{{
                t('COMPANIES.CREATE.REQUIRED_MARK')
              }}</span>
            </label>
            <RelayInput
              v-model="form.name"
              :placeholder="t('COMPANIES.CREATE.FIELDS.NAME_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
              @update:model-value="showErrors = false"
            />
            <p
              v-if="showErrors && !form.name.trim()"
              class="mt-1 text-[12px] text-destructive"
            >
              {{ t('COMPANIES.CREATE.NAME_REQUIRED') }}
            </p>
          </div>

          <div
            v-on-click-outside="() => openMenu === 'owner' && (openMenu = null)"
            class="relative flex flex-col gap-1.5"
            @click.stop
          >
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.OWNER') }}
            </label>
            <RelayButton
              variant="outline"
              class="h-10 w-full justify-between rounded-md border-border bg-background px-3 text-[14px] font-normal shadow-sm"
              :class="form.owner ? 'text-foreground' : 'text-muted-foreground'"
              :disabled="isLoading"
              @click="toggleMenu('owner')"
            >
              {{ form.owner || t('COMPANIES.CREATE.FIELDS.OWNER_PLACEHOLDER') }}
              <span class="i-lucide-chevron-down size-4 opacity-50" />
            </RelayButton>
            <div
              v-if="openMenu === 'owner'"
              class="absolute left-0 top-full z-[70] mt-1 max-h-48 w-full min-w-[240px] overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
            >
              <button
                v-for="name in agentNames"
                :key="`owner-${name}`"
                type="button"
                class="flex w-full cursor-pointer items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent"
                @click="selectAgent('owner', name)"
              >
                <span>{{ name }}</span>
                <span
                  v-if="form.owner === name"
                  class="i-lucide-check size-4 text-primary"
                />
              </button>
              <p
                v-if="!agentNames.length"
                class="px-2 py-1.5 text-sm text-muted-foreground"
              >
                {{ t('COMPANIES.CREATE.FIELDS.OWNER_PLACEHOLDER') }}
              </p>
            </div>
          </div>

          <div
            v-on-click-outside="
              () => openMenu === 'members' && (openMenu = null)
            "
            class="relative flex flex-col gap-1.5"
            @click.stop
          >
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.MEMBERS') }}
            </label>
            <RelayButton
              variant="outline"
              class="h-10 w-full justify-between rounded-md border-border bg-background px-3 text-[14px] font-normal shadow-sm"
              :class="
                form.members ? 'text-foreground' : 'text-muted-foreground'
              "
              :disabled="isLoading"
              @click="toggleMenu('members')"
            >
              {{
                form.members || t('COMPANIES.CREATE.FIELDS.MEMBERS_PLACEHOLDER')
              }}
              <span class="i-lucide-chevron-down size-4 opacity-50" />
            </RelayButton>
            <div
              v-if="openMenu === 'members'"
              class="absolute left-0 top-full z-[70] mt-1 max-h-48 w-full min-w-[240px] overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
            >
              <button
                v-for="name in agentNames"
                :key="`member-${name}`"
                type="button"
                class="flex w-full cursor-pointer items-center justify-between rounded-sm px-2 py-1.5 text-left text-sm hover:bg-accent"
                @click="selectAgent('members', name)"
              >
                <span>{{ name }}</span>
                <span
                  v-if="form.members === name"
                  class="i-lucide-check size-4 text-primary"
                />
              </button>
              <p
                v-if="!agentNames.length"
                class="px-2 py-1.5 text-sm text-muted-foreground"
              >
                {{ t('COMPANIES.CREATE.FIELDS.MEMBERS_PLACEHOLDER') }}
              </p>
            </div>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.PHONE') }}
            </label>
            <RelayInput
              v-model="form.phone"
              type="tel"
              :placeholder="t('COMPANIES.CREATE.FIELDS.PHONE_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.EMAIL') }}
            </label>
            <RelayInput
              v-model="form.email"
              type="email"
              :placeholder="t('COMPANIES.CREATE.FIELDS.EMAIL_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.WEBSITE') }}
            </label>
            <RelayInput
              v-model="form.website"
              :placeholder="t('COMPANIES.CREATE.FIELDS.WEBSITE_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.ADDRESS') }}
            </label>
            <RelayInput
              v-model="form.address"
              :placeholder="t('COMPANIES.CREATE.FIELDS.ADDRESS_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.STATE') }}
            </label>
            <div class="relative w-full">
              <RelayInput
                v-model="form.state"
                :placeholder="t('COMPANIES.CREATE.FIELDS.STATE_PLACEHOLDER')"
                class-name="h-10 w-full rounded-md border-border bg-background pr-9 text-[14px] shadow-sm"
                :disabled="isLoading"
              />
              <span
                class="i-lucide-chevron-down pointer-events-none absolute right-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
            </div>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.CITY') }}
            </label>
            <RelayInput
              v-model="form.city"
              :placeholder="t('COMPANIES.CREATE.FIELDS.CITY_PLACEHOLDER')"
              class-name="h-10 w-full rounded-md border-border bg-background text-[14px] shadow-sm"
              :disabled="isLoading"
            />
          </div>

          <div class="col-span-2 flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('COMPANIES.CREATE.FIELDS.DESCRIPTION') }}
              <span class="font-normal text-muted-foreground">
                {{ t('COMPANIES.CREATE.OPTIONAL') }}
              </span>
            </label>
            <textarea
              v-model="form.description"
              :placeholder="
                t('COMPANIES.CREATE.FIELDS.DESCRIPTION_PLACEHOLDER')
              "
              :disabled="isLoading"
              class="min-h-[80px] w-full resize-y rounded-md border border-border bg-background p-3 text-[14px] text-foreground shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 disabled:opacity-50"
            />
          </div>
        </div>

        <div
          class="mt-auto flex shrink-0 items-center justify-between border-t border-border bg-muted/10 p-6"
        >
          <RelayButton
            variant="ghost"
            class="text-sm font-medium"
            @click="close"
          >
            {{ t('COMPANIES.CREATE.ACTIONS.CANCEL') }}
          </RelayButton>
          <div @click="handleDisabledSubmitClick">
            <RelayButton
              class="text-sm font-medium shadow-sm"
              :disabled="!isFormValid || isLoading"
              @click="handleSubmit"
            >
              {{ t('COMPANIES.CREATE.ACTIONS.SAVE') }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
