<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayBadge, RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  variant: {
    type: String,
    default: 'deals',
    validator: value => ['deals', 'opportunities'].includes(value),
  },
});

const emit = defineEmits(['create']);
const { t } = useI18n();

const isOpportunities = computed(() => props.variant === 'opportunities');
const i18nKey = computed(() =>
  isOpportunities.value ? 'OPPORTUNITIES.EMPTY' : 'DEALS.EMPTY'
);

const whyCards = computed(() =>
  isOpportunities.value
    ? [
        { key: 'ONE', icon: 'i-lucide-layout-dashboard' },
        { key: 'TWO', icon: 'i-lucide-trending-up' },
        { key: 'THREE', icon: 'i-lucide-check-square' },
        { key: 'FOUR', icon: 'i-lucide-dollar-sign' },
      ]
    : [
        { key: 'ONE', icon: 'i-lucide-dollar-sign' },
        { key: 'TWO', icon: 'i-lucide-layout-dashboard' },
        { key: 'THREE', icon: 'i-lucide-trending-up' },
        { key: 'FOUR', icon: 'i-lucide-check-square' },
      ]
);
</script>

<template>
  <div
    class="mx-auto flex w-full max-w-5xl flex-col items-center animate-in fade-in zoom-in-95 duration-700"
  >
    <div class="mb-10 flex w-full flex-col items-center text-center">
      <div
        class="mb-6 flex size-16 items-center justify-center rounded-full bg-primary/10 ring-8 ring-primary/5"
      >
        <span
          class="size-8 text-primary"
          :class="isOpportunities ? 'i-lucide-target' : 'i-lucide-dollar-sign'"
        />
      </div>
      <h2 class="mb-2 text-[20px] font-[600] tracking-tight text-foreground">
        {{ t(`${i18nKey}.TITLE`) }}
      </h2>
      <p class="mb-6 max-w-lg text-sm leading-relaxed text-muted-foreground">
        {{ t(`${i18nKey}.SUBTITLE`) }}
      </p>
    </div>

    <div class="mb-16 grid w-full max-w-4xl gap-8 md:grid-cols-2">
      <div
        class="group relative overflow-hidden rounded-3xl border border-border/50 bg-card p-8 shadow-sm"
      >
        <div
          class="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-transparent opacity-0 transition-opacity duration-500 group-hover:opacity-100"
        />
        <div class="relative z-10">
          <div class="mb-8 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-foreground">
              {{ t(`${i18nKey}.GETTING_STARTED`) }}
            </h3>
            <RelayBadge
              variant="secondary"
              class="rounded-full border-none bg-primary/10 px-2.5 py-0.5 text-xs font-medium text-primary"
            >
              {{ t(`${i18nKey}.STEP_BADGE`) }}
            </RelayBadge>
          </div>

          <div class="relative space-y-6">
            <div
              class="absolute bottom-3 left-[11px] top-3 z-0 w-px bg-border"
            />

            <div class="relative z-10 flex items-start gap-4">
              <div
                class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full bg-primary ring-4 ring-card"
              >
                <span class="i-lucide-check size-3 text-primary-foreground" />
              </div>
              <p
                class="text-sm font-medium text-foreground line-through opacity-60"
              >
                {{ t(`${i18nKey}.STEP_WORKSPACE`) }}
              </p>
            </div>

            <template v-if="isOpportunities">
              <div class="relative z-10 flex items-start gap-4">
                <div
                  class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-primary bg-card shadow-sm shadow-primary/20 ring-4 ring-card"
                >
                  <div class="size-1.5 animate-pulse rounded-full bg-primary" />
                </div>
                <div>
                  <p class="text-sm font-semibold text-foreground">
                    {{ t(`${i18nKey}.STEP_CONTACTS`) }}
                  </p>
                  <p class="mt-1 text-xs leading-relaxed text-muted-foreground">
                    {{ t(`${i18nKey}.STEP_CONTACTS_HINT`) }}
                  </p>
                </div>
              </div>

              <div
                class="relative z-10 flex items-start gap-4 opacity-60 transition-opacity hover:opacity-100"
              >
                <div
                  class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full bg-muted ring-4 ring-card"
                />
                <p class="text-sm font-medium text-muted-foreground">
                  {{ t(`${i18nKey}.STEP_STAGES`) }}
                </p>
              </div>

              <div
                class="relative z-10 flex items-start gap-4 opacity-60 transition-opacity hover:opacity-100"
              >
                <div
                  class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full bg-muted ring-4 ring-card"
                />
                <p class="text-sm font-medium text-muted-foreground">
                  {{ t(`${i18nKey}.STEP_CREATE`) }}
                </p>
              </div>
            </template>

            <template v-else>
              <div class="relative z-10 flex items-start gap-4">
                <div
                  class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full bg-primary ring-4 ring-card"
                >
                  <span class="i-lucide-check size-3 text-primary-foreground" />
                </div>
                <p
                  class="text-sm font-medium text-foreground line-through opacity-60"
                >
                  {{ t(`${i18nKey}.STEP_CONTACTS`) }}
                </p>
              </div>

              <div class="relative z-10 flex items-start gap-4">
                <div
                  class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full bg-primary ring-4 ring-card"
                >
                  <span class="i-lucide-check size-3 text-primary-foreground" />
                </div>
                <p
                  class="text-sm font-medium text-foreground line-through opacity-60"
                >
                  {{ t(`${i18nKey}.STEP_COMPANY`) }}
                </p>
              </div>

              <div class="relative z-10 flex items-start gap-4">
                <div
                  class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-primary bg-card shadow-sm shadow-primary/20 ring-4 ring-card"
                >
                  <div class="size-1.5 animate-pulse rounded-full bg-primary" />
                </div>
                <div>
                  <p class="text-sm font-semibold text-foreground">
                    {{ t(`${i18nKey}.STEP_CREATE`) }}
                  </p>
                  <p class="mt-1 text-xs leading-relaxed text-muted-foreground">
                    {{ t(`${i18nKey}.STEP_CREATE_HINT`) }}
                  </p>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>

      <div class="flex flex-col justify-center gap-4">
        <div
          class="flex flex-col gap-4 rounded-3xl border border-border/50 bg-card p-8 shadow-sm"
        >
          <h3 class="mb-2 text-lg font-semibold text-foreground">
            {{ t(`${i18nKey}.ADD_TITLE`) }}
          </h3>
          <RelayButton
            class="group h-12 w-full rounded-xl !text-base shadow-sm"
            @click="emit('create')"
          >
            <span
              class="i-lucide-plus mr-2 size-5 transition-transform duration-300 group-hover:rotate-90"
            />
            {{ t(`${i18nKey}.CREATE`) }}
          </RelayButton>

          <div class="relative flex items-center py-3">
            <div class="flex-grow border-t border-border/60" />
            <span
              class="mx-4 flex-shrink-0 text-xs font-medium uppercase tracking-widest text-muted-foreground"
            >
              {{ t(`${i18nKey}.OR_IMPORT`) }}
            </span>
            <div class="flex-grow border-t border-border/60" />
          </div>

          <div class="grid grid-cols-1 gap-3">
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-start gap-3 rounded-xl border-border/60 text-muted-foreground hover:bg-accent hover:text-foreground"
              @click="emit('loadMock')"
            >
              <span class="i-lucide-upload size-4 text-foreground/70" />
              {{ t(`${i18nKey}.UPLOAD_CSV`) }}
            </RelayButton>
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-start gap-3 rounded-xl border-border/60 text-muted-foreground hover:bg-accent hover:text-foreground"
              @click="emit('loadMock')"
            >
              <span class="i-lucide-import size-4 text-foreground/70" />
              {{ t(`${i18nKey}.IMPORT_HUBSPOT`) }}
            </RelayButton>
            <RelayButton
              v-if="!isOpportunities"
              variant="outline"
              class="h-11 w-full justify-start gap-3 rounded-xl border-border/60 text-muted-foreground hover:bg-accent hover:text-foreground"
              @click="emit('loadMock')"
            >
              <span class="i-lucide-import size-4 text-foreground/70" />
              {{ t(`${i18nKey}.IMPORT_SALESFORCE`) }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>

    <div class="w-full max-w-5xl">
      <h4
        class="mb-8 text-center text-xs font-semibold uppercase tracking-widest text-muted-foreground"
      >
        {{ t(`${i18nKey}.WHY_TITLE`) }}
      </h4>
      <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
        <div
          v-for="card in whyCards"
          :key="card.key"
          class="rounded-2xl border border-border/40 bg-card p-6 text-center shadow-sm transition-colors hover:border-border/80"
        >
          <div
            class="mx-auto mb-4 flex size-12 items-center justify-center rounded-xl border border-primary/20 bg-primary/10 text-primary"
          >
            <span class="size-5" :class="card.icon" />
          </div>
          <h5 class="mb-2 text-sm font-semibold text-foreground">
            {{ t(`${i18nKey}.WHY.${card.key}.TITLE`) }}
          </h5>
          <p class="text-xs leading-relaxed text-muted-foreground">
            {{ t(`${i18nKey}.WHY.${card.key}.DESC`) }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
