<script>
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RELAY_FORM_FIELD_CLASS,
  RELAY_MODAL_CLOSE_BUTTON_CLASS,
  RELAY_MODAL_INPUT_CLASS,
} from 'dashboard/components-next/relay';

export default {
  components: {
    RelayButton,
    RelayInput,
    RelayLabel,
  },
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
  setup() {
    return {
      RELAY_FORM_FIELD_CLASS,
      RELAY_MODAL_CLOSE_BUTTON_CLASS,
    };
  },
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
    nameInputClass() {
      if (this.v$.macro.name.$error) {
        return `${RELAY_MODAL_INPUT_CLASS} border-destructive/80 focus-visible:ring-destructive/30`;
      }
      return RELAY_MODAL_INPUT_CLASS;
    },
  },
  methods: {
    visibilityCardClass(isActive) {
      return [
        'flex flex-col text-left p-3 rounded-xl border transition-all text-[13px] relative overflow-hidden outline-none cursor-pointer disabled:cursor-not-allowed disabled:opacity-60',
        isActive
          ? 'border-primary ring-1 ring-primary/30 shadow-xs bg-primary/5'
          : 'border-border/60 bg-background hover:border-primary/40',
      ];
    },
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
  <div class="flex h-full select-none flex-col bg-card">
    <div
      class="flex items-center justify-between border-b border-border/40 p-5"
    >
      <div>
        <h3 class="text-base font-medium text-foreground">
          {{ $t('MACROS.EDITOR.DETAILS_TITLE') }}
        </h3>
        <p class="text-[12.5px] text-muted-foreground">
          {{ $t('MACROS.EDITOR.DETAILS_DESCRIPTION') }}
        </p>
      </div>
      <button
        type="button"
        :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
        @click="$emit('close')"
      >
        <span class="i-lucide-x size-4.5 block" />
      </button>
    </div>

    <div class="custom-scrollbar flex-1 space-y-6 overflow-y-auto p-5">
      <div :class="RELAY_FORM_FIELD_CLASS">
        <RelayLabel>
          {{ $t('MACROS.ADD.FORM.NAME.LABEL') }}
        </RelayLabel>
        <RelayInput
          :model-value="macroName"
          type="text"
          :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
          :class-name="nameInputClass"
          :disabled="readOnly"
          @update:model-value="onUpdateName"
        />
        <p
          v-if="v$.macro.name.$error"
          class="mt-0.5 text-[12px] font-medium text-destructive"
        >
          {{ $t('MACROS.ADD.FORM.NAME.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-2">
        <RelayLabel>
          {{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}
        </RelayLabel>
        <div class="grid grid-cols-2 gap-2.5">
          <button
            type="button"
            :class="visibilityCardClass(macroVisibility === 'global')"
            :disabled="isPublicVisibilityDisabled || readOnly"
            @click="onUpdateVisibility('global')"
          >
            <div class="mb-1 flex items-center gap-2">
              <span class="i-lucide-globe size-4 text-primary" />
              <span class="text-[13.5px] font-medium text-foreground">
                {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
              </span>
              <span
                v-if="macroVisibility === 'global'"
                class="i-lucide-check ml-auto size-3.5 text-primary"
              />
            </div>
            <span class="text-[11.5px] leading-relaxed text-muted-foreground">
              {{ publicVisibilityDescription }}
            </span>
          </button>

          <button
            type="button"
            :class="visibilityCardClass(macroVisibility === 'personal')"
            :disabled="readOnly"
            @click="onUpdateVisibility('personal')"
          >
            <div class="mb-1 flex items-center gap-2">
              <span class="i-lucide-lock size-4 text-muted-foreground" />
              <span class="text-[13.5px] font-medium text-foreground">
                {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
              </span>
              <span
                v-if="macroVisibility === 'personal'"
                class="i-lucide-check ml-auto size-3.5 text-primary"
              />
            </div>
            <span class="text-[11.5px] leading-relaxed text-muted-foreground">
              {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
            </span>
          </button>
        </div>
      </div>

      <div
        class="flex items-start gap-2.5 rounded-lg border border-border/60 bg-muted/40 p-3.5"
      >
        <span class="i-lucide-info mt-0.5 block size-4 shrink-0 text-primary" />
        <p class="mb-0 text-[12.5px] leading-relaxed text-muted-foreground">
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>

    <div class="border-t border-border/40 p-5">
      <RelayButton
        type="button"
        size="lg"
        class="w-full"
        :disabled="readOnly"
        @click="$emit('submit')"
      >
        {{ $t('MACROS.HEADER_BTN_TXT_SAVE') }}
      </RelayButton>
    </div>
  </div>
</template>
