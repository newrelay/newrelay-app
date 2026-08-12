<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import ContactCustomAttributeItem from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributeItem.vue';
import { RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const { uiSettings } = useUISettings();

const searchQuery = ref('');

const contactAttributes = useMapGetter('attributes/getContactAttributes') || [];

const hasContactAttributes = computed(
  () => contactAttributes.value?.length > 0
);

const processContactAttributes = (
  attributes,
  customAttributes,
  filterCondition
) => {
  if (!attributes.length || !customAttributes) {
    return [];
  }

  return attributes.reduce((result, attribute) => {
    const { attributeKey } = attribute;
    const meetsCondition = filterCondition(attributeKey, customAttributes);

    if (meetsCondition) {
      result.push({
        ...attribute,
        value: customAttributes[attributeKey] ?? '',
      });
    }

    return result;
  }, []);
};

const sortAttributesOrder = computed(
  () =>
    uiSettings.value.conversation_elements_order_conversation_contact_panel ??
    []
);

const sortByUISettings = attributes => {
  const order = sortAttributesOrder.value;
  if (!order?.length) return attributes;

  const orderMap = new Map(order.map((key, index) => [key, index]));

  return [...attributes].sort((a, b) => {
    const aPos = orderMap.get(a.attributeKey) ?? Infinity;
    const bPos = orderMap.get(b.attributeKey) ?? Infinity;
    return aPos - bPos;
  });
};

const usedAttributes = computed(() => {
  const attributes = processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => key in custom
  );

  return sortByUISettings(attributes);
});

const unusedAttributes = computed(() => {
  const attributes = processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => !(key in custom)
  );

  return sortByUISettings(attributes);
});

const filteredUnusedAttributes = computed(() => {
  return unusedAttributes.value?.filter(attribute =>
    attribute.attributeDisplayName
      .toLowerCase()
      .includes(searchQuery.value.toLowerCase())
  );
});

const unusedAttributesCount = computed(() => unusedAttributes.value?.length);
const hasNoUnusedAttributes = computed(() => unusedAttributesCount.value === 0);
const hasNoUsedAttributes = computed(() => usedAttributes.value.length === 0);

const showEmptyPlaceholder = computed(
  () => !hasContactAttributes.value || hasNoUsedAttributes.value
);
</script>

<template>
  <div
    v-if="showEmptyPlaceholder && hasNoUnusedAttributes"
    class="mx-auto flex h-full max-w-sm flex-col items-center justify-center py-16 text-center opacity-60"
  >
    <div
      class="mb-4 flex size-12 items-center justify-center rounded-full bg-muted"
    >
      <span class="i-lucide-user size-6 text-muted-foreground" />
    </div>
    <h3 class="mb-1 text-sm font-medium text-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.TABS.ATTRIBUTES') }}
    </h3>
    <p class="text-xs text-muted-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.EMPTY_PLACEHOLDER') }}
    </p>
  </div>

  <div v-else-if="hasContactAttributes" class="flex flex-col gap-6">
    <div v-if="!hasNoUsedAttributes" class="flex flex-col gap-2">
      <ContactCustomAttributeItem
        v-for="attribute in usedAttributes"
        :key="attribute.id"
        is-editing-view
        :attribute="attribute"
      />
    </div>
    <div v-if="!hasNoUnusedAttributes" class="flex items-center gap-3">
      <div class="h-px flex-1 bg-border" />
      <span class="text-sm font-medium text-muted-foreground">{{
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.UNUSED_ATTRIBUTES', {
          count: unusedAttributesCount,
        })
      }}</span>
      <div class="h-px flex-1 bg-border" />
    </div>
    <div class="flex flex-col gap-3">
      <div v-if="!hasNoUnusedAttributes" class="relative">
        <span
          class="i-lucide-search absolute left-3 top-2.5 size-3.5 text-muted-foreground"
        />
        <RelayInput
          v-model="searchQuery"
          type="search"
          :placeholder="
            t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.SEARCH_PLACEHOLDER')
          "
          class-name="h-8 w-full py-2 pl-10 pr-2 text-sm rounded-lg border-border/80 bg-muted/40"
        />
      </div>
      <div
        v-if="filteredUnusedAttributes.length === 0 && !hasNoUnusedAttributes"
        class="flex h-11 items-center justify-start"
      >
        <p class="text-sm text-muted-foreground">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.NO_ATTRIBUTES') }}
        </p>
      </div>
      <div v-if="!hasNoUnusedAttributes" class="flex flex-col gap-2">
        <ContactCustomAttributeItem
          v-for="attribute in filteredUnusedAttributes"
          :key="attribute.id"
          :attribute="attribute"
        />
      </div>
    </div>
  </div>

  <div
    v-else
    class="mx-auto flex h-full max-w-sm flex-col items-center justify-center py-16 text-center opacity-60"
  >
    <div
      class="mb-4 flex size-12 items-center justify-center rounded-full bg-muted"
    >
      <span class="i-lucide-user size-6 text-muted-foreground" />
    </div>
    <h3 class="mb-1 text-sm font-medium text-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.TABS.ATTRIBUTES') }}
    </h3>
    <p class="text-xs text-muted-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.EMPTY_PLACEHOLDER') }}
    </p>
  </div>
</template>
