<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();

const isEditing = ref(false);
const showAddSocial = ref(false);

const SOCIAL_NETWORKS = [
  {
    id: 'linkedin',
    icon: 'i-ri-linkedin-box-fill',
    prefix: 'linkedin.com/in/',
  },
  { id: 'twitter', icon: 'i-ri-twitter-x-fill', prefix: 'x.com/' },
  {
    id: 'facebook',
    icon: 'i-ri-facebook-circle-fill',
    prefix: 'facebook.com/',
  },
  { id: 'instagram', icon: 'i-ri-instagram-line', prefix: 'instagram.com/' },
  { id: 'github', icon: 'i-ri-github-fill', prefix: 'github.com/' },
  { id: 'telegram', icon: 'i-ri-telegram-fill', prefix: 't.me/' },
  { id: 'tiktok', icon: 'i-ri-tiktok-fill', prefix: 'tiktok.com/@' },
];

const form = reactive({
  name: '',
  email: '',
  phoneNumber: '',
  address: '',
  socialProfiles: {},
});

const attrs = computed(() => props.contact?.additionalAttributes || {});

const emptyValue = computed(() => t('CONTACTS_LAYOUT.DETAIL.ABOUT.EMPTY'));

const addressDisplay = computed(() => {
  if (attrs.value.address) return attrs.value.address;
  const parts = [attrs.value.city, attrs.value.country].filter(Boolean);
  return parts.join(', ');
});

const socialEntries = computed(() => {
  const profiles = attrs.value.socialProfiles || {};
  return SOCIAL_NETWORKS.filter(n => profiles[n.id]).map(n => ({
    ...n,
    handle: profiles[n.id],
  }));
});

const availableNetworks = computed(() =>
  SOCIAL_NETWORKS.filter(n => !form.socialProfiles[n.id]).map(n => ({
    label: n.id.charAt(0).toUpperCase() + n.id.slice(1),
    action: 'addSocial',
    value: n.id,
    icon: n.icon,
  }))
);

const localSocialLinks = computed(() =>
  SOCIAL_NETWORKS.filter(n => form.socialProfiles[n.id] !== undefined).map(
    n => ({
      ...n,
      handle: form.socialProfiles[n.id] || '',
    })
  )
);

const syncForm = contact => {
  const a = contact?.additionalAttributes || {};
  form.name = contact?.name || '';
  form.email = contact?.email || '';
  form.phoneNumber = contact?.phoneNumber || '';
  form.address =
    a.address || [a.city, a.country].filter(Boolean).join(', ') || '';
  form.socialProfiles = { ...(a.socialProfiles || {}) };
};

watch(
  () => props.contact,
  current => {
    if (current?.id && !isEditing.value) syncForm(current);
  },
  { immediate: true, deep: true }
);

const startEditing = () => {
  syncForm(props.contact);
  isEditing.value = true;
};

const cancelEditing = () => {
  syncForm(props.contact);
  isEditing.value = false;
  showAddSocial.value = false;
};

const addSocialLink = ({ value }) => {
  form.socialProfiles = { ...form.socialProfiles, [value]: '' };
  showAddSocial.value = false;
};

const removeSocialLink = networkId => {
  const next = { ...form.socialProfiles };
  delete next[networkId];
  form.socialProfiles = next;
};

const updateSocialHandle = (networkId, handle) => {
  form.socialProfiles = { ...form.socialProfiles, [networkId]: handle };
};

