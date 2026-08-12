<script setup>
import { reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { buildPortalURL } from 'dashboard/helper/portalHelper';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, helpers, url } from '@vuelidate/validators';
import { isValidSlug } from 'shared/helpers/Validators';

import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

const state = reactive({
  name: '',
  headerText: '',
  pageTitle: '',
  slug: '',
  homePageLink: '',
  logoUrl: '',
  avatarBlobId: '',
});

const rules = {
  name: { required, minLength: minLength(2) },
  slug: {
    required: helpers.withMessage(
      () => t('HELP_CENTER.CREATE_PORTAL_DIALOG.SLUG.ERROR'),
      required
    ),
    isValidSlug: helpers.withMessage(
      () => t('HELP_CENTER.CREATE_PORTAL_DIALOG.SLUG.FORMAT_ERROR'),
      isValidSlug
    ),
  },
  homePageLink: { url },
};

const v$ = useVuelidate(rules, state);

const nameError = computed(() =>
  v$.value.name.$error ? t('HELP_CENTER.CREATE_PORTAL_DIALOG.NAME.ERROR') : ''
);

const slugError = computed(() => {
  return v$.value.slug.$errors[0]?.$message || '';
});

const homePageLinkError = computed(() =>
  v$.value.homePageLink.$error
    ? t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.ERROR')
    : ''
);

const isUpdatingPortal = computed(() => {
  const slug = props.activePortal?.slug;
  if (slug) return getters['portals/uiFlagsIn'].value(slug)?.isUpdating;

  return false;
});

watch(
  () => props.activePortal,
  newVal => {
    if (newVal && !props.isFetching) {
      Object.assign(state, {
        name: newVal.name,
        headerText: newVal.header_text,
        pageTitle: newVal.page_title,
        homePageLink: newVal.homepage_link,
        slug: newVal.slug,
      });
      if (newVal.logo) {
        const {
          logo: { file_url: logoURL, blob_id: blobId },
        } = newVal;
        state.logoUrl = logoURL;
        state.avatarBlobId = blobId;
      } else {
        state.logoUrl = '';
        state.avatarBlobId = '';
      }
    }
  },
  { immediate: true, deep: true }
);

const isInvalid = computed(() => v$.value.$invalid);

const getPayload = () => ({
  id: props.activePortal?.id,
  slug: state.slug,
  name: state.name,
  page_title: state.pageTitle,
  header_text: state.headerText,
  homepage_link: state.homePageLink,
  blob_id: state.avatarBlobId,
});

async function uploadLogoToStorage({ file }) {
  try {
    const { fileUrl, blobId } = await uploadFile(file);
    if (fileUrl) {
      state.logoUrl = fileUrl;
      state.avatarBlobId = blobId;
    }
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_SUCCESS'));
  } catch (error) {
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_ERROR'));
  }
}

async function deleteLogo() {
  try {
    const portalSlug = props.activePortal?.slug;
    await store.dispatch('portals/deleteLogo', {
      portalSlug,
    });
    useAlert(t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_DELETE_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_DELETE_ERROR')
    );
  }
}

const handleAvatarUpload = file => {
  if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    uploadLogoToStorage(file);
  } else {
    const errorKey =
      'HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.IMAGE_UPLOAD_SIZE_ERROR';
    useAlert(t(errorKey, { size: MAXIMUM_FILE_UPLOAD_SIZE }));
  }
};

const handleAvatarDelete = () => {
  state.logoUrl = '';
  state.avatarBlobId = '';
  deleteLogo();
};

defineExpose({
  isInvalid,
  isUpdatingPortal,
  getPayload,
});
</script>

