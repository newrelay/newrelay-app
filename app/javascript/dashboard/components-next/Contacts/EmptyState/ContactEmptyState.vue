<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';

import ContactImportDialog from 'dashboard/components-next/Contacts/ContactsForm/ContactImportDialog.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  showButton: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['create']);

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute } = useAccount();

const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCompaniesLink = computed(() =>
  isFeatureEnabledonAccount.value(accountId.value, FEATURE_FLAGS.COMPANIES)
);
const companiesRoute = computed(() =>
  accountScopedRoute('companies_dashboard_index')
);

const contactImportDialogRef = ref(null);
const createNewContactDialogRef = ref(null);

const inboxesList = useMapGetter('inboxes/getInboxes');
const allConversations = useMapGetter('getAllConversations');

const hasChannels = computed(() => (inboxesList.value?.length ?? 0) > 0);
const hasConversations = computed(
  () => (allConversations.value?.length ?? 0) > 0
);

const steps = computed(() => [
  {
    key: 'workspace',
    label: t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_WORKSPACE'),
    status: 'completed',
  },
  {
    key: 'contacts',
    label: t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_IMPORT'),
    status: 'active',
  },
  {
    key: 'channel',
    label: t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_CHANNEL'),
    status: hasChannels.value ? 'completed' : 'pending',
  },
  {
    key: 'conversation',
    label: t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_MESSAGE'),
    status: hasConversations.value ? 'completed' : 'pending',
  },
]);

const currentStepNumber = computed(() => {
  const activeIndex = steps.value.findIndex(step => step.status === 'active');
  if (activeIndex >= 0) return activeIndex + 1;
  return 2;
});

const openImport = () => {
  contactImportDialogRef.value?.dialogRef.open();
};

const openCreate = () => {
  createNewContactDialogRef.value?.dialogRef.open();
};

const onImport = async file => {
  try {
    await store.dispatch('contacts/import', file);
    contactImportDialogRef.value?.dialogRef.close();
    useAlert(
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error instanceof ExceptionWithMessage
        ? error.data
        : (error.message ??
            t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.ERROR_MESSAGE'))
    );
  }
};
</script>

<template>
  <div
    class="mx-auto flex max-w-lg flex-1 flex-col items-center justify-center py-12 text-center"
  >
    <div
      class="mb-6 mt-2 flex size-16 items-center justify-center rounded-full bg-primary/10 ring-8 ring-primary/5 animate-in fade-in zoom-in-95 duration-500"
    >
      <span class="i-lucide-users size-8 text-primary" />
    </div>
    <h2 class="mb-2 text-[20px] font-[600] tracking-tight text-foreground">
      {{ title || t('CONTACTS_LAYOUT.EMPTY_STATE.TITLE') }}
    </h2>
    <p class="mb-8 max-w-md text-sm text-muted-foreground">
      {{ subtitle || t('CONTACTS_LAYOUT.EMPTY_STATE.SUBTITLE') }}
    </p>

    <div
      class="relative mb-8 w-full overflow-hidden rounded-xl border border-border/50 bg-card/50 p-5 text-left shadow-sm backdrop-blur-sm"
    >
      <div
        class="pointer-events-none absolute right-0 top-0 h-32 w-32 translate-x-1/4 -translate-y-1/2 rounded-full bg-primary/5 blur-2xl"
      />

      <h3
        class="mb-4 flex items-center justify-between text-sm font-semibold text-foreground"
      >
        {{ t('CONTACTS_LAYOUT.EMPTY_STATE.GETTING_STARTED') }}
        <span
          class="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide text-primary"
        >
          {{
            t('CONTACTS_LAYOUT.EMPTY_STATE.STEP_BADGE', {
              current: currentStepNumber,
              total: steps.length,
            })
          }}
        </span>
      </h3>

      <div class="relative ml-1 flex flex-col">
        <div class="absolute bottom-3 left-[11px] top-3 z-0 w-px bg-border" />

        <div
          v-for="step in steps"
          :key="step.key"
          class="z-10 flex items-center gap-4 py-2.5"
          :class="{
            'opacity-60 transition-opacity hover:opacity-100':
              step.status === 'pending',
          }"
        >
          <div
            v-if="step.status === 'completed'"
            class="flex size-[22px] shrink-0 items-center justify-center rounded-full bg-primary ring-4 ring-card"
          >
            <span class="i-lucide-check size-3 text-primary-foreground" />
          </div>
          <div
            v-else-if="step.status === 'active'"
            class="flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-primary bg-card shadow-sm shadow-primary/20 ring-4 ring-card"
          >
            <div class="size-1.5 animate-pulse rounded-full bg-primary" />
          </div>
          <div
            v-else
            class="size-[22px] shrink-0 rounded-full border-2 border-muted-foreground/30 bg-card ring-4 ring-card"
          />

          <span
            class="text-sm"
            :class="{
              'font-medium text-muted-foreground line-through':
                step.status === 'completed',
              'font-semibold text-foreground': step.status === 'active',
              'font-medium text-foreground': step.status === 'pending',
            }"
          >
            {{ step.label }}
          </span>
        </div>
      </div>
    </div>

    <div
      v-if="showButton"
      class="mb-8 grid w-full grid-cols-1 gap-4 sm:grid-cols-2"
    >
      <button
        type="button"
        class="inline-flex h-14 items-center justify-start rounded-md border border-input bg-background px-4 shadow-xs transition-colors hover:border-transparent hover:bg-muted/50"
        @click="openImport"
      >
        <span
          class="mr-4 size-5 shrink-0 text-muted-foreground i-lucide-upload"
        />
        <span class="flex flex-col items-start">
          <span class="text-sm font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.IMPORT_CSV') }}
          </span>
          <span class="text-xs font-normal text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.IMPORT_CSV_HINT') }}
          </span>
        </span>
      </button>

      <button
        type="button"
        class="inline-flex h-14 items-center justify-start rounded-md border border-input bg-background px-4 shadow-xs transition-colors hover:border-transparent hover:bg-muted/50"
        @click="openCreate"
      >
        <span
          class="mr-4 size-5 shrink-0 text-muted-foreground i-lucide-user-plus"
        />
        <span class="flex flex-col items-start">
          <span class="text-sm font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.ADD_MANUALLY') }}
          </span>
          <span class="text-xs font-normal text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.EMPTY_STATE.ADD_MANUALLY_HINT') }}
          </span>
        </span>
      </button>
    </div>

    <router-link
      v-if="showCompaniesLink"
      :to="companiesRoute"
      class="mb-8 text-sm font-medium text-primary transition-colors hover:underline"
    >
      {{ t('CONTACTS_LAYOUT.EMPTY_STATE.GO_TO_COMPANIES') }}
    </router-link>

    <ContactImportDialog ref="contactImportDialogRef" @import="onImport" />
    <CreateNewContactDialog
      ref="createNewContactDialogRef"
      @create="emit('create', $event)"
    />
  </div>
</template>
