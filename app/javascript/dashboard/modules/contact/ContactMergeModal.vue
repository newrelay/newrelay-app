<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';
import {
  DialogRoot,
  DialogPortal,
  DialogOverlay,
  DialogContent,
  DialogTitle,
  DialogDescription,
} from 'reka-ui';
import ContactAPI from 'dashboard/api/contacts';
import { CONTACTS_EVENTS } from '../../helper/AnalyticsHelper/events';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import {
  RelayButton,
  RelayInput,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_BODY_CLASS,
} from 'dashboard/components-next/relay/modal/constants';
import RelayModalHeader from 'dashboard/components-next/relay/modal/RelayModalHeader.vue';

const props = defineProps({
  primaryContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'merged']);

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('contacts/getUIFlags');

const showMergeModal = ref(false);
const isPreviewOpen = ref(false);
const mergeSearchQuery = ref('');
const searchResults = ref([]);
const selectedDuplicate = ref(null);
const isSearching = ref(false);

const isMergingContact = computed(() => uiFlags.value.isMerging);
const canPreview = computed(() => Boolean(selectedDuplicate.value?.id));

const resetState = () => {
  mergeSearchQuery.value = '';
  searchResults.value = [];
  selectedDuplicate.value = null;
  isPreviewOpen.value = false;
};

const openMergeModal = () => {
  resetState();
  showMergeModal.value = true;
};

const closeMergeModal = () => {
  if (isMergingContact.value) return;
  showMergeModal.value = false;
  resetState();
  emit('close');
};

const handleOpenChange = value => {
  if (value) {
    openMergeModal();
    return;
  }
  closeMergeModal();
};

watch(
  () => props.primaryContact.id,
  () => {
    resetState();
    showMergeModal.value = false;
  }
);

