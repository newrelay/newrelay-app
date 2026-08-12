<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';

const props = defineProps({
  attribute: {
    type: Object,
    required: true,
  },
  badges: {
    type: Array,
    default: () => [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete']);
const { t } = useI18n();

const typeLabel = computed(() => {
  const typeKey = (props.attribute.type || '').toLowerCase();
  const labels = {
    text: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.TEXT'),
    number: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.NUMBER'),
    link: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.LINK'),
    date: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.DATE'),
    list: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.LIST'),
    checkbox: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.CHECKBOX'),
  };
  return labels[typeKey] || props.attribute.type;
});

const metaLine = computed(() => {
  const parts = [props.attribute.value, typeLabel.value].filter(Boolean);
  return parts.join(' • ');
});
</script>

<template>
  <div
    class="group flex items-center justify-between gap-4 p-4 rounded-xl border border-border/80 bg-card hover:border-primary/30 transition-all shadow-2xs"
  >
    <div class="flex min-w-0 items-center gap-4">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 border border-primary/20 text-primary"
      >
        <Icon icon="i-lucide-code" class="size-5" />
      </div>
      <div class="min-w-0">
        <div class="flex min-w-0 flex-wrap items-center gap-2">
          <h4 class="truncate text-sm font-semibold text-foreground">
            {{ attribute.label }}
          </h4>
          <RelayBadge
            v-for="badge in badges"
            :key="badge.type"
            variant="secondary"
            class="text-[11px]"
          >
            {{
              badge.type === 'pre-chat'
                ? t('ATTRIBUTES_MGMT.BADGES.PRE_CHAT')
                : t('ATTRIBUTES_MGMT.BADGES.RESOLUTION')
            }}
          </RelayBadge>
        </div>
        <p class="mt-0.5 truncate text-xs text-muted-foreground">
          {{ metaLine }}
        </p>
      </div>
    </div>

    <div class="flex shrink-0 items-center gap-2">
      <RelayButton
        variant="outline"
        size="sm"
        class="h-8 border-border/80 bg-background px-3 text-xs shadow-2xs hover:bg-muted font-medium"
        :disabled="loading"
        @click="emit('edit', attribute)"
      >
        {{ t('ATTRIBUTES_MGMT.LIST.BUTTONS.EDIT', 'Edit') }}
      </RelayButton>
      <RelayButton
        v-tooltip.top="t('ATTRIBUTES_MGMT.LIST.BUTTONS.DELETE')"
        variant="ghost"
        size="icon"
        class="size-8 text-muted-foreground hover:text-destructive"
        :disabled="loading"
        @click="emit('delete', attribute)"
      >
        <Icon icon="i-lucide-trash-2" class="size-3.5" />
      </RelayButton>
    </div>
  </div>
</template>
