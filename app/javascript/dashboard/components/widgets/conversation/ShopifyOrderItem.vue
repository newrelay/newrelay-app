<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const formatDate = dateString => {
  return format(new Date(dateString), 'MMM d, yyyy');
};

const formatCurrency = (amount, currency) => {
  return new Intl.NumberFormat('en', {
    style: 'currency',
    currency: currency || 'USD',
  }).format(amount);
};

const getStatusClass = status => {
  const classes = {
    paid: 'bg-success/20 text-success',
  };
  return classes[status] || 'bg-accent text-foreground';
};

const getStatusI18nKey = (type, status = '') => {
  return `CONVERSATION_SIDEBAR.SHOPIFY.${type.toUpperCase()}_STATUS.${status.toUpperCase()}`;
};

const fulfillmentStatus = computed(() => {
  const { fulfillment_status: status } = props.order;
  if (!status) {
    return '';
  }
  return t(getStatusI18nKey('FULFILLMENT', status));
});

const financialStatus = computed(() => {
  const { financial_status: status } = props.order;
  if (!status) {
    return '';
  }
  return t(getStatusI18nKey('FINANCIAL', status));
});

const getFulfillmentClass = status => {
  const classes = {
    fulfilled: 'text-success',
    partial: 'text-warning',
    unfulfilled: 'text-destructive',
  };
  return classes[status] || 'text-muted-foreground';
};
</script>

<template>
  <div
    class="py-3 border-b border-border last:border-b-0 flex flex-col gap-1.5"
  >
    <div class="flex justify-between items-center">
      <div class="font-medium flex">
        <a
          :href="order.admin_url"
          target="_blank"
          rel="noopener noreferrer"
          class="hover:underline text-foreground cursor-pointer truncate"
        >
          {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.ORDER_ID', { id: order.id }) }}
          <i class="i-lucide-external-link pl-5" />
        </a>
      </div>
      <div
        :class="getStatusClass(order.financial_status)"
        class="text-xs px-2 py-1 rounded capitalize truncate"
        :title="financialStatus"
      >
        {{ financialStatus }}
      </div>
    </div>
    <div class="text-sm text-foreground">
      <span class="text-muted-foreground border-r border-border pr-2">
        {{ formatDate(order.created_at) }}
      </span>
      <span class="text-muted-foreground pl-2">
        {{ formatCurrency(order.total_price, order.currency) }}
      </span>
    </div>
    <div v-if="fulfillmentStatus">
      <span
        :class="getFulfillmentClass(order.fulfillment_status)"
        class="capitalize font-medium"
        :title="fulfillmentStatus"
      >
        {{ fulfillmentStatus }}
      </span>
    </div>
  </div>
</template>
