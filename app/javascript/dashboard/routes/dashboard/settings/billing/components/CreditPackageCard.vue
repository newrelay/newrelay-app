<script setup>
defineProps({
  credits: {
    type: Number,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
  },
  currency: {
    type: String,
    default: 'usd',
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  isPopular: {
    type: Boolean,
    default: false,
  },
  name: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['select']);

const formatCredits = credits => {
  return credits.toLocaleString();
};

const formatAmount = (amount, currency) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency.toUpperCase(),
    minimumFractionDigits: 0,
  }).format(amount);
};
</script>

<template>
  <label
    class="relative flex cursor-pointer flex-col rounded-xl border p-5 transition-all duration-200"
    :class="
      isSelected
        ? 'border-primary bg-primary/5 ring-1 ring-primary'
        : 'border-border bg-card hover:border-border/80 hover:bg-muted/30'
    "
  >
    <input
      type="radio"
      :name="name"
      :value="credits"
      :checked="isSelected"
      class="sr-only"
      @change="emit('select')"
    />
    <span
      v-if="isPopular"
      class="absolute -top-3 left-4 rounded bg-primary px-2 py-0.5 text-[11px] font-semibold text-primary-foreground shadow-sm"
    >
      {{ $t('BILLING_SETTINGS.TOPUP.POPULAR') }}
    </span>
    <span
      v-if="isSelected"
      class="i-lucide-circle-check-big absolute right-3 top-3 size-5 text-primary"
    />
    <span
      class="mb-1.5 text-[28px] font-normal leading-none tracking-tight text-foreground"
    >
      {{ formatCredits(credits) }}
    </span>
    <span
      class="mb-6 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
    >
      {{ $t('BILLING_SETTINGS.TOPUP.CREDITS') }}
    </span>
    <span class="flex items-baseline gap-1.5">
      <span class="text-[22px] font-normal text-foreground">
        {{ formatAmount(amount, currency) }}
      </span>
      <span class="text-[13px] font-medium text-muted-foreground">
        {{ $t('BILLING_SETTINGS.TOPUP.ONE_TIME') }}
      </span>
    </span>
  </label>
</template>