const onContactSearch = debounce(
  async query => {
    mergeSearchQuery.value = query;
    selectedDuplicate.value = null;
    if (!query?.trim()) {
      searchResults.value = [];
      return;
    }

    isSearching.value = true;
    try {
      const {
        data: { payload },
      } = await ContactAPI.search(query);
      searchResults.value = payload.filter(
        contact => contact.id !== props.primaryContact.id
      );
    } catch {
      useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SEARCH_ERROR_MESSAGE'));
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const selectDuplicate = contact => {
  selectedDuplicate.value = contact;
  mergeSearchQuery.value = contact.name || contact.email || '';
  searchResults.value = [];
};

const openPreviewMerge = () => {
  if (!canPreview.value) return;
  isPreviewOpen.value = true;
};

const onMergeContacts = async () => {
  if (!selectedDuplicate.value?.id) return;

  useTrack(CONTACTS_EVENTS.MERGED_CONTACTS);

  try {
    await store.dispatch('contacts/merge', {
      parentId: props.primaryContact.id,
      childId: selectedDuplicate.value.id,
    });
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SUCCESS_MESSAGE'));
    showMergeModal.value = false;
    resetState();
    emit('merged');
    emit('close');
  } catch {
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.ERROR_MESSAGE'));
  }
};

const initials = name => {
  const parts = (name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }
  return (name || '?').slice(0, 2).toUpperCase();
};
</script>

<template>
  <div class="contents">
    <slot name="trigger" :open="openMergeModal" />

    <DialogRoot :open="showMergeModal" @update:open="handleOpenChange">
      <DialogPortal>
        <DialogOverlay :class="RELAY_DIALOG_OVERLAY_CLASS" />
        <DialogContent
          class="fixed left-[50%] top-[50%] z-[200] flex w-full max-w-[600px] translate-x-[-50%] translate-y-[-50%] flex-col overflow-hidden border border-border/80 bg-background p-0 shadow-xl duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 sm:rounded-xl"
        >
          <RelayModalHeader
            :title-tag="DialogTitle"
            :description-tag="DialogDescription"
            :title="
              isPreviewOpen
                ? t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PREVIEW_TITLE')
                : t('CONTACTS_LAYOUT.SIDEBAR.MERGE.TITLE_NEW')
            "
            :description="
              isPreviewOpen
                ? t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PREVIEW_SUBTITLE')
                : ''
            "
            :show-close="false"
          />

          <div :class="RELAY_MODAL_BODY_CLASS">
            <template v-if="!isPreviewOpen">
              <div
                class="flex flex-col gap-4 rounded-xl border border-border/80 p-5 shadow-sm"
              >
                <div :class="RELAY_FORM_FIELD_CLASS">
                  <label :class="RELAY_FORM_LABEL_CLASS">
                    {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SELECT_LABEL') }}
                  </label>
                  <div class="relative w-full">
                    <span
                      class="i-lucide-search absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
                      aria-hidden="true"
                    />
                    <RelayInput
                      :model-value="mergeSearchQuery"
                      :placeholder="
                        t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SEARCH_BY')
                      "
                      class-name="h-10 pl-9"
                      @update:model-value="onContactSearch"
                    />
                  </div>
                </div>

                <div
                  v-if="isSearching || searchResults.length"
                  class="max-h-48 overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
                >
                  <p
                    v-if="isSearching"
                    class="mb-0 px-2 py-1.5 text-sm leading-tight text-muted-foreground"
                  >
                    {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.IS_SEARCHING') }}
                  </p>
                  <button
                    v-for="contact in searchResults"
                    :key="contact.id"
                    type="button"
                    class="flex w-full items-center gap-2.5 rounded-sm px-2 py-1.5 text-left text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
                    @click="selectDuplicate(contact)"
                  >
                    <Avatar
                      :name="contact.name || ''"
                      :src="contact.thumbnail || ''"
                      :size="24"
                      rounded-full
                    />
                    <div class="flex min-w-0 flex-col gap-0">
                      <span
                        class="truncate text-sm font-medium leading-tight text-foreground"
                      >
                        {{ contact.name }}
                      </span>
                      <span
                        class="truncate text-xs leading-tight text-muted-foreground"
                      >
                        {{ contact.email }}
                      </span>
                    </div>
                  </button>
                  <p
                    v-if="!isSearching && searchResults.length === 0"
                    class="mb-0 px-2 py-1.5 text-sm leading-tight text-muted-foreground"
                  >
                    {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.EMPTY_STATE') }}
                  </p>
                </div>

                <p class="mt-1 text-[13px] text-muted-foreground">
                  {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SELECT_HELP_PREFIX') }}
                  <strong class="text-foreground">{{
                    primaryContact.name
                  }}</strong>
                  {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SELECT_HELP_SUFFIX') }}
                </p>

                <div
                  class="mt-1 rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-[13px] leading-relaxed text-destructive shadow-sm"
                >
                  {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.WARNING') }}
                </div>

                <div class="mt-2 flex justify-end gap-3">
                  <RelayButton
                    type="button"
                    variant="ghost"
                    class="h-9 rounded-lg border border-border bg-background px-4 text-[13px] font-medium text-foreground shadow-sm transition-all hover:border-transparent hover:bg-accent"
                    :disabled="isMergingContact"
                    @click="closeMergeModal"
                  >
                    {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CANCEL') }}
                  </RelayButton>
                  <RelayButton
                    type="button"
                    class="h-9 rounded-lg px-4 text-[13px] font-medium shadow-sm"
                    :class="
                      canPreview
                        ? ''
                        : 'cursor-not-allowed bg-primary/50 opacity-50 hover:bg-primary/50'
                    "
                    :disabled="!canPreview || isMergingContact"
                    @click="openPreviewMerge"
                  >
                    {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.PREVIEW') }}
                  </RelayButton>
                </div>
              </div>
            </template>

            <template v-else>
              <div
                class="grid grid-cols-1 gap-6 overflow-y-auto bg-muted/10 sm:grid-cols-2"
              >
                <div class="flex flex-col gap-2">
                  <div class="flex justify-end">
                    <span
                      class="rounded-md bg-primary px-2 py-0.5 text-[10px] font-bold text-primary-foreground"
                    >
                      {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PRIMARY_BADGE') }}
                    </span>
                  </div>
                  <div
                    class="flex flex-col gap-4 rounded-lg border border-border bg-card p-4"
                  >
                    <div
                      class="flex items-center gap-3 border-b border-border/40 pb-3"
                    >
                      <div
                        class="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary/10 font-medium text-primary"
                      >
                        {{ initials(primaryContact.name) }}
                      </div>
                      <div class="min-w-0">
                        <h4
                          class="truncate text-[14px] font-medium capitalize text-foreground"
                        >
                          {{ primaryContact.name }}
                        </h4>
                        <p
                          class="mb-0 truncate text-xs leading-normal text-muted-foreground"
                        >
                          {{ primaryContact.email }}
                        </p>
                      </div>
                    </div>
                    <div class="flex flex-col gap-3">
                      <div>
                        <span
                          class="text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
                        >
                          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PHONE') }}
                        </span>
                        <p
                          class="mb-0 truncate text-sm leading-normal text-foreground"
                        >
                          {{
                            primaryContact.phone_number ||
                            t('CONTACT_PANEL.PHONE_NOT_PROVIDED')
                          }}
                        </p>
                      </div>
                      <div>
                        <span
                          class="text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
                        >
                          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.EMAIL') }}
                        </span>
                        <p
                          class="mb-0 truncate text-sm leading-normal text-foreground"
                        >
                          {{
                            primaryContact.email ||
                            t('CONTACT_PANEL.EMAIL_NOT_PROVIDED')
                          }}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex flex-col gap-2">
                  <div class="flex justify-end">
                    <span
                      class="rounded-md bg-destructive px-2 py-0.5 text-[10px] font-bold text-destructive-foreground"
                    >
                      {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.DELETED_BADGE') }}
                    </span>
                  </div>
                  <div
                    class="flex flex-col gap-4 rounded-lg border border-destructive/30 bg-destructive/5 p-4"
                  >
                    <div
                      class="flex items-center gap-3 border-b border-destructive/10 pb-3"
                    >
                      <div
                        class="flex size-10 shrink-0 items-center justify-center rounded-full bg-destructive/10 font-medium text-destructive"
                      >
                        {{ initials(selectedDuplicate?.name) }}
                      </div>
                      <div class="min-w-0">
                        <h4
                          class="truncate text-[14px] font-medium capitalize text-foreground"
                        >
                          {{ selectedDuplicate?.name }}
                        </h4>
                        <p
                          class="mb-0 truncate text-xs leading-normal text-muted-foreground"
                        >
                          {{ selectedDuplicate?.email }}
                        </p>
                      </div>
                    </div>
                    <div class="flex flex-col gap-3">
                      <div>
                        <span
                          class="text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
                        >
                          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PHONE') }}
                        </span>
                        <p
                          class="mb-0 truncate text-sm leading-normal text-foreground line-through opacity-60"
                        >
                          {{
                            selectedDuplicate?.phone_number ||
                            t('CONTACT_PANEL.PHONE_NOT_PROVIDED')
                          }}
                        </p>
                      </div>
                      <div>
                        <span
                          class="text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
                        >
                          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.EMAIL') }}
                        </span>
                        <p
                          class="mb-0 truncate text-sm leading-normal text-foreground line-through opacity-60"
                        >
                          {{
                            selectedDuplicate?.email ||
                            t('CONTACT_PANEL.EMAIL_NOT_PROVIDED')
                          }}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="mt-2 flex justify-end gap-3">
                <RelayButton
                  type="button"
                  variant="ghost"
                  class="h-9 rounded-lg border border-border bg-background px-4 text-[13px] font-medium text-foreground shadow-sm transition-all hover:border-transparent hover:bg-accent"
                  :disabled="isMergingContact"
                  @click="isPreviewOpen = false"
                >
                  {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CANCEL') }}
                </RelayButton>
                <RelayButton
                  type="button"
                  class="h-9 rounded-lg px-4 text-[13px] font-medium shadow-sm"
                  :disabled="isMergingContact"
                  @click="onMergeContacts"
                >
                  {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CONFIRM_MERGE') }}
                </RelayButton>
              </div>
            </template>
          </div>
        </DialogContent>
      </DialogPortal>
    </DialogRoot>
  </div>
</template>
