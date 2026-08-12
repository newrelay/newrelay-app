<script setup>
import { computed, h, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle, useElementSize } from '@vueuse/core';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  instruction: {
    type: String,
    required: true,
  },
  tools: {
    type: Array,
    default: () => [],
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'hover', 'delete', 'update']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const state = reactive({
  id: '',
  title: '',
  description: '',
  instruction: '',
});

const instructionContentRef = ref();

const [isEditing, toggleEditing] = useToggle();
const [isInstructionExpanded, toggleInstructionExpanded] = useToggle();

const toggleSelect = () => {
  if (!props.selectable || isEditing.value) return;
  emit('select', props.id);
};

const { height: contentHeight } = useElementSize(instructionContentRef);
const needsOverlay = computed(() => contentHeight.value > 160);

const startEdit = () => {
  Object.assign(state, {
    id: props.id,
    title: props.title,
    description: props.description,
    instruction: props.instruction,
    tools: props.tools,
  });
  toggleEditing(true);
};

const rules = {
  title: { required, minLength: minLength(1) },
  description: { required },
  instruction: { required },
};

const v$ = useVuelidate(rules, state);

const titleError = computed(() =>
  v$.value.title.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.ERROR')
    : ''
);

const descriptionError = computed(() =>
  v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.ERROR')
    : ''
);

const onClickUpdate = () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  emit('update', { ...state });
  toggleEditing(false);
};

const instructionError = computed(() =>
  v$.value.instruction.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.ERROR')
    : ''
);

const LINK_INSTRUCTION_CLASS =
  '[&_a[href^="tool://"]]:text-primary [&_a:not([href^="tool://"])]:text-foreground [&_a]:pointer-events-none [&_a]:cursor-default';

const renderInstruction = instruction => () =>
  h('p', {
    class: `mb-0 max-w-none min-w-0 break-words py-4 text-[14px] leading-relaxed text-foreground/90 prose prose-sm ${LINK_INSTRUCTION_CLASS}`,
    innerHTML: instruction,
  });
</script>

<template>
  <div
    class="group relative overflow-hidden rounded-xl border bg-card transition-all hover:shadow-sm"
    :class="
      isSelected && !isEditing
        ? 'border-primary/50 bg-primary/[0.02]'
        : 'border-border hover:border-border'
    "
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div
      class="flex w-full gap-4 p-5"
      :class="isEditing ? 'flex-col' : 'cursor-pointer select-none items-start'"
      @click="!isEditing && toggleSelect()"
    >
      <div
        v-if="selectable && !isEditing"
        class="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors"
        :class="
          isSelected
            ? 'border-primary bg-primary text-primary-foreground shadow-xs'
            : 'border-border/80 bg-background/50'
        "
      >
        <span v-if="isSelected" class="i-lucide-check size-3 stroke-[3]" />
      </div>

      <div v-if="!isEditing" class="min-w-0 flex-1">
        <div class="mb-2 flex w-full items-center justify-between gap-2">
          <h3 class="text-[15px] font-medium text-foreground">{{ title }}</h3>
          <div class="flex shrink-0 items-center gap-1" @click.stop>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:text-foreground"
              @click="startEdit"
            >
              <span class="i-lucide-pen size-3.5" />
            </RelayButton>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md border border-border text-muted-foreground hover:border-transparent hover:bg-destructive/10 hover:text-destructive"
              @click="emit('delete', id)"
            >
              <span class="i-lucide-trash size-3.5" />
            </RelayButton>
          </div>
        </div>

        <p class="mb-4 text-[14px] text-muted-foreground">
          {{ description }}
        </p>

        <div
          class="group/expandable relative overflow-hidden rounded-lg border border-border/50 bg-background/50 transition-all duration-300 ease-in-out"
          :class="{ 'cursor-pointer': needsOverlay }"
          :style="{
            maxHeight: isInstructionExpanded ? `${contentHeight}px` : '10rem',
          }"
          @click.stop="needsOverlay ? toggleInstructionExpanded() : null"
        >
          <div ref="instructionContentRef" class="px-4">
            <component
              :is="renderInstruction(formatMessage(instruction, false))"
            />
          </div>

          <div
            class="pointer-events-none absolute bottom-0 flex h-40 w-full items-end justify-center bg-gradient-to-t from-card via-card via-10% to-transparent px-2 py-1 text-xs text-muted-foreground transition-all duration-500 ease-in-out"
            :class="{
              'visible opacity-100': !isInstructionExpanded,
              'invisible opacity-0': isInstructionExpanded || !needsOverlay,
            }"
          >
            <Icon
              icon="i-lucide-chevron-down"
              class="mb-4 size-4 text-muted-foreground/50 transition-colors duration-200 group-hover/expandable:text-muted-foreground"
            />
          </div>
        </div>
        <span
          v-if="tools?.length"
          class="mb-1 mt-3 block text-sm font-medium text-muted-foreground"
        >
          {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TOOLS_USED') }}
          {{ tools?.map(tool => `@${tool}`).join(', ') }}
        </span>
      </div>
      <div v-else class="flex w-full flex-col gap-6 overflow-hidden">
        <div class="flex flex-col gap-1.5">
          <RelayLabel
            html-for="scenario-title"
            class="text-[13.5px] font-medium text-foreground"
          >
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="scenario-title"
            v-model="state.title"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
            "
            class-name="rounded-md border-border/80 bg-background text-[14px] shadow-sm"
          />
          <p v-if="titleError" class="text-xs text-destructive">
            {{ titleError }}
          </p>
        </div>

        <TextArea
          v-model="state.description"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.PLACEHOLDER'
            )
          "
          :message="descriptionError"
          :message-type="descriptionError ? 'error' : 'info'"
          show-character-count
        />
        <Editor
          v-model="state.instruction"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.PLACEHOLDER'
            )
          "
          :message="instructionError"
          :message-type="instructionError ? 'error' : 'info'"
          :show-character-count="false"
          enable-captain-tools
        />
        <div class="flex items-center gap-2">
          <RelayButton
            variant="outline"
            class="h-9 px-4"
            @click="toggleEditing(false)"
          >
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.UPDATE.CANCEL') }}
          </RelayButton>
          <RelayButton class="h-9 px-6" @click="onClickUpdate">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.UPDATE.UPDATE') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
