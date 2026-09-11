<script>
import AutomationActionTeamMessageInput from './AutomationActionTeamMessageInput.vue';
import AutomationActionFileInput from './AutomationFileInput.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import { RelayInput } from 'dashboard/components-next/relay';

export default {
  components: {
    AutomationActionTeamMessageInput,
    AutomationActionFileInput,
    WootMessageEditor,
    NextButton,
    SingleSelect,
    MultiSelect,
    RelayInput,
  },
  props: {
    modelValue: {
      type: Object,
      default: () => null,
    },
    actionTypes: {
      type: Array,
      default: () => [],
    },
    dropdownValues: {
      type: Array,
      default: () => [],
    },
    errorMessage: {
      type: String,
      default: '',
    },
    showActionInput: {
      type: Boolean,
      default: true,
    },
    initialFileName: {
      type: String,
      default: '',
    },
    isMacro: {
      type: Boolean,
      default: false,
    },
    dropdownMaxHeight: {
      type: String,
      default: 'max-h-80',
    },
  },
  emits: ['update:modelValue', 'input', 'removeAction', 'resetAction'],
  computed: {
    action_name: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_name;
      },
      set(value) {
        const payload = this.modelValue || {};
        this.$emit('update:modelValue', { ...payload, action_name: value });
        this.$emit('input', { ...payload, action_name: value });
      },
    },
    action_params: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_params;
      },
      set(value) {
        const payload = this.modelValue || {};
        this.$emit('update:modelValue', { ...payload, action_params: value });
        this.$emit('input', { ...payload, action_params: value });
      },
    },
    inputType() {
      return this.actionTypes.find(action => action.key === this.action_name)
        ?.inputType;
    },
    fieldAppearance() {
      return this.isMacro ? 'field' : 'default';
    },
    valueAppearance() {
      return this.isMacro ? 'fieldMuted' : 'default';
    },
    macroValueInputClass() {
      return 'h-9 w-full rounded-lg border-border/50 bg-muted/40 px-3 text-[13.5px] shadow-none focus-visible:ring-1 focus-visible:ring-primary/30';
    },
    actionNameAsSelectModel: {
      get() {
        if (!this.action_name) return null;
        const found = this.actionTypes.find(a => a.key === this.action_name);
        return found ? { id: found.key, name: found.label } : null;
      },
      set(value) {
        this.action_name = value?.id || value;
      },
    },
    actionTypesAsOptions() {
      return this.actionTypes.map(a => ({ id: a.key, name: a.label }));
    },
    isVerticalLayout() {
      return ['team_message', 'textarea'].includes(this.inputType);
    },
    castMessageVmodel: {
      get() {
        if (Array.isArray(this.action_params)) {
          return this.action_params[0];
        }
        return this.action_params;
      },
      set(value) {
        this.action_params = value;
      },
    },
  },
  methods: {
    removeAction() {
      this.$emit('removeAction');
    },
    resetAction() {
      this.$emit('resetAction');
    },
    onActionNameChange(value) {
      this.actionNameAsSelectModel = value;
      this.resetAction();
    },
  },
};
</script>

<template>
  <div
    :class="isMacro ? 'min-w-0 w-full' : 'list-none py-2 first:pt-0 last:pb-0'"
  >
    <div
      class="flex flex-col gap-2"
      :class="{ 'animate-wiggle': errorMessage }"
    >
      <div
        class="flex w-full items-center"
        :class="isMacro ? 'gap-2.5' : 'gap-2'"
      >
        <SingleSelect
          :model-value="actionNameAsSelectModel"
          :options="actionTypesAsOptions"
          :dropdown-max-height="dropdownMaxHeight"
          :appearance="fieldAppearance"
          :placeholder="isMacro ? $t('MACROS.EDITOR.SELECT_OPTION') : ''"
          :search-placeholder="
            isMacro ? $t('MACROS.EDITOR.SEARCH_ACTIONS') : ''
          "
          disable-deselect
          :class="isMacro ? 'min-w-[220px] shrink-0' : 'flex-shrink-0'"
          @update:model-value="onActionNameChange"
        />
        <template v-if="showActionInput && !isVerticalLayout">
          <div :class="isMacro ? 'relative min-w-0 flex-1' : 'contents'">
            <SingleSelect
              v-if="inputType === 'search_select'"
              v-model="action_params"
              :options="dropdownValues"
              :dropdown-max-height="dropdownMaxHeight"
              :appearance="valueAppearance"
              :placeholder="isMacro ? $t('MACROS.EDITOR.SELECT_OPTION') : ''"
            />
            <MultiSelect
              v-else-if="inputType === 'multi_select'"
              v-model="action_params"
              :options="dropdownValues"
              :dropdown-max-height="dropdownMaxHeight"
              :appearance="valueAppearance"
              :placeholder="isMacro ? $t('MACROS.EDITOR.SELECT_OPTION') : ''"
            />
            <RelayInput
              v-else-if="inputType === 'email'"
              v-model="action_params"
              type="email"
              :placeholder="$t('AUTOMATION.ACTION.EMAIL_INPUT_PLACEHOLDER')"
              :class-name="isMacro ? macroValueInputClass : undefined"
            />
            <RelayInput
              v-else-if="inputType === 'url'"
              v-model="action_params"
              type="url"
              :placeholder="$t('AUTOMATION.ACTION.URL_INPUT_PLACEHOLDER')"
              :class-name="isMacro ? macroValueInputClass : undefined"
            />
            <AutomationActionFileInput
              v-else-if="inputType === 'attachment'"
              v-model="action_params"
              :initial-file-name="initialFileName"
            />
          </div>
        </template>
        <div
          v-else-if="isMacro && !isVerticalLayout"
          class="flex h-9 min-w-0 flex-1 items-center rounded-lg border border-border/40 bg-muted/20 px-3 text-[12.5px] italic text-muted-foreground"
        >
          {{ $t('MACROS.EDITOR.NO_PARAMS') }}
        </div>
        <NextButton
          v-if="!isMacro"
          sm
          solid
          slate
          icon="i-lucide-trash"
          class="flex-shrink-0"
          @click="removeAction"
        />
      </div>
      <AutomationActionTeamMessageInput
        v-if="inputType === 'team_message'"
        v-model="action_params"
        :teams="dropdownValues"
        :dropdown-max-height="dropdownMaxHeight"
      />
      <WootMessageEditor
        v-if="inputType === 'textarea'"
        v-model="castMessageVmodel"
        rows="4"
        enable-variables
        :placeholder="$t('AUTOMATION.ACTION.TEAM_MESSAGE_INPUT_PLACEHOLDER')"
        :class="
          isMacro
            ? 'rounded-lg border border-border/50 bg-muted/40 px-3 py-1 outline-none [&_.ProseMirror-menubar]:hidden'
            : 'rounded-lg bg-muted px-3 py-1 outline outline-1 outline-border dark:outline-border [&_.ProseMirror-menubar]:hidden'
        "
      />
    </div>
    <span v-if="errorMessage" class="text-sm text-destructive">
      {{ errorMessage }}
    </span>
  </div>
</template>
