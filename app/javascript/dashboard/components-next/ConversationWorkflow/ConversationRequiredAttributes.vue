<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ConversationRequiredAttributeItem from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributeItem.vue';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const props = defineProps({
  isEnabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click']);
const router = useRouter();
const { t } = useI18n();
const { currentAccount, accountId, isOnChatwootCloud, updateAccount } =
  useAccount();
const [showDropdown, toggleDropdown] = useToggle(false);
const [isSaving, toggleSaving] = useToggle(false);
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);
const currentUser = useMapGetter('getCurrentUser');

const isSuperAdmin = computed(() => currentUser.value.type === 'SuperAdmin');
const showPaywall = computed(() => !props.isEnabled && isOnChatwootCloud.value);
const i18nKey = computed(() =>
  isOnChatwootCloud.value ? 'PAYWALL' : 'ENTERPRISE_PAYWALL'
);

const goToBillingSettings = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

const handleClick = () => {
  emit('click');
};

const selectedAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const allAttributeOptions = computed(() =>
  (conversationAttributes.value || []).map(attribute => ({
    ...attribute,
    action: 'add',
    value: attribute.attributeKey,
    label: attribute.attributeDisplayName,
    type: attribute.attributeDisplayType,
  }))
);

const attributeOptions = computed(() => {
  const selectedKeysSet = new Set(selectedAttributeKeys.value);
  return allAttributeOptions.value.filter(
    attribute => !selectedKeysSet.has(attribute.value)
  );
});

const conversationRequiredAttributes = computed(() => {
  const attributeMap = new Map(
    allAttributeOptions.value.map(attr => [attr.value, attr])
  );
  return selectedAttributeKeys.value
    .map(key => attributeMap.get(key))
    .filter(Boolean);
});

const handleAddAttributesClick = event => {
  event.stopPropagation();
  toggleDropdown();
};

const saveRequiredAttributes = async keys => {
  try {
    toggleSaving(true);
    await updateAccount(
      { conversation_required_attributes: keys },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.ERROR'));
  } finally {
    toggleSaving(false);
    toggleDropdown(false);
  }
};

const handleAttributeAction = ({ value }) => {
  if (!value || isSaving.value) return;
  const updatedKeys = Array.from(
    new Set([...selectedAttributeKeys.value, value])
  );
  saveRequiredAttributes(updatedKeys);
};

const closeDropdown = () => {
  toggleDropdown(false);
};

const handleDelete = attribute => {
  if (isSaving.value) return;
  const updatedKeys = selectedAttributeKeys.value.filter(
    key => key !== attribute.value
  );
  saveRequiredAttributes(updatedKeys);
};
</script>

<template>
  <div
    v-if="isEnabled || showPaywall"
    class="bg-card border-border/60 overflow-hidden rounded-xl border shadow-xs"
    @click="handleClick"
  >
    <div class="p-5 sm:p-6">
      <div
        class="mb-6 flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
      >
        <div>
          <h3 class="text-foreground text-[16px] font-semibold">
            {{ $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.TITLE') }}
          </h3>
          <p class="text-muted-foreground mt-1.5 text-[13.5px] leading-relaxed">
            {{ $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.DESCRIPTION') }}
          </p>
        </div>
        <div v-if="isEnabled" v-on-clickaway="closeDropdown" class="relative">
          <RelayButton
            variant="outline"
            class="border-primary/20 text-primary hover:border-primary/40 hover:bg-primary/5 hover:text-primary h-9 shrink-0 font-medium transition-all"
            :disabled="isSaving || attributeOptions.length === 0"
            @click="handleAddAttributesClick"
          >
            <Icon icon="i-lucide-plus" class="size-4" />
            {{ $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.ADD.TITLE') }}
          </RelayButton>
          <DropdownMenu
            v-if="showDropdown"
            :menu-items="attributeOptions"
            show-search
            :search-placeholder="
              $t(
                'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.ADD.SEARCH_PLACEHOLDER'
              )
            "
            class="top-full mt-1 w-52 ltr:right-0 rtl:left-0"
            @action="handleAttributeAction"
          />
        </div>
      </div>

      <template v-if="isEnabled">
        <div
          v-if="conversationRequiredAttributes.length === 0"
          class="border-border/80 bg-muted/10 flex items-center justify-center rounded-lg border border-dashed p-6 sm:p-8"
        >
          <p class="text-muted-foreground text-[14px] font-medium">
            {{ $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.NO_ATTRIBUTES') }}
          </p>
        </div>

        <div
          v-else
          class="border-border/40 divide-y overflow-hidden rounded-lg border"
        >
          <ConversationRequiredAttributeItem
            v-for="attribute in conversationRequiredAttributes"
            :key="attribute.value"
            :attribute="attribute"
            @delete="handleDelete"
          />
        </div>
      </template>

      <BasePaywallModal
        v-else
        class="mx-auto my-8"
        feature-prefix="CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES"
        :i18n-key="i18nKey"
        :is-on-chatwoot-cloud="isOnChatwootCloud"
        :is-super-admin="isSuperAdmin"
        @upgrade="goToBillingSettings"
      />
    </div>
  </div>
</template>
