<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelaySwitch,
  RelayCheckbox,
  RelayDatePicker,
  RelayTimePicker,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS, CHANNEL_NAMES } from '../constants/channels';

defineProps({
  open: { type: Boolean, default: false },
});

const emit = defineEmits(['update:open']);

const { t } = useI18n();

const steps = computed(() => [
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_TRIGGER'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_CONDITION'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_ACTION'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_RESPONSE'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_REVIEW'),
]);
const currentStep = ref(0);

// Step 1: Trigger
const automationName = ref('');
const automateType = ref('auto_responder');
const platform = ref('Instagram');
const triggerOptions = computed(() => [
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TRIGGER_ON_MESSAGE'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TRIGGER_ON_COMMENT'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TRIGGER_ON_MENTION'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TRIGGER_ON_KEYWORD'),
]);
const triggerType = ref('');
triggerType.value = triggerOptions.value[0];

// Step 2: Condition
const conditions = ref({
  containsKeyword: true,
  doesNotContainKeyword: false,
  specificPost: false,
  businessHours: false,
  firstInteraction: false,
});
const keywords = ref('');

// Step 3: Action
const actions = ref({
  sendReply: true,
  sendDm: false,
  addTag: false,
  assignRoute: false,
  stopAutomation: false,
});

// Step 4: Response
const responseMessage = ref('');
const delayOptions = computed(() => [
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.DELAY_IMMEDIATELY'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.DELAY_1_MIN'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.DELAY_5_MIN'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.DELAY_CUSTOM'),
]);
const delay = ref('');
delay.value = delayOptions.value[0];
const customDate = ref(null);
const customTime = ref('');

// Step 5: Review
const isEnabled = ref(true);
const showSafetyNotice = ref(true);

const closeModal = () => {
  emit('update:open', false);
  setTimeout(() => {
    currentStep.value = 0;
  }, 200);
};

const nextStep = () => {
  if (currentStep.value < steps.value.length - 1) {
    currentStep.value += 1;
  } else {
    closeModal();
  }
};

