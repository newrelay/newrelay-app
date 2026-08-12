<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { RelayBadge, RelayButton } from 'dashboard/components-next/relay';
import { useCompaniesStore } from 'dashboard/stores/companies';

const props = defineProps({
  company: { type: Object, default: () => ({}) },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['back']);

const { t } = useI18n();
const companiesStore = useCompaniesStore();

const isEditingName = ref(false);
const nameDraft = ref('');
const avatarPreviewUrl = ref('');
const isUploadingAvatar = ref(false);

const uiFlags = computed(() => companiesStore.getUIFlags);
const isAvatarBusy = computed(
  () =>
    isUploadingAvatar.value ||
    uiFlags.value.deletingAvatar ||
    uiFlags.value.updatingItem
);

const displayName = computed(
  () => props.company?.name || t('COMPANIES.UNNAMED')
);
const avatarSource = computed(
  () => avatarPreviewUrl.value || props.company?.avatarUrl || ''
);
const subtitle = computed(() => {
  if (props.company?.description) return props.company.description;
  const domain = props.company?.domain;
  if (domain) return domain;
  return '';
});

watch(
  () => [props.company?.id, props.company?.name, props.company?.avatarUrl],
  () => {
    avatarPreviewUrl.value = '';
    nameDraft.value = props.company?.name || '';
  },
  { immediate: true }
);

const handleAvatarUpload = async ({ file, url }) => {
  avatarPreviewUrl.value = url;
  isUploadingAvatar.value = true;
  try {
    await companiesStore.update({ id: props.company.id, avatar: file });
    useAlert(t('COMPANIES.DETAIL.AVATAR.UPLOAD_SUCCESS'));
  } catch {
    avatarPreviewUrl.value = '';
    useAlert(t('COMPANIES.DETAIL.AVATAR.UPLOAD_ERROR'));
  } finally {
    isUploadingAvatar.value = false;
  }
};

const handleAvatarDelete = async () => {
  try {
    await companiesStore.deleteCompanyAvatar(props.company.id);
    avatarPreviewUrl.value = '';
    useAlert(t('COMPANIES.DETAIL.AVATAR.DELETE_SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.DETAIL.AVATAR.DELETE_ERROR'));
  }
};

const commitNameEdit = async () => {
  isEditingName.value = false;
  const nextName = nameDraft.value.trim();
  if (!nextName || nextName === (props.company?.name || '').trim()) return;

  try {
    await companiesStore.update({
      id: props.company.id,
      name: nextName,
    });
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_SUCCESS'));
  } catch {
    nameDraft.value = props.company?.name || '';
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_ERROR'));
  }
};
</script>

<template>
  <div
    v-if="isLoading && !company?.id"
    class="px-8 py-6 text-sm text-muted-foreground"
  >
    {{ t('COMPANIES.DETAIL.LOADING') }}
  </div>

  <header
    v-else-if="company?.id"
    class="flex shrink-0 flex-col border-b border-border/50 bg-card px-8 py-6"
  >
    <div class="mb-4">
      <RelayButton
        variant="ghost"
        size="sm"
        class="-ml-2 h-8 rounded-md px-2 text-[13px] font-medium text-muted-foreground hover:text-foreground"
        @click="emit('back')"
      >
        <span class="i-lucide-arrow-left mr-1.5 size-4" />
        {{ t('COMPANIES.DETAIL.BACK') }}
      </RelayButton>
    </div>

    <div class="flex items-start justify-between">
      <div class="flex items-center gap-5">
        <div
          class="flex size-20 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-border bg-background p-1 shadow-sm"
        >
          <Avatar
            :name="displayName"
            :src="avatarSource"
            :size="72"
            :allow-upload="!isAvatarBusy"
            hide-offline-status
            @upload="handleAvatarUpload"
            @delete="handleAvatarDelete"
          />
        </div>
        <div class="flex flex-col pt-1">
          <div class="flex items-center gap-3">
            <h2
              v-if="!isEditingName"
              class="group flex cursor-pointer items-center gap-2 text-xl font-bold tracking-tight text-foreground"
              @click="isEditingName = true"
            >
              {{ displayName }}
              <span
                class="i-lucide-pencil size-4 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100"
              />
            </h2>
            <input
              v-else
              v-model="nameDraft"
              type="text"
              class="rounded-md border border-border bg-background px-2 py-0.5 text-xl font-bold text-foreground focus:outline-none focus:ring-1 focus:ring-primary/50"
              @blur="commitNameEdit"
              @keyup.enter="commitNameEdit"
            />
            <RelayBadge
              class="h-5 border-none bg-emerald-500/15 px-2 py-0 text-[11px] font-medium text-emerald-600 shadow-none hover:bg-emerald-500/25"
            >
              {{ t('COMPANIES.DETAIL.STATUS_ACTIVE') }}
            </RelayBadge>
          </div>
          <p class="mt-1 text-[14px] text-muted-foreground">
            {{ subtitle }}
          </p>
          <p
            v-if="isUploadingAvatar || uiFlags.deletingAvatar"
            class="mt-1 text-sm text-muted-foreground"
          >
            {{ t('COMPANIES.DETAIL.AVATAR.UPDATING') }}
          </p>
        </div>
      </div>
    </div>
  </header>
</template>