const saveAbout = async () => {
  try {
    const socialProfiles = Object.fromEntries(
      Object.entries(form.socialProfiles).filter(([, handle]) =>
        String(handle || '').trim()
      )
    );
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      name: form.name.trim(),
      email: form.email.trim() || null,
      phoneNumber: form.phoneNumber.trim() || null,
      additionalAttributes: {
        ...attrs.value,
        address: form.address.trim() || undefined,
        socialProfiles,
      },
    });
    isEditing.value = false;
    showAddSocial.value = false;
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <aside
    class="flex w-full shrink-0 flex-col overflow-y-auto border-t border-border/40 bg-muted/10 p-6 lg:max-w-sm lg:border-l lg:border-t-0 xl:w-96"
  >
    <div
      class="flex flex-col rounded-xl border border-border/30 bg-card shadow-sm"
    >
      <div class="border-b border-border/30 p-6">
        <h3
          class="mb-6 flex items-center justify-between text-[15px] font-semibold text-foreground"
        >
          {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.TITLE') }}
          <RelayButton
            v-if="!isEditing"
            variant="ghost"
            size="icon"
            class="size-6 text-muted-foreground hover:text-foreground"
            :title="t('CONTACTS_LAYOUT.DETAIL.ABOUT.EDIT')"
            @click="startEditing"
          >
            <span class="i-lucide-user-cog size-4" />
          </RelayButton>
        </h3>

        <!-- View mode -->
        <div v-if="!isEditing" class="flex flex-col">
          <div class="flex items-start gap-4 border-b border-border/30 pb-4">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"
            >
              <span class="i-lucide-mail size-5" />
            </div>
            <div class="flex min-w-0 flex-col gap-0.5">
              <span class="text-[13px] text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.EMAIL') }}
              </span>
              <a
                v-if="contact?.email"
                :href="`mailto:${contact.email}`"
                class="truncate text-[14px] font-medium text-primary hover:underline"
              >
                {{ contact.email }}
              </a>
              <span
                v-else
                class="text-[14px] font-medium text-muted-foreground"
              >
                {{ emptyValue }}
              </span>
            </div>
          </div>

          <div class="flex items-start gap-4 border-b border-border/30 py-4">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"
            >
              <span class="i-lucide-phone size-5" />
            </div>
            <div class="flex min-w-0 flex-col gap-0.5">
              <span class="text-[13px] text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.PHONE') }}
              </span>
              <a
                v-if="contact?.phoneNumber"
                :href="`tel:${contact.phoneNumber}`"
                class="truncate text-[14px] font-medium text-foreground transition-colors hover:text-primary"
              >
                {{ contact.phoneNumber }}
              </a>
              <span
                v-else
                class="text-[14px] font-medium text-muted-foreground"
              >
                {{ emptyValue }}
              </span>
            </div>
          </div>

          <div class="flex items-start gap-4 border-b border-border/30 py-4">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"
            >
              <span class="i-lucide-map-pin size-5" />
            </div>
            <div class="flex min-w-0 flex-col gap-0.5">
              <span class="text-[13px] text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.ADDRESS') }}
              </span>
              <span class="text-[14px] font-medium text-foreground">
                {{ addressDisplay || emptyValue }}
              </span>
            </div>
          </div>

          <div v-if="socialEntries.length" class="flex items-center gap-4 pt-4">
            <div class="flex gap-3">
              <a
                v-for="social in socialEntries"
                :key="social.id"
                :href="`https://${social.prefix}${social.handle}`"
                target="_blank"
                rel="noopener noreferrer"
                class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary transition-colors hover:bg-primary/20"
                :title="social.handle"
              >
                <span class="size-5" :class="[social.icon]" />
              </a>
            </div>
            <span class="text-[14px] text-muted-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.SOCIALS') }}
            </span>
          </div>
          <div v-else class="flex items-start gap-4 pt-4">
            <div
              class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"
            >
              <span class="i-ri-linkedin-box-fill size-5" />
            </div>
            <div class="flex flex-col gap-0.5">
              <span class="text-[13px] text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.SOCIALS') }}
              </span>
              <span class="text-[14px] font-medium text-muted-foreground">
                {{ emptyValue }}
              </span>
            </div>
          </div>
        </div>

        <!-- Edit mode -->
        <div v-else class="space-y-3">
          <div
            class="mb-4 flex items-center gap-3 border-b border-border/40 pb-4"
          >
            <Avatar
              :src="contact?.thumbnail || ''"
              :name="form.name || ''"
              :size="40"
              rounded-full
            />
            <div class="flex flex-1 flex-col gap-1.5">
              <label class="text-[12px] font-medium text-foreground">
                {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.FULL_NAME') }}
              </label>
              <RelayInput
                v-model="form.name"
                class-name="h-8 px-3 text-[13px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
              />
            </div>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.EMAIL') }}
            </label>
            <RelayInput
              v-model="form.email"
              type="email"
              class-name="h-8 px-3 text-[13px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.PHONE') }}
            </label>
            <RelayInput
              v-model="form.phoneNumber"
              class-name="h-8 px-3 text-[13px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.ADDRESS') }}
            </label>
            <RelayInput
              v-model="form.address"
              class-name="h-8 px-3 text-[13px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>

          <div class="flex flex-col gap-1.5 pt-2">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.SOCIAL_LINKS') }}
            </label>
            <div class="mt-1 space-y-2">
              <div
                v-for="link in localSocialLinks"
                :key="link.id"
                class="flex items-center gap-2"
              >
                <div
                  class="flex h-9 flex-1 items-center overflow-hidden rounded-md border border-border/80 bg-background text-[13px] shadow-sm transition-shadow focus-within:ring-1 focus-within:ring-primary/30"
                >
                  <div
                    class="flex shrink-0 items-center pl-3 pr-1 text-muted-foreground"
                  >
                    <span class="size-3.5" :class="[link.icon]" />
                    <span class="ml-2 select-none text-[13px]">{{
                      link.prefix
                    }}</span>
                  </div>
                  <input
                    :value="link.handle"
                    class="h-full min-w-0 flex-1 border-none bg-transparent px-1 text-foreground placeholder:text-muted-foreground focus:outline-none"
                    :placeholder="t('CONTACTS_LAYOUT.DETAIL.ABOUT.HANDLE')"
                    @input="updateSocialHandle(link.id, $event.target.value)"
                  />
                </div>
                <RelayButton
                  variant="ghost"
                  size="icon"
                  class="size-8 shrink-0 text-muted-foreground hover:text-destructive"
                  @click="removeSocialLink(link.id)"
                >
                  <span class="i-lucide-x size-4" />
                </RelayButton>
              </div>

              <div
                v-if="availableNetworks.length"
                v-on-clickaway="() => (showAddSocial = false)"
                class="relative self-start"
              >
                <RelayButton
                  variant="outline"
                  size="sm"
                  class="mt-2 h-8 gap-2 rounded-md text-xs font-medium text-foreground shadow-sm"
                  @click="showAddSocial = !showAddSocial"
                >
                  <span class="i-lucide-plus size-3.5" />
                  {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.ADD_SOCIAL') }}
                </RelayButton>
                <DropdownMenu
                  v-if="showAddSocial"
                  :menu-items="availableNetworks"
                  class="left-0 top-full mt-1 w-48"
                  @action="addSocialLink"
                />
              </div>
            </div>
          </div>

          <div class="flex items-center gap-2 pt-4">
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 flex-1 text-xs font-medium"
              :disabled="isUpdating"
              @click="cancelEditing"
            >
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.CANCEL') }}
            </RelayButton>
            <RelayButton
              size="sm"
              class="h-8 flex-1 text-xs font-medium"
              :disabled="isUpdating || !form.name.trim()"
              @click="saveAbout"
            >
              {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.SAVE') }}
            </RelayButton>
          </div>
        </div>
      </div>

      <div class="p-6">
        <h3 class="mb-4 text-[15px] font-semibold text-foreground">
          {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.STATUS_PROPERTIES') }}
        </h3>
        <div class="flex flex-col gap-3">
          <span class="text-[14px] text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.TAGS') }}
          </span>
          <ContactLabels :contact-id="contact?.id" />
        </div>
      </div>
    </div>
  </aside>
</template>
