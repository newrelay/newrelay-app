<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

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
  isPreview: { type: Boolean, default: false },
});

const emit = defineEmits(['showCompany', 'update:currentPage']);

const { t } = useI18n();

const emptyValue = computed(() => t('COMPANIES.EMPTY_VALUE'));

const attrsOf = company => company.additionalAttributes || {};

const displayName = company => company.name || t('COMPANIES.UNNAMED');
const industryOf = company => attrsOf(company).industry || null;
const phoneOf = company => attrsOf(company).phone || null;
const ownerOf = company => attrsOf(company).owner || null;
const websiteOf = company => attrsOf(company).website || company.domain || null;
const websiteHref = company => {
  const value = attrsOf(company).website || company.domain;
  if (!value) return null;
  return value.startsWith('http') ? value : `https://${value}`;
};

// Inline phone formatter — groups raw digit strings for readability
const formatPhone = raw => {
  if (!raw) return raw;
  // Already has formatting chars — show as-is
  if (/[-().+ ]/.test(raw.trim())) return raw.trim();
  const digits = raw.replace(/\D/g, '');
  // 10-digit (US): (XXX) XXX-XXXX
  if (digits.length === 10) {
    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
  }
  // 11-digit US with country code: +1 (XXX) XXX-XXXX
  if (digits.length === 11 && digits[0] === '1') {
    return `+1 (${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`;
  }
  // Generic: space-separate every 3 digits
  return digits.replace(/(\d{3})(?=\d)/g, '$1 ');
};

const openCompany = id => {
  if (props.isPreview) return;
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
          class="border-b border-border/60 bg-muted/30 text-[14px] font-semibold capitalize text-muted-foreground"
        >
          <tr>
            <th v-if="visibleColumns.company" class="px-4 py-2.5">
              {{ t('COMPANIES.COLUMNS.COMPANY') }}
            </th>
            <th v-if="visibleColumns.industry" class="py-2.5 pl-3 pr-4">
              {{ t('COMPANIES.COLUMNS.INDUSTRY') }}
            </th>
            <th v-if="visibleColumns.contacts" class="px-4 py-2.5">
              {{ t('COMPANIES.COLUMNS.CONTACTS') }}
            </th>
            <th v-if="visibleColumns.phone" class="px-4 py-2.5">
              {{ t('COMPANIES.COLUMNS.PHONE') }}
            </th>
            <th v-if="visibleColumns.email" class="px-4 py-2.5">
              {{ t('COMPANIES.COLUMNS.EMAIL') }}
            </th>
            <th v-if="visibleColumns.website" class="px-4 py-2.5">
              {{ t('COMPANIES.COLUMNS.WEBSITE') }}
            </th>
            <th v-if="visibleColumns.owner" class="py-2.5 pl-3 pr-4">
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
            <td v-if="visibleColumns.company" class="px-4 py-3">
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
              class="py-3 pl-3 pr-4 text-muted-foreground"
            >
              <span v-if="industryOf(company)">{{ industryOf(company) }}</span>
              <span v-else class="text-[11px]">{{ emptyValue }}</span>
            </td>
            <td
              v-if="visibleColumns.contacts"
              class="px-4 py-3 text-muted-foreground"
            >
              {{ Number(company.contactsCount || 0) }}
            </td>
            <td
              v-if="visibleColumns.phone"
              class="px-4 py-3 text-muted-foreground"
            >
              <span v-if="phoneOf(company)" class="tabular-nums">{{
                formatPhone(phoneOf(company))
              }}</span>
              <span v-else class="text-[11px]">{{ emptyValue }}</span>
            </td>
            <td v-if="visibleColumns.email" class="px-4 py-3">
              <a
                v-if="attrsOf(company).email"
                :href="`mailto:${attrsOf(company).email}`"
                class="text-foreground hover:text-primary hover:underline"
                @click.stop
              >
                {{ attrsOf(company).email }}
              </a>
              <span v-else class="text-[11px] text-muted-foreground">{{
                emptyValue
              }}</span>
            </td>
            <td v-if="visibleColumns.website" class="px-4 py-3">
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
              <span v-else class="text-[11px] text-muted-foreground">{{
                emptyValue
              }}</span>
            </td>
            <td
              v-if="visibleColumns.owner"
              class="py-3 pl-3 pr-4 text-foreground"
            >
              <span v-if="ownerOf(company)">{{ ownerOf(company) }}</span>
              <span v-else class="text-[11px] text-muted-foreground">{{
                emptyValue
              }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <PaginationFooter
      current-page-info="COMPANIES_LAYOUT.PAGINATION_FOOTER.SHOWING"
      :current-page="currentPage"
      :total-items="totalItems"
      :items-per-page="itemsPerPage"
      @update:current-page="emit('update:currentPage', $event)"
    />
  </div>
</template>
