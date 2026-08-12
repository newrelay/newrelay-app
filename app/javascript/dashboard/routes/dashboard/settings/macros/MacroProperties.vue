<script>
export default {
  inject: ['v$'],
  props: {
    macroName: {
      type: String,
      default: '',
    },
    macroVisibility: {
      type: String,
      default: 'global',
    },
    canManagePublicMacros: {
      type: Boolean,
      default: true,
    },
    readOnly: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:name', 'update:visibility', 'submit', 'close'],
  computed: {
    isPublicVisibilityDisabled() {
      return !this.canManagePublicMacros;
    },
    publicVisibilityDescription() {
      if (this.readOnly) {
        return this.$t(
          'MACROS.EDITOR.VISIBILITY.GLOBAL.EDIT_DISABLED_DESCRIPTION'
        );
      }

      if (this.isPublicVisibilityDisabled) {
        return this.$t(
          'MACROS.EDITOR.VISIBILITY.GLOBAL.CREATE_DISABLED_DESCRIPTION'
        );
      }

      return this.$t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION');
    },
  },
  methods: {
    onUpdateName(value) {
      if (this.readOnly) return;

      this.$emit('update:name', value);
    },
    onUpdateVisibility(value) {
      if (this.readOnly) return;
      if (value === 'global' && this.isPublicVisibilityDisabled) return;

      this.$emit('update:visibility', value);
    },
  },
};
</script>

<template>
  <div class="p-6 bg-card flex flex-col h-full justify-between select-none">
    <div class="space-y-6">
      <div
        class="flex items-center justify-between pb-4 border-b border-border/40 mb-6"
      >
        <h3 class="text-base font-medium text-foreground">
          {{ $t('MACROS.EDITOR.DETAILS_TITLE') }}
        </h3>
        <button
          type="button"
          class="text-muted-foreground hover:text-foreground transition-colors p-1 rounded-md hover:bg-muted/50 border-0 bg-transparent cursor-pointer flex items-center"
          @click="$emit('close')"
        >
          <span class="i-lucide-x size-4.5 block" />
        </button>
      </div>

      <!-- Name Field -->
      <div class="flex flex-col gap-2">
        <label class="text-[14px] font-semibold text-foreground">
          {{ $t('MACROS.ADD.FORM.NAME.LABEL') }}
        </label>
        <input
          :value="macroName"
          type="text"
          :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
          class="h-10 px-3 text-[14px] shadow-sm rounded-lg bg-background border border-border/60 focus:border-border/80 focus-visible:ring-1 focus-visible:ring-primary/20 outline-none w-full"
          :class="
            v$.macro.name.$error
              ? 'border-destructive/80 focus-visible:ring-destructive/30'
              : ''
          "
          :readonly="readOnly"
          @input="onUpdateName($event.target.value)"
        />
        <p
          v-if="v$.macro.name.$error"
          class="text-[12.5px] font-medium text-destructive mt-0.5"
        >
          {{ $t('MACROS.ADD.FORM.NAME.ERROR') }}
        </p>
      </div>

      <!-- Visibility Selection -->
      <div class="flex flex-col gap-2">
        <label class="text-[14px] font-semibold text-foreground">
          {{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}
        </label>
        <div class="grid grid-cols-2 gap-3">
          <!-- Global/Public Button -->
          <button
            type="button"
            class="flex flex-col text-left p-4 rounded-xl border transition-all text-[13px] relative overflow-hidden outline-none cursor-pointer"
            :class="
              macroVisibility === 'global'
                ? 'border-primary ring-1 ring-primary/30 shadow-sm bg-primary/5'
                : 'border-border/60 bg-background hover:border-primary/40 shadow-sm'
            "
            :disabled="isPublicVisibilityDisabled || readOnly"
            @click="onUpdateVisibility('global')"
          >
            <div class="flex items-center gap-3 mb-2">
              <div
                class="size-7 rounded-full flex items-center justify-center bg-primary/10 text-primary shrink-0"
              >
                <span class="i-lucide-globe size-4 block" />
              </div>
              <div
                v-if="macroVisibility === 'global'"
                class="absolute top-3 right-3 flex items-center justify-center size-5 rounded-full bg-primary text-primary-foreground"
              >
                <span class="i-lucide-check size-3 block" />
              </div>
            </div>
            <span
              class="font-semibold text-[14.5px] text-foreground mb-1 block"
            >
              {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
            </span>
            <span class="text-[12px] text-muted-foreground leading-relaxed">
              {{ publicVisibilityDescription }}
            </span>
          </button>

          <!-- Personal/Private Button -->
          <button
            type="button"
            class="flex flex-col text-left p-4 rounded-xl border transition-all text-[13px] relative overflow-hidden outline-none cursor-pointer"
            :class="
              macroVisibility === 'personal'
                ? 'border-primary ring-1 ring-primary/30 shadow-sm bg-primary/5'
                : 'border-border/60 bg-background hover:border-primary/40 shadow-sm'
            "
            :disabled="readOnly"
            @click="onUpdateVisibility('personal')"
          >
            <div class="flex items-center gap-3 mb-2">
              <div
                class="size-7 rounded-full flex items-center justify-center bg-muted border border-border/40 text-foreground shrink-0"
              >
                <span class="i-lucide-lock size-4 block" />
              </div>
              <div
                v-if="macroVisibility === 'personal'"
                class="absolute top-3 right-3 flex items-center justify-center size-5 rounded-full bg-primary text-primary-foreground"
              >
                <span class="i-lucide-check size-3 block" />
              </div>
            </div>
            <span
              class="font-semibold text-[14.5px] text-foreground mb-1 block"
            >
              {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
            </span>
            <span class="text-[12px] text-muted-foreground leading-relaxed">
              {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
            </span>
          </button>
        </div>
      </div>

      <!-- Info Box -->
      <div
        class="p-4 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800 flex items-start gap-3"
      >
        <span
          class="i-lucide-info size-4.5 text-primary shrink-0 mt-0.5 block"
        />
        <p
          class="text-[13px] text-slate-600 dark:text-slate-400 leading-relaxed mb-0"
        >
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>

    <!-- Submit Section -->
    <div class="pt-6 border-t border-border/40">
      <button
        type="button"
        class="w-full h-11 text-[14.5px] font-medium shadow-sm bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg border-0 cursor-pointer transition-colors"
        :disabled="readOnly"
        @click="$emit('submit')"
      >
        {{ $t('MACROS.HEADER_BTN_TXT_SAVE') }}
      </button>
    </div>
  </div>
</template>