<template>
  <div class="flex flex-col gap-8">
    <!-- Portal Identity -->
    <div
      class="relative flex flex-col gap-6 overflow-hidden rounded-2xl border border-border/40 bg-card p-6 shadow-sm"
    >
      <h2 class="flex items-center gap-2 text-base font-medium text-foreground">
        <span class="i-lucide-monitor size-4 text-primary" aria-hidden="true" />
        {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SECTION_IDENTITY') }}
      </h2>

      <div class="flex flex-col gap-8 md:flex-row">
        <div class="flex shrink-0 flex-col gap-3">
          <RelayLabel class="text-[13.5px]">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.LABEL') }}
          </RelayLabel>
          <Avatar
            :src="state.logoUrl"
            :name="state.name"
            :size="96"
            allow-upload
            icon-name="i-lucide-layout-grid"
            @upload="handleAvatarUpload"
            @delete="handleAvatarDelete"
          />
          <span
            class="max-w-[96px] text-center text-[11px] leading-tight text-muted-foreground"
          >
            {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.AVATAR.HINT') }}
          </span>
        </div>

        <div class="flex-1 space-y-5">
          <div class="flex flex-col gap-1.5">
            <RelayLabel class="text-[13.5px]">
              {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.LABEL') }}
            </RelayLabel>
            <RelayInput
              v-model="state.name"
              :placeholder="
                t('HELP_CENTER.PORTAL_SETTINGS.FORM.NAME.PLACEHOLDER')
              "
              class-name="h-10 text-[14px]"
              @blur="v$.name.$touch()"
            />
            <p v-if="nameError" class="text-[12px] text-destructive">
              {{ nameError }}
            </p>
          </div>
          <div class="flex flex-col gap-1.5">
            <RelayLabel class="text-[13.5px]">
              {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.LABEL') }}
            </RelayLabel>
            <RelayInput
              v-model="state.headerText"
              :placeholder="
                t('HELP_CENTER.PORTAL_SETTINGS.FORM.HEADER_TEXT.PLACEHOLDER')
              "
              class-name="h-10 text-[14px]"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <RelayLabel class="text-[13.5px]">
              {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.LABEL') }}
            </RelayLabel>
            <RelayInput
              v-model="state.pageTitle"
              :placeholder="
                t('HELP_CENTER.PORTAL_SETTINGS.FORM.PAGE_TITLE.PLACEHOLDER')
              "
              class-name="h-10 text-[14px]"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Domain & Routing -->
    <div
      class="flex flex-col gap-6 rounded-2xl border border-border/40 bg-card p-6 shadow-sm"
    >
      <h2 class="flex items-center gap-2 text-base font-medium text-foreground">
        <span
          class="i-lucide-layout-grid size-4 text-primary"
          aria-hidden="true"
        />
        {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SECTION_ROUTING') }}
      </h2>

      <div class="space-y-5">
        <div class="flex flex-col gap-1.5">
          <RelayLabel class="text-[13.5px]">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.LABEL') }}
          </RelayLabel>
          <RelayInput
            v-model="state.homePageLink"
            :placeholder="
              t('HELP_CENTER.PORTAL_SETTINGS.FORM.HOME_PAGE_LINK.PLACEHOLDER')
            "
            class-name="h-10 text-[14px]"
            @blur="v$.homePageLink.$touch()"
          />
          <p v-if="homePageLinkError" class="text-[12px] text-destructive">
            {{ homePageLinkError }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel class="text-[13.5px]">
            {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SLUG.LABEL') }}
          </RelayLabel>
          <RelayInput
            v-model="state.slug"
            :placeholder="
              t('HELP_CENTER.PORTAL_SETTINGS.FORM.SLUG.PLACEHOLDER')
            "
            class-name="h-10 text-[14px]"
            @blur="v$.slug.$touch()"
          />
          <p
            class="truncate px-1 text-[12.5px]"
            :class="slugError ? 'text-destructive' : 'text-muted-foreground'"
          >
            {{ slugError || buildPortalURL(state.slug) }}
          </p>
        </div>

        <slot name="custom-domain" />
      </div>
    </div>
  </div>
</template>
