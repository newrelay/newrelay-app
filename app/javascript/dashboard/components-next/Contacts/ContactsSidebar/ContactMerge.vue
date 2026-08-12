<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useAlert, useTrack } from 'dashboard/composables';
import ContactAPI from 'dashboard/api/contacts';
import { debounce } from '@chatwoot/utils';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['resetTab']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const mergeSearchQuery = ref('');
const searchResults = ref([]);
const selectedDuplicate = ref(null);
const isSearching = ref(false);
const isPreviewOpen = ref(false);

const uiFlags = useMapGetter('contacts/getUIFlags');
const isMergingContact = computed(() => uiFlags.value.isMerging);

const canPreview = computed(() => Boolean(selectedDuplicate.value?.id));

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
        contact => contact.id !== props.selectedContact.id
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

const resetState = () => {
  mergeSearchQuery.value = '';
  searchResults.value = [];
  selectedDuplicate.value = null;
  isPreviewOpen.value = false;
  emit('resetTab');
};

const openPreviewMerge = () => {
  if (!canPreview.value) return;
  isPreviewOpen.value = true;
};

const onMergeContacts = async () => {
  if (!selectedDuplicate.value?.id) return;

  useTrack(CONTACTS_EVENTS.MERGED_CONTACTS);

  try {
    // Current contact is primary (kept); selected duplicate is deleted.
    await store.dispatch('contacts/merge', {
      parentId: props.selectedContact.id || route.params.contactId,
      childId: selectedDuplicate.value.id,
    });
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SUCCESS_MESSAGE'));
    isPreviewOpen.value = false;
    mergeSearchQuery.value = '';
    searchResults.value = [];
    selectedDuplicate.value = null;
    await store.dispatch('contacts/show', {
      id: props.selectedContact.id || route.params.contactId,
    });
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
  <div>
    <h3 class="mb-6 text-sm font-medium text-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.TITLE_NEW') }}
    </h3>

    <div
      class="mb-4 flex w-full flex-col rounded-xl border border-border bg-card p-5 shadow-sm"
    >
      <div class="mb-6 flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SELECT_LABEL') }}
        </label>
        <div class="relative">
          <span
            class="i-lucide-search absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            :model-value="mergeSearchQuery"
            :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SEARCH_BY')"
            class-name="pl-9 h-10 w-full text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            @update:model-value="onContactSearch"
          />
        </div>
        <p class="mt-1 text-xs text-muted-foreground">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SELECT_HELP_PREFIX') }}
          <strong class="text-foreground">{{ selectedContact.name }}</strong>
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SELECT_HELP_SUFFIX') }}
        </p>

        <div
          v-if="isSearching || searchResults.length"
          class="mt-2 max-h-48 overflow-y-auto rounded-md border border-border bg-popover shadow-md"
        >
          <p v-if="isSearching" class="px-3 py-2 text-sm text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.IS_SEARCHING') }}
          </p>
          <button
            v-for="contact in searchResults"
            :key="contact.id"
            type="button"
            class="flex w-full items-center gap-3 px-3 py-2 text-left text-sm hover:bg-accent hover:text-accent-foreground"
            @click="selectDuplicate(contact)"
          >
            <Avatar
              :name="contact.name || ''"
              :src="contact.thumbnail || ''"
              :size="28"
              rounded-full
            />
            <div class="min-w-0">
              <p class="truncate font-medium text-foreground">
                {{ contact.name }}
              </p>
              <p class="truncate text-xs text-muted-foreground">
                {{ contact.email }}
              </p>
            </div>
          </button>
          <p
            v-if="!isSearching && searchResults.length === 0"
            class="px-3 py-2 text-sm text-muted-foreground"
          >
            {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.EMPTY_STATE') }}
          </p>
        </div>
      </div>

      <div
        class="mb-6 flex items-start gap-3 rounded-lg border border-destructive/20 bg-destructive/10 p-3.5"
      >
        <span
          class="i-lucide-lightbulb mt-0.5 size-4 shrink-0 text-destructive"
        />
        <p class="text-[13px] font-medium leading-relaxed text-destructive">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.WARNING') }}
        </p>
      </div>

      <div class="mt-auto flex items-center gap-3 self-end">
        <RelayButton
          variant="outline"
          class="h-9 px-4 text-sm font-medium"
          @click="resetState"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CANCEL') }}
        </RelayButton>
        <RelayButton
          class="h-9 px-4 text-sm font-medium"
          :disabled="!canPreview"
          @click="openPreviewMerge"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.PREVIEW') }}
        </RelayButton>
      </div>
    </div>

    <!-- Preview merge modal -->
    <div
      v-if="isPreviewOpen"
      class="fixed inset-0 z-[60] flex items-center justify-center bg-n-alpha-black2 p-4 backdrop-blur-[4px]"
      @click.self="isPreviewOpen = false"
    >
      <div
        class="flex max-h-[90vh] w-full max-w-2xl flex-col overflow-hidden rounded-xl border border-border bg-card shadow-2xl animate-in fade-in zoom-in-95 duration-200"
      >
        <div class="shrink-0 border-b border-border/40 p-6">
          <h2 class="text-lg font-semibold tracking-tight text-foreground">
            {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PREVIEW_TITLE') }}
          </h2>
          <p class="mt-1 text-sm text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PREVIEW_SUBTITLE') }}
          </p>
        </div>

        <div
          class="grid grid-cols-1 gap-6 overflow-y-auto bg-muted/10 p-6 sm:grid-cols-2"
        >
          <div
            class="relative flex flex-col gap-4 overflow-hidden rounded-lg border border-border bg-card p-4"
          >
            <div
              class="absolute right-0 top-0 rounded-bl-lg bg-primary px-2 py-0.5 text-[10px] font-bold text-primary-foreground"
            >
              {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PRIMARY_BADGE') }}
            </div>
            <div class="flex items-center gap-3 border-b border-border/40 pb-3">
              <div
                class="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary/10 font-medium text-primary"
              >
                {{ initials(selectedContact.name) }}
              </div>
              <div class="min-w-0">
                <h4 class="truncate text-sm font-medium text-foreground">
                  {{ selectedContact.name }}
                </h4>
                <p class="truncate text-xs text-muted-foreground">
                  {{ selectedContact.email }}
                </p>
              </div>
            </div>
            <div class="flex flex-col gap-3">
              <div>
                <span
                  class="text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
                >
                  {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.PHONE') }}
                </span>
                <p class="truncate text-sm text-foreground">
                  {{ selectedContact.phoneNumber || '—' }}
                </p>
              </div>
            </div>
          </div>

          <div
            class="relative flex flex-col gap-4 overflow-hidden rounded-lg border border-destructive/30 bg-destructive/5 p-4"
          >
            <div
              class="absolute right-0 top-0 rounded-bl-lg bg-destructive px-2 py-0.5 text-[10px] font-bold text-destructive-foreground"
            >
              {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.DELETED_BADGE') }}
            </div>
            <div
              class="flex items-center gap-3 border-b border-destructive/10 pb-3"
            >
              <div
                class="flex size-10 shrink-0 items-center justify-center rounded-full bg-destructive/10 font-medium text-destructive"
              >
                {{ initials(selectedDuplicate?.name) }}
              </div>
              <div class="min-w-0">
                <h4 class="truncate text-sm font-medium text-foreground">
                  {{ selectedDuplicate?.name }}
                </h4>
                <p class="truncate text-xs text-muted-foreground">
                  {{ selectedDuplicate?.email }}
                </p>
              </div>
            </div>
            <div class="flex flex-col gap-3">
              <div>
                <span
                  class="text-[11px] font-medium uppercase tracking-wider text-muted-foreground"
                >
                  {{ t('CONTACTS_LAYOUT.DETAIL.ABOUT.PHONE') }}
                </span>
                <p
                  class="truncate text-sm text-foreground line-through opacity-60"
                >
                  {{ selectedDuplicate?.phoneNumber || '—' }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div
          class="flex shrink-0 items-center justify-end gap-3 border-t border-border bg-card px-6 py-4"
        >
          <RelayButton variant="outline" @click="isPreviewOpen = false">
            {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CANCEL') }}
          </RelayButton>
          <RelayButton :disabled="isMergingContact" @click="onMergeContacts">
            {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CONFIRM_MERGE') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
