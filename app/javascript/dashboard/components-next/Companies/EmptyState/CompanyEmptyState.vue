<script setup>
import { useI18n } from 'vue-i18n';
import { RelayBadge, RelayButton } from 'dashboard/components-next/relay';

defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
});

const emit = defineEmits(['create', 'import']);
const { t } = useI18n();
</script>

<template>
  <div
    class="mx-auto flex w-full max-w-5xl flex-col items-center animate-in fade-in zoom-in-95 duration-700"
  >
    <div class="mb-10 flex w-full flex-col items-center text-center">
      <div
        class="mb-6 flex size-16 items-center justify-center rounded-full bg-primary/10 ring-8 ring-primary/5"
      >
        <span class="i-lucide-building-2 size-8 text-primary" />
      </div>
      <h2 class="mb-2 text-base font-medium tracking-tight text-foreground">
        {{ title || t('COMPANIES.EMPTY_STATE.TITLE') }}
      </h2>
      <p class="mb-6 max-w-lg text-sm leading-relaxed text-muted-foreground">
        {{ subtitle || t('COMPANIES.EMPTY_STATE.SUBTITLE') }}
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
              {{ t('COMPANIES.EMPTY_STATE.GETTING_STARTED') }}
            </h3>
            <RelayBadge
              variant="secondary"
              class="rounded-full border-none bg-primary/10 px-2.5 py-0.5 text-xs font-medium text-primary"
            >
              {{ t('COMPANIES.EMPTY_STATE.STEP_BADGE') }}
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
                {{ t('COMPANIES.EMPTY_STATE.STEP_WORKSPACE') }}
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
                {{ t('COMPANIES.EMPTY_STATE.STEP_CONTACTS') }}
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
                  {{ t('COMPANIES.EMPTY_STATE.STEP_CREATE') }}
                </p>
                <p class="mt-1 text-xs leading-relaxed text-muted-foreground">
                  {{ t('COMPANIES.EMPTY_STATE.STEP_CREATE_HINT') }}
                </p>
              </div>
            </div>

            <div
              class="relative z-10 flex items-start gap-4 opacity-60 transition-opacity hover:opacity-100"
            >
              <div
                class="mt-0.5 flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 border-muted-foreground/30 bg-card ring-4 ring-card"
              />
              <div>
                <p class="text-sm font-medium text-foreground">
                  {{ t('COMPANIES.EMPTY_STATE.STEP_DEAL') }}
                </p>
                <p class="mt-1 text-xs leading-relaxed text-muted-foreground">
                  {{ t('COMPANIES.EMPTY_STATE.STEP_DEAL_HINT') }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex flex-col justify-center gap-4">
        <div
          class="flex flex-col gap-4 rounded-3xl border border-border/50 bg-card p-8 shadow-sm"
        >
          <h3 class="mb-2 text-lg font-semibold text-foreground">
            {{ t('COMPANIES.EMPTY_STATE.ADD_ACCOUNTS') }}
          </h3>
          <RelayButton
            class="group h-12 w-full rounded-xl text-base shadow-sm"
            @click="emit('create')"
          >
            <span
              class="i-lucide-plus mr-2 size-5 transition-transform duration-300 group-hover:rotate-90"
            />
            {{ t('COMPANIES.ACTIONS.CREATE') }}
          </RelayButton>

          <div class="relative flex items-center py-3">
            <div class="flex-grow border-t border-border/60" />
            <span
              class="mx-4 flex-shrink-0 text-xs font-medium uppercase tracking-widest text-muted-foreground"
            >
              {{ t('COMPANIES.EMPTY_STATE.OR_IMPORT') }}
            </span>
            <div class="flex-grow border-t border-border/60" />
          </div>

          <div class="grid grid-cols-1 gap-3">
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-start gap-3 rounded-xl border-border/60 text-muted-foreground hover:bg-muted/30 hover:text-foreground"
              @click="emit('import')"
            >
              <span class="i-lucide-upload size-4 text-foreground/70" />
              {{ t('COMPANIES.EMPTY_STATE.UPLOAD_CSV') }}
            </RelayButton>
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-start gap-3 rounded-xl border-border/60 text-muted-foreground hover:bg-muted/30 hover:text-foreground"
              @click="emit('import')"
            >
              <span class="i-lucide-import size-4 text-foreground/70" />
              {{ t('COMPANIES.EMPTY_STATE.IMPORT_HUBSPOT') }}
            </RelayButton>
            <RelayButton
              variant="outline"
              class="h-11 w-full justify-start gap-3 rounded-xl border-border/60 text-muted-foreground hover:bg-muted/30 hover:text-foreground"
              @click="emit('import')"
            >
              <span class="i-lucide-import size-4 text-foreground/70" />
              {{ t('COMPANIES.EMPTY_STATE.IMPORT_SALESFORCE') }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>

    <div class="w-full max-w-5xl">
      <h4
        class="mb-8 text-center text-xs font-semibold uppercase tracking-widest text-muted-foreground"
      >
        {{ t('COMPANIES.EMPTY_STATE.WHY_TITLE') }}
      </h4>
      <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
        <div
          class="rounded-2xl border border-border/40 bg-card p-6 text-center shadow-sm transition-colors hover:border-border/80"
        >
          <div
            class="mx-auto mb-4 flex size-12 items-center justify-center rounded-xl border border-primary/20 bg-primary/10 text-primary"
          >
            <span class="i-lucide-users size-5" />
          </div>
          <h5 class="mb-2 text-sm font-semibold text-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.ORGANIZE_TITLE') }}
          </h5>
          <p class="text-xs leading-relaxed text-muted-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.ORGANIZE_DESC') }}
          </p>
        </div>
        <div
          class="rounded-2xl border border-border/40 bg-card p-6 text-center shadow-sm transition-colors hover:border-border/80"
        >
          <div
            class="mx-auto mb-4 flex size-12 items-center justify-center rounded-xl border border-primary/20 bg-primary/10 text-primary"
          >
            <span class="i-lucide-briefcase size-5" />
          </div>
          <h5 class="mb-2 text-sm font-semibold text-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.DEALS_TITLE') }}
          </h5>
          <p class="text-xs leading-relaxed text-muted-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.DEALS_DESC') }}
          </p>
        </div>
        <div
          class="rounded-2xl border border-border/40 bg-card p-6 text-center shadow-sm transition-colors hover:border-border/80"
        >
          <div
            class="mx-auto mb-4 flex size-12 items-center justify-center rounded-xl border border-primary/20 bg-primary/10 text-primary"
          >
            <span class="i-lucide-dollar-sign size-5" />
          </div>
          <h5 class="mb-2 text-sm font-semibold text-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.REVENUE_TITLE') }}
          </h5>
          <p class="text-xs leading-relaxed text-muted-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.REVENUE_DESC') }}
          </p>
        </div>
        <div
          class="rounded-2xl border border-border/40 bg-card p-6 text-center shadow-sm transition-colors hover:border-border/80"
        >
          <div
            class="mx-auto mb-4 flex size-12 items-center justify-center rounded-xl border border-primary/20 bg-primary/10 text-primary"
          >
            <span class="i-lucide-clock size-5" />
          </div>
          <h5 class="mb-2 text-sm font-semibold text-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.TIMELINE_TITLE') }}
          </h5>
          <p class="text-xs leading-relaxed text-muted-foreground">
            {{ t('COMPANIES.EMPTY_STATE.WHY.TIMELINE_DESC') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
