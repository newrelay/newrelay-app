<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import Avatar from 'next/avatar/Avatar.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import SettingsLayout from '../SettingsLayout.vue';
import SettingsListCard from '../components/SettingsListCard.vue';
import SettingsListRow from '../components/SettingsListRow.vue';
import {
  useMapGetter,
  useStoreGetters,
  useStore,
} from 'dashboard/composables/store';
import ChannelName from './components/ChannelName.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const getters = useStoreGetters();
const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const showDeletePopup = ref(false);
const selectedInbox = ref({});
const searchQuery = ref('');

const inboxes = useMapGetter('inboxes/getInboxes');

const inboxesList = computed(() => {
  return inboxes.value?.slice().sort((a, b) => a.name.localeCompare(b.name));
});

const filteredInboxesList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return inboxesList.value;
  return picoSearch(inboxesList.value, query, ['name', 'channel_type']);
});

const uiFlags = computed(() => getters['inboxes/getUIFlags'].value);

const deleteConfirmText = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.YES')} ${selectedInbox.value.name}`
);

const deleteRejectText = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.NO')} ${selectedInbox.value.name}`
);

const confirmDeleteMessage = computed(
  () => `${t('INBOX_MGMT.DELETE.CONFIRM.MESSAGE')} ${selectedInbox.value.name}?`
);
const confirmPlaceHolderText = computed(
  () =>
    `${t('INBOX_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
      inboxName: selectedInbox.value.name,
    })}`
);

const deleteInbox = async ({ id }) => {
  try {
    await store.dispatch('inboxes/delete', id);
    useAlert(t('INBOX_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.DELETE.API.ERROR_MESSAGE'));
  }
};
const closeDelete = () => {
  showDeletePopup.value = false;
  selectedInbox.value = {};
};

const confirmDeletion = () => {
  deleteInbox(selectedInbox.value);
  closeDelete();
};
const openDelete = inbox => {
  showDeletePopup.value = true;
  selectedInbox.value = inbox;
};

const openAddInbox = () => {
  router.push({ name: 'settings_inbox_new' });
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INBOX_MGMT.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <SettingsListCard
        :details-label="$t('INBOX_MGMT.LIST.DETAILS')"
        :actions-label="$t('INBOX_MGMT.LIST.ACTIONS')"
        :show-column-headers="!!filteredInboxesList.length"
      >
        <template #toolbar>
          <div>
            <h3 class="text-base font-medium text-foreground">
              {{ $t('INBOX_MGMT.HEADER') }}
            </h3>
            <p class="mt-1 text-sm text-muted-foreground">
              {{ $t('INBOX_MGMT.DESCRIPTION') }}
            </p>
          </div>
          <div
            class="flex w-full flex-col items-center gap-3 sm:flex-row md:w-auto"
          >
            <div class="relative w-full sm:w-64">
              <Icon
                icon="i-lucide-search"
                class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <RelayInput
                v-model="searchQuery"
                type="search"
                :placeholder="$t('INBOX_MGMT.SEARCH_PLACEHOLDER')"
                class-name="h-9 bg-background pl-9 shadow-none"
              />
            </div>
            <RelayButton
              v-if="isAdmin"
              class="h-9 w-full whitespace-nowrap shadow-sm sm:w-auto"
              @click="openAddInbox"
            >
              {{ $t('SETTINGS.INBOXES.NEW_INBOX') }}
            </RelayButton>
          </div>
        </template>

        <template v-if="!filteredInboxesList.length" #empty>
          <div
            v-if="searchQuery"
            class="px-6 text-center text-sm text-muted-foreground"
          >
            {{ $t('INBOX_MGMT.NO_RESULTS') }}
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center bg-muted/10 px-6 py-4"
          >
            <div
              class="mb-5 flex size-16 items-center justify-center rounded-full border border-border bg-muted/50"
            >
              <Icon
                icon="i-lucide-inbox"
                class="size-7 text-muted-foreground/70"
              />
            </div>
            <h3 class="mb-1.5 text-base font-semibold text-foreground">
              {{ $t('INBOX_MGMT.LIST.EMPTY_TITLE') }}
            </h3>
            <p
              class="mb-6 max-w-sm text-center text-[13.5px] leading-relaxed text-muted-foreground"
            >
              {{ $t('INBOX_MGMT.LIST.EMPTY_DESC') }}
            </p>
            <RelayButton
              v-if="isAdmin"
              class="h-9 shadow-sm"
              @click="openAddInbox"
            >
              <Icon icon="i-lucide-plus" class="size-4" />
              {{ $t('SETTINGS.INBOXES.NEW_INBOX') }}
            </RelayButton>
          </div>
        </template>

        <SettingsListRow v-for="inbox in filteredInboxesList" :key="inbox.id">
          <template #leading>
            <div
              v-if="inbox.avatar_url"
              class="grid size-10 place-items-center rounded-xl border border-border/60 bg-background shadow-xs"
            >
              <Avatar
                :src="inbox.avatar_url"
                :name="inbox.name"
                :size="24"
                rounded-full
              />
            </div>
            <div
              v-else
              class="grid size-10 place-items-center rounded-xl border border-border/60 bg-background shadow-xs"
            >
              <ChannelIcon
                class="size-4 text-muted-foreground"
                :inbox="inbox"
              />
            </div>
          </template>
          <span class="text-sm font-medium capitalize text-foreground">
            {{ inbox.name }}
          </span>
          <ChannelName
            :channel-type="inbox.channel_type"
            :medium="inbox.medium"
            :voice-enabled="inbox.voice_enabled"
            class="mt-0.5 text-xs text-muted-foreground"
          />
          <template #actions>
            <router-link
              :to="{
                name: 'settings_inbox_show',
                params: { inboxId: inbox.id },
              }"
            >
              <RelayButton
                v-if="isAdmin"
                v-tooltip.top="$t('INBOX_MGMT.SETTINGS')"
                variant="ghost"
                size="icon"
                class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-border hover:bg-background hover:text-foreground"
              >
                <Icon icon="i-lucide-sliders-horizontal" class="size-3.5" />
              </RelayButton>
            </router-link>
            <RelayButton
              v-if="isAdmin"
              v-tooltip.top="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
              variant="ghost"
              size="icon"
              class="size-8 border border-transparent text-muted-foreground shadow-xs hover:border-red-100 hover:bg-red-50 hover:text-red-600"
              @click="openDelete(inbox)"
            >
              <Icon icon="i-lucide-trash-2" class="size-3.5" />
            </RelayButton>
          </template>
        </SettingsListRow>
      </SettingsListCard>
    </template>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="$t('INBOX_MGMT.DELETE.CONFIRM.TITLE')"
      :message="confirmDeleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedInbox.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
