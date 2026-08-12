<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  companies: { type: Array, required: true },
  visibleColumns: {
    type: Object,
    default: () => ({
      company: true,
      industry: true,
      phone: true,
      email: true,
      contacts: true,
      website: true,
      owner: true,
    }),
  },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 0 },
  itemsPerPage: { type: Number, default: 25 },
});

const emit = defineEmits(['showCompany', 'update:currentPage']);

const { t } = useI18n();

const emptyValue = computed(() => t('COMPANIES.EMPTY_VALUE'));

const startItem = computed(() =>
  props.totalItems === 0 ? 0 : (props.currentPage - 1) * props.itemsPerPage + 1
);
const endItem = computed(() =>
  Math.min(startItem.value + props.itemsPerPage - 1, props.totalItems)
);
const isFirstPage = computed(() => props.currentPage <= 1);
const isLastPage = computed(
  () => endItem.value >= props.totalItems || props.totalItems === 0
);

const attrsOf = company => company.additionalAttributes || {};

const displayName = company => company.name || t('COMPANIES.UNNAMED');
const industryOf = company => attrsOf(company).industry || emptyValue.value;
const phoneOf = company => attrsOf(company).phone || emptyValue.value;
const ownerOf = company => attrsOf(company).owner || emptyValue.value;
const websiteOf = company =>
  attrsOf(company).website || company.domain || emptyValue.value;
const websiteHref = company => {
  const value = attrsOf(company).website || company.domain;
  if (!value) return null;
  return value.startsWith('http') ? value : `https://${value}`;
};

const openCompany = id => {
  emit('showCompany', id);
};
</script>

<template>
  <div
    class="overflow-hidden rounded-2xl border border-border/60 bg-card shadow-xs"
  >
    <div class="overflow-x-auto">
      <table class="w-full whitespace-nowrap text-left text-sm">
        <thead
          class="border-b border-border/60 bg-muted/30 text-[14px] text-muted-foreground"
        >
          <tr>
            <th v-if="visibleColumns.company" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.COMPANY') }}
            </th>
            <th v-if="visibleColumns.industry" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.INDUSTRY') }}
            </th>
            <th v-if="visibleColumns.contacts" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.CONTACTS') }}
            </th>
            <th v-if="visibleColumns.phone" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.PHONE') }}
            </th>
            <th v-if="visibleColumns.email" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.EMAIL') }}
            </th>
            <th v-if="visibleColumns.website" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.WEBSITE') }}
            </th>
            <th v-if="visibleColumns.owner" class="px-5 py-3.5 font-medium">
              {{ t('COMPANIES.COLUMNS.OWNER') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border/40">
          <tr
            v-for="company in companies"
            :key="company.id"
            class="group cursor-pointer transition-colors hover:bg-muted/20"
            @click="openCompany(company.id)"
          >
            <td v-if="visibleColumns.company" class="px-5 py-4">
              <div class="flex items-center gap-3">
                <div
                  class="flex size-9 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-border/50 bg-background shadow-xs"
                >
                  <Avatar
                    :name="displayName(company)"
                    :src="company.avatarUrl || null"
                    :size="24"
                    hide-offline-status
                  />
                </div>
                <span
                  class="font-medium text-foreground transition-colors group-hover:text-primary"
                >
                  {{ displayName(company) }}
                </span>
              </div>
            </td>
            <td
              v-if="visibleColumns.industry"
              class="px-5 py-4 text-muted-foreground"
            >
              {{ industryOf(company) }}
            </td>
            <td
              v-if="visibleColumns.contacts"
              class="px-5 py-4 text-muted-foreground"
            >
              {{ Number(company.contactsCount || 0) }}
            </td>
            <td
              v-if="visibleColumns.phone"
              class="px-5 py-4 text-muted-foreground"
            >
              {{ phoneOf(company) }}
            </td>
            <td v-if="visibleColumns.email" class="px-5 py-4">
              <a
                v-if="attrsOf(company).email"
                :href="`mailto:${attrsOf(company).email}`"
                class="text-foreground hover:text-primary hover:underline"
                @click.stop
              >
                {{ attrsOf(company).email }}
              </a>
              <span v-else class="text-muted-foreground">{{ emptyValue }}</span>
            </td>
            <td v-if="visibleColumns.website" class="px-5 py-4">
              <a
                v-if="websiteHref(company)"
                :href="websiteHref(company)"
                target="_blank"
                rel="noopener noreferrer"
                class="text-muted-foreground hover:text-primary hover:underline"
                @click.stop
              >
                {{ websiteOf(company) }}
              </a>
              <span v-else class="text-muted-foreground">{{ emptyValue }}</span>
            </td>
            <td v-if="visibleColumns.owner" class="px-5 py-4 text-foreground">
              {{ ownerOf(company) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div
      class="flex items-center justify-between border-t border-border/60 bg-muted/10 p-3 text-xs text-muted-foreground"
    >
      <span class="pl-2">
        {{
          t('COMPANIES_LAYOUT.PAGINATION_FOOTER.SHOWING', {
            startItem,
            endItem,
            totalItems,
          })
        }}
      </span>
      <div class="flex items-center gap-1.5">
        <button
          type="button"
          class="h-7 rounded-md px-3 text-xs font-medium transition-colors hover:bg-accent disabled:pointer-events-none disabled:opacity-40"
          :disabled="isFirstPage"
          @click="emit('update:currentPage', currentPage - 1)"
        >
          {{ t('COMPANIES_LAYOUT.PAGINATION_FOOTER.PREVIOUS') }}
        </button>
        <button
          type="button"
          class="h-7 rounded-md px-3 text-xs font-medium transition-colors hover:bg-accent disabled:pointer-events-none disabled:opacity-40"
          :disabled="isLastPage"
          @click="emit('update:currentPage', currentPage + 1)"
        >
          {{ t('COMPANIES_LAYOUT.PAGINATION_FOOTER.NEXT') }}
        </button>
      </div>
    </div>
  </div>
</template>
