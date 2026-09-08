<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import {
  RelayButton,
  RelayInput,
  RelayTextarea,
  RelayLabel,
  RelayCheckbox,
} from 'dashboard/components-next/relay';
import {
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_CHECKBOX_ROW_CLASS,
} from 'dashboard/components-next/relay/form/constants';

const props = defineProps({
  open: { type: Boolean, default: false },
  template: { type: Object, default: null },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();
const store = useStore();

const currentStep = ref(0);
const name = ref('');
const templateType = ref('message');
const publicRepliesText = ref('');
const dmTextBody = ref('');
const favorite = ref(false);
const isSaving = ref(false);

const isEditMode = computed(() => !!props.template);
const steps = computed(() => [
  t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.STEP_BASICS'),
  t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.STEP_CONTENT'),
]);

watch(
  () => props.open,
  isOpen => {
    if (!isOpen) return;
    currentStep.value = 0;
    if (props.template) {
      name.value = props.template.name;
      templateType.value = props.template.template_type;
      publicRepliesText.value = props.template.public_replies.join('\n');
      dmTextBody.value = props.template.dm_text_body || '';
      favorite.value = props.template.favorite;
    } else {
      name.value = '';
      templateType.value = 'message';
      publicRepliesText.value = '';
      dmTextBody.value = '';
      favorite.value = false;
    }
  }
);

const publicReplies = computed(() =>
  publicRepliesText.value
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
);

const previewReply = computed(
  () =>
    publicReplies.value[0] ||
    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_EMPTY')
);
const previewDm = computed(
  () =>
    dmTextBody.value.trim() ||
    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_EMPTY')
);

const canSave = computed(
  () =>
    name.value.trim() && publicReplies.value.length && dmTextBody.value.trim()
);

const closeWizard = () => emit('update:open', false);

const save = async () => {
  if (!canSave.value || isSaving.value) return;
  isSaving.value = true;
  const payload = {
    name: name.value,
    template_type: templateType.value,
    public_replies: publicReplies.value,
    dm_text_body: dmTextBody.value,
    favorite: favorite.value,
  };
  try {
    if (isEditMode.value) {
      await store.dispatch('commentAutomationTemplates/update', {
        id: props.template.id,
        template: payload,
      });
    } else {
      await store.dispatch('commentAutomationTemplates/create', {
        template: payload,
      });
    }
    closeWizard();
  } finally {
    isSaving.value = false;
  }
};

const prevStep = () => {
  if (currentStep.value === 0) {
    closeWizard();
    return;
  }
  currentStep.value -= 1;
};

const nextStep = () => {
  if (currentStep.value < steps.value.length - 1) {
    if (!name.value.trim()) return;
    currentStep.value += 1;
    return;
  }
  save();
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[120] bg-background flex flex-col h-screen overflow-hidden"
    >
      <div
        class="h-[88px] border-b border-border flex items-center justify-center relative shrink-0"
      >
        <div class="flex items-center gap-8 sm:gap-12">
          <template v-for="(step, index) in steps" :key="step">
            <div class="flex flex-col items-center gap-2 relative">
              <div
                class="size-8 rounded-full flex items-center justify-center text-[13px] font-medium z-10 transition-colors"
                :class="
                  currentStep === index
                    ? 'bg-primary text-primary-foreground'
                    : index < currentStep
                      ? 'bg-primary/20 text-primary'
                      : 'bg-muted text-muted-foreground'
                "
              >
                <span
                  v-if="index < currentStep"
                  class="i-lucide-check size-4"
                />
                <span v-else>{{ index + 1 }}</span>
              </div>
              <span
                class="text-[13px] font-medium absolute -bottom-6 whitespace-nowrap transition-colors"
                :class="
                  currentStep === index
                    ? 'text-primary'
                    : 'text-muted-foreground'
                "
              >
                {{ step }}
              </span>
              <div
                v-if="index < steps.length - 1"
                class="absolute left-10 top-4 w-12 h-px -translate-y-1/2"
                :class="index < currentStep ? 'bg-primary/30' : 'bg-border'"
              />
            </div>
          </template>
        </div>
        <button
          type="button"
          class="absolute right-6 top-1/2 -translate-y-1/2 text-muted-foreground hover:bg-muted p-2 rounded-full transition-colors"
          @click="closeWizard"
        >
          <span class="i-lucide-x size-5" />
        </button>
      </div>

      <div class="flex-1 flex overflow-hidden">
        <div class="flex-1 flex flex-col min-h-0">
          <div
            class="flex-1 overflow-y-auto px-4 py-8 sm:px-8 sm:py-10 lg:px-20"
          >
            <div class="w-full">
              <template v-if="currentStep === 0">
                <div class="mb-8">
                  <h1
                    class="text-[20px] font-[600] tracking-tight text-foreground"
                  >
                    {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.BASICS_TITLE') }}
                  </h1>
                  <p class="text-[14px] text-muted-foreground mt-1">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.BASICS_SUBTITLE')
                    }}
                  </p>
                </div>

                <div class="flex flex-col gap-8">
                  <div class="flex flex-col gap-3">
                    <span class="text-[13.5px] font-medium text-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.TEMPLATE_TYPE')
                      }}
                    </span>
                    <div class="grid grid-cols-2 gap-4">
                      <div
                        class="relative border rounded-xl p-5 cursor-pointer transition-all duration-200"
                        :class="
                          templateType === 'message'
                            ? 'border-primary bg-primary/5 shadow-sm'
                            : 'border-border hover:border-border/80'
                        "
                        @click="templateType = 'message'"
                      >
                        <div class="flex items-start gap-4">
                          <div
                            class="size-10 rounded-lg bg-primary/10 flex items-center justify-center shrink-0"
                          >
                            <span
                              class="i-lucide-message-square size-5 text-primary"
                            />
                          </div>
                          <div class="flex flex-col gap-1">
                            <span
                              class="text-[14px] font-semibold text-foreground"
                            >
                              {{
                                t(
                                  'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.MESSAGE_TEMPLATE'
                                )
                              }}
                            </span>
                            <span
                              class="text-[13px] text-muted-foreground leading-snug"
                            >
                              {{
                                t(
                                  'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.MESSAGE_TEMPLATE_DESC'
                                )
                              }}
                            </span>
                          </div>
                        </div>
                        <div
                          v-if="templateType === 'message'"
                          class="absolute top-4 right-4 size-5 rounded-full bg-primary flex items-center justify-center"
                        >
                          <span
                            class="i-lucide-check size-3 text-primary-foreground"
                          />
                        </div>
                        <div
                          v-else
                          class="absolute top-4 right-4 size-5 rounded-full border border-border"
                        />
                      </div>

                      <div
                        class="relative border rounded-xl p-5 cursor-pointer transition-all duration-200"
                        :class="
                          templateType === 'comment'
                            ? 'border-primary bg-primary/5 shadow-sm'
                            : 'border-border hover:border-border/80'
                        "
                        @click="templateType = 'comment'"
                      >
                        <div class="flex items-start gap-4">
                          <div
                            class="size-10 rounded-lg bg-primary/10 flex items-center justify-center shrink-0"
                          >
                            <span
                              class="i-lucide-message-circle size-5 text-primary"
                            />
                          </div>
                          <div class="flex flex-col gap-1">
                            <span
                              class="text-[14px] font-semibold text-foreground"
                            >
                              {{
                                t(
                                  'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.COMMENT_TEMPLATE'
                                )
                              }}
                            </span>
                            <span
                              class="text-[13px] text-muted-foreground leading-snug"
                            >
                              {{
                                t(
                                  'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.COMMENT_TEMPLATE_DESC'
                                )
                              }}
                            </span>
                          </div>
                        </div>
                        <div
                          v-if="templateType === 'comment'"
                          class="absolute top-4 right-4 size-5 rounded-full bg-primary flex items-center justify-center"
                        >
                          <span
                            class="i-lucide-check size-3 text-primary-foreground"
                          />
                        </div>
                        <div
                          v-else
                          class="absolute top-4 right-4 size-5 rounded-full border border-border"
                        />
                      </div>
                    </div>
                  </div>

                  <div :class="RELAY_FORM_FIELD_CLASS">
                    <RelayLabel>
                      {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_LABEL') }}
                    </RelayLabel>
                    <RelayInput
                      v-model="name"
                      :placeholder="
                        t(
                          'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_PLACEHOLDER'
                        )
                      "
                      class-name="h-9 text-[14px]"
                    />
                    <span class="text-[12px] text-muted-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_HELPER')
                      }}
                    </span>
                  </div>

                  <div :class="RELAY_FORM_CHECKBOX_ROW_CLASS">
                    <RelayCheckbox v-model="favorite" />
                    <span class="text-[13.5px] font-medium text-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.FAVORITE_LABEL')
                      }}
                    </span>
                  </div>
                </div>
              </template>

              <template v-else>
                <div class="mb-8">
                  <h1
                    class="text-[20px] font-[600] tracking-tight text-foreground"
                  >
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.CONTENT_TITLE')
                    }}
                  </h1>
                  <p class="text-[14px] text-muted-foreground mt-1">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.CONTENT_SUBTITLE')
                    }}
                  </p>
                </div>

                <div class="flex flex-col gap-8">
                  <div :class="RELAY_FORM_FIELD_CLASS">
                    <RelayLabel>
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_LABEL'
                        )
                      }}
                    </RelayLabel>
                    <RelayTextarea
                      v-model="publicRepliesText"
                      :rows="4"
                      :placeholder="
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_PLACEHOLDER'
                        )
                      "
                    />
                    <span class="text-[12px] text-muted-foreground">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_HELPER'
                        )
                      }}
                    </span>
                  </div>

                  <div :class="RELAY_FORM_FIELD_CLASS">
                    <RelayLabel>
                      {{
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_LABEL')
                      }}
                    </RelayLabel>
                    <RelayTextarea
                      v-model="dmTextBody"
                      :rows="5"
                      :placeholder="
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_PLACEHOLDER'
                        )
                      "
                    />
                  </div>
                </div>
              </template>
            </div>
          </div>

          <div
            class="bg-background border-t border-border px-4 py-4 sm:px-8 sm:py-5 lg:px-12 flex items-center justify-between shrink-0 gap-3"
          >
            <RelayButton
              variant="outline"
              class="h-10 px-6 font-medium border border-border hover:border-transparent"
              @click="prevStep"
            >
              {{
                currentStep === 0
                  ? t('AUTORESPONDER.COMMON.CANCEL')
                  : t('AUTORESPONDER.COMMON.BACK')
              }}
            </RelayButton>
            <RelayButton
              class="h-10 px-6 font-medium gap-2"
              :disabled="
                currentStep === 0 ? !name.trim() : !canSave || isSaving
              "
              @click="nextStep"
            >
              <template v-if="currentStep < steps.length - 1">
                {{ t('AUTORESPONDER.COMMON.NEXT') }}
                <span class="i-lucide-chevron-right size-4" />
              </template>
              <template v-else>
                {{
                  isEditMode
                    ? t('AUTORESPONDER.COMMON.SAVE_CHANGES')
                    : t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.CREATE')
                }}
              </template>
            </RelayButton>
          </div>
        </div>

        <div
          class="hidden lg:flex w-[45%] shrink-0 border-l border-border bg-muted/10 flex-col h-full overflow-y-auto"
        >
          <div class="p-8 flex flex-col gap-8">
            <div class="flex flex-col gap-4">
              <div class="flex flex-col gap-1">
                <h3 class="text-[14px] font-semibold text-foreground">
                  {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_TITLE') }}
                </h3>
                <p class="text-[13px] text-muted-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_SUBTITLE')
                  }}
                </p>
              </div>

              <div
                class="bg-card border border-border rounded-xl overflow-hidden shadow-sm flex flex-col mt-2"
              >
                <div class="flex border-b border-border pt-1 px-2">
                  <div
                    class="flex items-center gap-2 px-3 pb-2.5 pt-2 text-[12px] font-medium border-b-2 -mb-px border-primary text-primary"
                  >
                    <span class="i-lucide-message-circle size-3.5" />
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_PUBLIC')
                    }}
                  </div>
                </div>
                <div class="p-4 bg-background min-h-[140px] flex flex-col">
                  <div
                    class="bg-muted/50 rounded-2xl rounded-tl-sm p-4 text-[13.5px] text-foreground self-start max-w-[85%] whitespace-pre-wrap shadow-sm border border-border/50"
                  >
                    {{ previewReply }}
                  </div>
                </div>
              </div>

              <div
                class="bg-card border border-border rounded-xl overflow-hidden shadow-sm flex flex-col"
              >
                <div class="flex border-b border-border pt-1 px-2">
                  <div
                    class="flex items-center gap-2 px-3 pb-2.5 pt-2 text-[12px] font-medium border-b-2 -mb-px border-primary text-primary"
                  >
                    <span class="i-lucide-message-square size-3.5" />
                    {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_DM') }}
                  </div>
                </div>
                <div class="p-4 bg-background min-h-[140px] flex flex-col">
                  <div
                    class="bg-muted/50 rounded-2xl rounded-tl-sm p-4 text-[13.5px] text-foreground self-start max-w-[85%] whitespace-pre-wrap shadow-sm border border-border/50"
                  >
                    {{ previewDm }}
                  </div>
                </div>
              </div>
            </div>

            <div
              class="bg-primary/5 border border-primary/10 rounded-xl p-5 flex flex-col gap-2 mt-2"
            >
              <div class="flex items-center gap-2">
                <span class="i-lucide-shield size-4 text-primary" />
                <span class="text-[14px] font-semibold text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.SAVE_TIME_TITLE')
                  }}
                </span>
              </div>
              <p class="text-[13px] text-muted-foreground leading-relaxed">
                {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.SAVE_TIME_BODY') }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
