<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();
const isExpanded = ref(false);

const attributes = ['email', 'first_name', 'last_name'];

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
};
</script>

<template>
  <div
    class="bg-muted/10 transition-colors"
    :class="{ 'bg-muted/20': isExpanded }"
  >
    <button
      type="button"
      class="flex w-full items-center justify-between p-3 text-left"
      @click="toggleExpanded"
    >
      <span class="text-[13px] font-medium text-foreground">
        {{ t('SECURITY_SETTINGS.SAML.ATTRIBUTE_MAPPING.TITLE') }}
      </span>
      <Icon
        icon="i-lucide-chevron-down"
        class="size-4 text-muted-foreground transition-transform"
        :class="{ 'rotate-180': isExpanded }"
      />
    </button>

    <div v-if="isExpanded" class="p-3 pt-0">
      <p class="mb-3 text-[12.5px] text-muted-foreground">
        {{ t('SECURITY_SETTINGS.SAML.ATTRIBUTE_MAPPING.DESCRIPTION') }}
      </p>
      <div class="flex flex-col gap-2">
        <div
          v-for="attribute in attributes"
          :key="attribute"
          class="w-fit rounded border border-border bg-background px-2 py-1 font-mono text-[12px] text-foreground shadow-xs"
        >
          {{ attribute }}
        </div>
      </div>
    </div>
  </div>
</template>