const prevStep = () => {
  if (currentStep.value > 0) {
    currentStep.value -= 1;
  } else {
    closeModal();
  }
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[100] flex items-center justify-center bg-background/80 backdrop-blur-md p-4 sm:p-6"
      @click.self="closeModal"
    >
      <div
        class="bg-background w-full max-w-[550px] rounded-2xl shadow-xl flex flex-col max-h-[90vh] overflow-hidden relative border border-border/50"
      >
        <div class="flex flex-col p-6 pb-8 border-b border-border">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold tracking-tight text-foreground">
              {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TITLE') }}
            </h2>
            <button
              type="button"
              class="p-1 text-muted-foreground hover:bg-muted rounded-full transition-colors"
              @click="closeModal"
            >
              <span class="i-lucide-x size-5" />
            </button>
          </div>
          <p class="text-[13.5px] text-muted-foreground mt-1">
            {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUBTITLE') }}
          </p>

          <div class="flex items-center justify-between mt-8 mb-2 px-2">
            <template v-for="(step, index) in steps" :key="step">
              <div class="flex flex-col items-center relative z-10">
                <div
                  class="size-8 rounded-full flex items-center justify-center text-[13px] font-semibold transition-all duration-200"
                  :class="[
                    currentStep === index
                      ? 'bg-primary text-primary-foreground ring-4 ring-primary/20'
                      : currentStep > index
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-background text-muted-foreground border-2 border-muted-foreground/20',
                  ]"
                >
                  {{ index + 1 }}
                </div>
                <span
                  class="text-[12px] font-medium absolute -bottom-6 whitespace-nowrap"
                  :class="
                    currentStep === index
                      ? 'text-primary'
                      : currentStep > index
                        ? 'text-foreground'
                        : 'text-muted-foreground'
                  "
                >
                  {{ step }}
                </span>
              </div>
              <div
                v-if="index < steps.length - 1"
                class="flex-1 h-[2px] mx-2 transition-colors duration-200"
                :class="currentStep > index ? 'bg-primary' : 'bg-muted'"
              />
            </template>
          </div>
        </div>

        <div class="flex-1 overflow-y-auto p-6 flex flex-col gap-6">
          <template v-if="currentStep === 0">
            <div class="flex flex-col gap-6">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.NAME_LABEL') }}
                </label>
                <RelayInput
                  v-model="automationName"
                  :placeholder="
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.NAME_PLACEHOLDER')
                  "
                />
              </div>

              <div class="flex flex-col gap-3">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.AUTOMATE_TYPE_LABEL'
                    )
                  }}
                </label>
                <div class="grid grid-cols-2 gap-4">
                  <div
                    class="relative border rounded-xl p-4 cursor-pointer transition-colors"
                    :class="
                      automateType === 'auto_responder'
                        ? 'border-primary bg-primary/5 ring-1 ring-primary'
                        : 'border-border hover:border-foreground/20'
                    "
                    @click="automateType = 'auto_responder'"
                  >
                    <div
                      v-if="automateType === 'auto_responder'"
                      class="absolute top-3 right-3 size-4 rounded-full bg-primary flex items-center justify-center text-primary-foreground"
                    >
                      <span class="i-lucide-check size-3" />
                    </div>
                    <div
                      class="size-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center mb-3"
                    >
                      <span class="i-lucide-message-square size-4" />
                    </div>
                    <div class="text-sm font-semibold text-foreground">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.AUTO_RESPONDER'
                        )
                      }}
                    </div>
                    <div
                      class="text-xs text-muted-foreground mt-1 leading-relaxed"
                    >
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.AUTO_RESPONDER_DESC'
                        )
                      }}
                    </div>
                  </div>

                  <div
                    class="relative border rounded-xl p-4 cursor-pointer transition-colors"
                    :class="
                      automateType === 'auto_commenter'
                        ? 'border-primary bg-primary/5 ring-1 ring-primary'
                        : 'border-border hover:border-foreground/20'
                    "
                    @click="automateType = 'auto_commenter'"
                  >
                    <div
                      v-if="automateType === 'auto_commenter'"
                      class="absolute top-3 right-3 size-4 rounded-full bg-primary flex items-center justify-center text-primary-foreground"
                    >
                      <span class="i-lucide-check size-3" />
                    </div>
                    <div
                      class="size-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center mb-3"
                    >
                      <span class="i-lucide-message-circle size-4" />
                    </div>
                    <div class="text-sm font-semibold text-foreground">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.AUTO_COMMENTER'
                        )
                      }}
                    </div>
                    <div
                      class="text-xs text-muted-foreground mt-1 leading-relaxed"
                    >
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.AUTO_COMMENTER_DESC'
                        )
                      }}
                    </div>
                  </div>
                </div>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.PLATFORM_LABEL')
                  }}
                </label>
                <RelayDropdownMenu>
                  <RelayDropdownMenuTrigger as-child>
                    <button
                      type="button"
                      class="w-full h-10 px-3 flex items-center justify-between text-sm shadow-sm rounded-md border border-border/80 bg-background cursor-pointer outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                    >
                      <div class="flex items-center gap-2">
                        <img
                          :src="CHANNEL_LOGO_URLS[platform]"
                          class="size-4 opacity-90"
                        />
                        <span class="text-foreground">{{ platform }}</span>
                      </div>
                      <span
                        class="i-lucide-chevron-down size-4 text-muted-foreground"
                      />
                    </button>
                  </RelayDropdownMenuTrigger>
                  <RelayDropdownMenuContent
                    align="start"
                    class="w-[--reka-dropdown-menu-trigger-width]"
                  >
                    <RelayDropdownMenuItem
                      v-for="opt in CHANNEL_NAMES"
                      :key="opt"
                      class="flex items-center justify-between cursor-pointer"
                      @click="platform = opt"
                    >
                      <div class="flex items-center gap-2">
                        <img
                          :src="CHANNEL_LOGO_URLS[opt]"
                          class="size-4 opacity-90"
                        />
                        <span>{{ opt }}</span>
                      </div>
                      <span
                        v-if="platform === opt"
                        class="i-lucide-check size-4"
                      />
                    </RelayDropdownMenuItem>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TRIGGER_LABEL') }}
                </label>
                <RelayDropdownMenu>
                  <RelayDropdownMenuTrigger as-child>
                    <button
                      type="button"
                      class="w-full h-10 px-3 flex items-center justify-between text-sm shadow-sm rounded-md border border-border/80 bg-background cursor-pointer outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                    >
                      <span class="truncate text-foreground">{{
                        triggerType
                      }}</span>
                      <span
                        class="i-lucide-chevron-down size-4 text-muted-foreground shrink-0"
                      />
                    </button>
                  </RelayDropdownMenuTrigger>
                  <RelayDropdownMenuContent
                    align="start"
                    class="w-[--reka-dropdown-menu-trigger-width]"
                  >
                    <RelayDropdownMenuItem
                      v-for="opt in triggerOptions"
                      :key="opt"
                      class="flex items-center justify-between cursor-pointer"
                      @click="triggerType = opt"
                    >
                      <span>{{ opt }}</span>
                      <span
                        v-if="triggerType === opt"
                        class="i-lucide-check size-4"
                      />
                    </RelayDropdownMenuItem>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>
                <p class="text-xs text-muted-foreground mt-1">
                  {{
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TRIGGER_HELPER')
                  }}
                </p>
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 1">
            <div class="flex flex-col gap-5">
              <div class="flex flex-col gap-3">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONDITIONS_LABEL')
                  }}
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="conditions.containsKeyword" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONDITION_CONTAINS_KEYWORD'
                      )
                    }}
                  </span>
                </label>

                <div v-if="conditions.containsKeyword" class="pl-7 pr-1 pb-2">
                  <RelayInput
                    v-model="keywords"
                    :placeholder="
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.KEYWORDS_PLACEHOLDER'
                      )
                    "
                  />
                  <p class="text-xs text-muted-foreground mt-1">
                    {{
                      t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.KEYWORDS_HELPER')
                    }}
                  </p>
                </div>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="conditions.doesNotContainKeyword" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONDITION_NOT_CONTAINS_KEYWORD'
                      )
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="conditions.specificPost" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONDITION_SPECIFIC_POST'
                      )
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="conditions.businessHours" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONDITION_BUSINESS_HOURS'
                      )
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="conditions.firstInteraction" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONDITION_FIRST_INTERACTION'
                      )
                    }}
                  </span>
                </label>
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 2">
            <div class="flex flex-col gap-5">
              <div class="flex flex-col gap-3">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.ACTIONS_LABEL') }}
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="actions.sendReply" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.ACTION_SEND_REPLY'
                      )
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="actions.sendDm" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.ACTION_SEND_DM')
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="actions.addTag" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.ACTION_ADD_TAG')
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="actions.assignRoute" />
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.ACTION_ASSIGN_ROUTE'
                      )
                    }}
                  </span>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <RelayCheckbox v-model="actions.stopAutomation" />
                  <span class="text-[13.5px] font-medium text-destructive">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_AUTOMATION_MODAL.ACTION_STOP_OTHERS'
                      )
                    }}
                  </span>
                </label>
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 3">
            <div class="flex flex-col gap-5">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_LABEL') }}
                </label>
                <textarea
                  v-model="responseMessage"
                  rows="4"
                  :placeholder="
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_PLACEHOLDER'
                    )
                  "
                  class="w-full p-3 resize-none text-sm shadow-sm rounded-md border border-border/80 bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                />
                <div class="flex items-center justify-between mt-1">
                  <div class="flex items-center gap-2">
                    <button
                      type="button"
                      class="p-1 text-muted-foreground hover:bg-muted hover:text-foreground rounded flex items-center gap-1.5 transition-colors text-xs font-medium"
                    >
                      <span class="i-lucide-sparkles size-3.5" />
                      {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.VARIABLES') }}
                    </button>
                    <button
                      type="button"
                      class="p-1 text-muted-foreground hover:bg-muted hover:text-foreground rounded flex items-center gap-1.5 transition-colors text-xs font-medium"
                    >
                      <span class="i-lucide-image size-3.5" />
                      {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MEDIA') }}
                    </button>
                  </div>
                  <button
                    type="button"
                    class="text-primary text-xs font-medium hover:underline"
                  >
                    {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.PREVIEW') }}
                  </button>
                </div>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.DELAY_LABEL') }}
                </label>
                <RelayDropdownMenu>
                  <RelayDropdownMenuTrigger as-child>
                    <button
                      type="button"
                      class="w-full h-10 px-3 flex items-center justify-between text-sm shadow-sm rounded-md border border-border/80 bg-background cursor-pointer outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                    >
                      <span class="text-foreground">{{ delay }}</span>
                      <span
                        class="i-lucide-chevron-down size-4 text-muted-foreground shrink-0"
                      />
                    </button>
                  </RelayDropdownMenuTrigger>
                  <RelayDropdownMenuContent
                    align="start"
                    class="w-[--reka-dropdown-menu-trigger-width]"
                  >
                    <RelayDropdownMenuItem
                      v-for="opt in delayOptions"
                      :key="opt"
                      class="flex items-center justify-between cursor-pointer"
                      @click="delay = opt"
                    >
                      <span>{{ opt }}</span>
                      <span
                        v-if="delay === opt"
                        class="i-lucide-check size-4"
                      />
                    </RelayDropdownMenuItem>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>

                <div
                  v-if="delay === delayOptions[3]"
                  class="grid grid-cols-2 gap-3 mt-2"
                >
                  <div class="flex flex-col gap-1.5">
                    <label class="text-xs font-medium text-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.CUSTOM_DATE')
                      }}
                    </label>
                    <RelayDatePicker v-model="customDate" />
                  </div>
                  <div class="flex flex-col gap-1.5">
                    <label class="text-xs font-medium text-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.CUSTOM_TIME')
                      }}
                    </label>
                    <RelayTimePicker v-model="customTime" />
                  </div>
                </div>
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 4">
            <div class="flex flex-col gap-5">
              <div
                class="bg-muted/30 rounded-xl border border-border p-4 flex flex-col gap-4"
              >
                <h3 class="text-sm font-semibold text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_TITLE') }}
                </h3>

                <div class="flex items-start gap-3">
                  <div
                    class="mt-0.5 size-5 flex items-center justify-center bg-primary/10 text-primary rounded-full shrink-0 text-[11px] font-bold"
                  >
                    {{ 1 }}
                  </div>
                  <div>
                    <div class="text-[13px] font-medium text-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_TRIGGER')
                      }}
                    </div>
                    <div class="text-[13px] text-muted-foreground mt-0.5">
                      {{ triggerType }} — {{ platform }}
                    </div>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <div
                    class="mt-0.5 size-5 flex items-center justify-center bg-primary/10 text-primary rounded-full shrink-0 text-[11px] font-bold"
                  >
                    {{ 2 }}
                  </div>
                  <div>
                    <div class="text-[13px] font-medium text-foreground">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_CONDITION'
                        )
                      }}
                    </div>
                    <div class="text-[13px] text-muted-foreground mt-0.5">
                      {{
                        conditions.containsKeyword
                          ? t(
                              'AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_KEYWORDS',
                              {
                                keywords:
                                  keywords ||
                                  t(
                                    'AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_NONE'
                                  ),
                              }
                            )
                          : t(
                              'AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_NO_CONDITIONS'
                            )
                      }}
                    </div>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <div
                    class="mt-0.5 size-5 flex items-center justify-center bg-primary/10 text-primary rounded-full shrink-0 text-[11px] font-bold"
                  >
                    {{ 3 }}
                  </div>
                  <div>
                    <div class="text-[13px] font-medium text-foreground">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_ACTION_TITLE'
                        )
                      }}
                    </div>
                    <div class="text-[13px] text-muted-foreground mt-0.5">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_ACTION',
                          { delay }
                        )
                      }}
                    </div>
                  </div>
                </div>
              </div>

              <div
                class="flex items-center justify-between border-t border-border pt-4"
              >
                <div class="flex flex-col">
                  <span class="text-sm font-semibold text-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.ENABLE_LABEL')
                    }}
                  </span>
                  <span class="text-xs text-muted-foreground mt-0.5">
                    {{
                      t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.ENABLE_HELPER')
                    }}
                  </span>
                </div>
                <RelaySwitch v-model="isEnabled" />
              </div>
            </div>
          </template>

          <div
            v-if="currentStep === 0 && showSafetyNotice"
            class="mt-4 bg-primary/5 rounded-xl border border-primary/20 p-4 flex gap-3"
          >
            <span class="i-lucide-shield size-5 text-primary shrink-0" />
            <div>
              <div
                class="text-[13.5px] font-semibold text-foreground flex items-center justify-between"
              >
                {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.SAFETY_TITLE') }}
                <button type="button" @click="showSafetyNotice = false">
                  <span
                    class="i-lucide-x size-3.5 text-muted-foreground cursor-pointer hover:text-foreground"
                  />
                </button>
              </div>
              <p class="text-xs text-muted-foreground mt-1 leading-relaxed">
                {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.SAFETY_DESC') }}
              </p>
            </div>
          </div>
        </div>

        <div
          class="p-4 border-t border-border flex items-center justify-between bg-muted/10"
        >
          <RelayButton
            variant="outline"
            @click="currentStep === 0 ? closeModal() : prevStep()"
          >
            {{
              currentStep === 0
                ? t('AUTORESPONDER.COMMON.CANCEL')
                : t('AUTORESPONDER.COMMON.BACK')
            }}
          </RelayButton>

          <RelayButton class="min-w-[100px]" @click="nextStep">
            {{
              currentStep === steps.length - 1
                ? t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.SAVE_RULE')
                : t('AUTORESPONDER.COMMON.NEXT')
            }}
          </RelayButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>
