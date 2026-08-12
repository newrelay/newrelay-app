<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { RelayInput } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();

const fairDistributionLimit = defineModel('fairDistributionLimit', {
  type: Number,
  default: 100,
  set(value) {
    return Number(value) || 0;
  },
});

// Backend stores window in seconds; UI works in minutes then converts.
const fairDistributionWindow = defineModel('fairDistributionWindow', {
  type: Number,
  default: 3600,
  set(value) {
    return Number(value) || 0;
  },
});

const windowUnit = ref(DURATION_UNITS.HOURS);
const showTimeUnitDropdown = ref(false);

const windowInMinutes = computed({
  get() {
    return Math.floor((fairDistributionWindow.value || 0) / 60);
  },
  set(minutes) {
    fairDistributionWindow.value = minutes * 60;
  },
});

const displayWindowValue = computed({
  get() {
    const minutes = windowInMinutes.value || 0;
    if (windowUnit.value === DURATION_UNITS.DAYS) {
      return Math.floor(minutes / (24 * 60));
    }
    if (windowUnit.value === DURATION_UNITS.HOURS) {
      return Math.floor(minutes / 60);
    }
    return minutes;
  },
  set(value) {
    const n = Number(value) || 0;
    if (windowUnit.value === DURATION_UNITS.DAYS) {
      windowInMinutes.value = n * 24 * 60;
    } else if (windowUnit.value === DURATION_UNITS.HOURS) {
      windowInMinutes.value = n * 60;
    } else {
      windowInMinutes.value = n;
    }
  },
});

const unitLabel = computed(() => {
  if (windowUnit.value === DURATION_UNITS.DAYS) {
    return t('DURATION_INPUT.DAYS');
  }
  if (windowUnit.value === DURATION_UNITS.HOURS) {
    return t('DURATION_INPUT.HOURS');
  }
  return t('DURATION_INPUT.MINUTES');
});

const detectUnit = minutes => {
  const m = Number(minutes) || 0;
  if (m === 0) return DURATION_UNITS.HOURS;
  if (m % (24 * 60) === 0) return DURATION_UNITS.DAYS;
  if (m % 60 === 0) return DURATION_UNITS.HOURS;
  return DURATION_UNITS.MINUTES;
};

const closeUnitDropdown = () => {
  showTimeUnitDropdown.value = false;
};

const selectUnit = unit => {
  windowUnit.value = unit;
  showTimeUnitDropdown.value = false;
};

onMounted(() => {
  windowUnit.value = detectUnit(windowInMinutes.value);
});
</script>

<template>
  <div
    class="flex flex-wrap items-center gap-4 rounded-xl border border-border/40 bg-muted/20 p-4"
  >
    <div class="flex items-center gap-2.5">
      <label
        class="whitespace-nowrap text-[13.5px] font-medium text-foreground"
      >
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.FAIR_DISTRIBUTION.INPUT_MAX'
          )
        }}
      </label>
      <RelayInput
        v-model="fairDistributionLimit"
        type="number"
        class-name="h-9 w-24 px-3 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
      />
    </div>

    <div class="relative flex flex-wrap items-center gap-2.5">
      <label
        class="whitespace-nowrap text-[13.5px] font-medium text-foreground"
      >
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.FAIR_DISTRIBUTION.DURATION'
          )
        }}
      </label>
      <RelayInput
        v-model="displayWindowValue"
        type="number"
        class-name="h-9 w-20 px-3 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
      />
      <div v-on-click-outside="closeUnitDropdown" class="relative w-32">
        <button
          type="button"
          class="flex h-9 w-full items-center justify-between rounded-md border border-border/80 bg-background px-3 text-left text-[13.5px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
          @click="showTimeUnitDropdown = !showTimeUnitDropdown"
        >
          {{ unitLabel }}
          <Icon
            icon="i-lucide-chevron-right"
            class="size-4 text-muted-foreground transition-transform"
            :class="{ 'rotate-90': showTimeUnitDropdown }"
          />
        </button>
        <div
          v-if="showTimeUnitDropdown"
          class="absolute left-0 top-full z-50 mt-1 w-full overflow-hidden rounded-md border border-border/80 bg-card py-1 shadow-lg"
        >
          <button
            type="button"
            class="w-full px-3 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-muted"
            @click="selectUnit(DURATION_UNITS.MINUTES)"
          >
            {{ t('DURATION_INPUT.MINUTES') }}
          </button>
          <button
            type="button"
            class="w-full px-3 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-muted"
            @click="selectUnit(DURATION_UNITS.HOURS)"
          >
            {{ t('DURATION_INPUT.HOURS') }}
          </button>
          <button
            type="button"
            class="w-full px-3 py-1.5 text-left text-[13px] text-foreground transition-colors hover:bg-muted"
            @click="selectUnit(DURATION_UNITS.DAYS)"
          >
            {{ t('DURATION_INPUT.DAYS') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
