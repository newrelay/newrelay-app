<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { RelayBadge, RelayInput } from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';

const props = defineProps({
  show: { type: Boolean, default: false },
  company: { type: Object, default: () => ({}) },
  contacts: { type: Array, default: () => [] },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const searchQuery = ref('');

watch(
  () => props.show,
  isOpen => {
    if (!isOpen) searchQuery.value = '';
  }
);

const companyName = computed(
  () => props.company?.name || t('COMPANIES.UNNAMED')
);

const contactCount = computed(() => props.contacts.length);

const contactInitials = contact => {
  const name = contact.name || '';
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }
  return (name.slice(0, 2) || '?').toUpperCase();
};

const contactName = contact =>
  contact.name || t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT');

const filteredContacts = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return props.contacts;
  return props.contacts.filter(contact => {
    const name = contactName(contact).toLowerCase();
    const email = (contact.email || '').toLowerCase();
    return name.includes(query) || email.includes(query);
  });
});

const openContact = contactId => {
  emit('close');
  router.push({
    name: 'contacts_edit',
    params: {
      accountId: route.params.accountId,
      contactId,
    },
  });
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      data-relay
      class="flex items-center justify-center p-4 sm:p-6 animate-in fade-in duration-200"
      :class="RELAY_DIALOG_OVERLAY_CLASS"
    >
      <div class="absolute inset-0" @click="emit('close')" />
      <div
        class="relative flex max-h-[85vh] w-full max-w-4xl animate-in zoom-in-95 flex-col rounded-2xl border border-border/60 bg-card shadow-xl duration-200"
        @click.stop
      >
        <div
          class="flex shrink-0 items-center justify-between gap-4 border-b border-border/40 p-6"
        >
          <div class="shrink-0">
            <h3 class="text-lg font-semibold tracking-tight text-foreground">
              {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.MODAL.TITLE') }}
            </h3>
            <p class="mt-1 text-sm text-muted-foreground">
              {{
                t('COMPANIES.DETAIL.RECENT_CONTACTS.MODAL.SUBTITLE', {
                  count: contactCount,
                  company: companyName,
                })
              }}
            </p>
          </div>
          <div class="ml-auto flex w-full max-w-sm items-center gap-3">
            <div class="relative w-full">
              <span
                class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <RelayInput
                v-model="searchQuery"
                :placeholder="
                  t('COMPANIES.DETAIL.RECENT_CONTACTS.MODAL.SEARCH_PLACEHOLDER')
                "
                class-name="h-9 w-full rounded-md border-border/80 bg-background !pl-9 text-[13px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30 placeholder:text-muted-foreground"
              />
            </div>
            <button
              type="button"
              class="shrink-0 rounded-full p-2 text-muted-foreground transition-colors hover:bg-muted/50 hover:text-foreground"
              @click="emit('close')"
            >
              <span class="i-lucide-x size-5" />
            </button>
          </div>
        </div>

        <div class="flex-1 overflow-y-auto p-6">
          <div
            v-if="filteredContacts.length === 0"
            class="flex h-full flex-col items-center justify-center py-12 text-center"
          >
            <span class="i-lucide-users mb-3 size-8 text-muted-foreground" />
            <h3 class="text-sm font-medium text-foreground">
              {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.MODAL.EMPTY_TITLE') }}
            </h3>
            <p class="mt-1 text-xs text-muted-foreground">
              {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.MODAL.EMPTY_SUBTITLE') }}
            </p>
          </div>
          <div
            v-else
            class="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3"
          >
            <button
              v-for="contact in filteredContacts"
              :key="contact.id"
              type="button"
              class="flex items-center justify-between rounded-xl border border-border/40 p-3 text-left transition-colors hover:border-primary/20 hover:bg-muted/30"
              @click="openContact(contact.id)"
            >
              <div class="flex min-w-0 items-center gap-4">
                <div
                  class="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary/10 font-semibold text-primary"
                >
                  {{ contactInitials(contact) }}
                </div>
                <div class="flex min-w-0 flex-col">
                  <span
                    class="truncate text-[14px] font-medium text-foreground"
                  >
                    {{ contactName(contact) }}
                  </span>
                  <span class="truncate text-[13px] text-muted-foreground">
                    {{ contact.email || t('COMPANIES.EMPTY_VALUE') }}
                  </span>
                </div>
              </div>
              <RelayBadge
                v-if="contact.role === 'owner'"
                variant="secondary"
                class="rounded-full border-transparent bg-primary/10 px-2.5 font-medium text-primary hover:bg-primary/20"
              >
                {{ t('COMPANIES.DETAIL.RECENT_CONTACTS.OWNER') }}
              </RelayBadge>
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
