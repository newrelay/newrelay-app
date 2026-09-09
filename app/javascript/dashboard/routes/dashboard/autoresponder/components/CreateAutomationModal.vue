<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { extractResponseMessage } from 'shared/helpers/CustomErrors';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  RelayButton,
  RelayInput,
  RelayTextarea,
  RelaySwitch,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { RELAY_MODAL_CLOSE_BUTTON_CLASS } from 'dashboard/components-next/relay/modal/constants';

const props = defineProps({
  open: { type: Boolean, default: false },
  template: { type: Object, default: null },
});

const emit = defineEmits(['update:open']);

const { t } = useI18n();
const store = useStore();
const { accountScopedRoute } = useAccount();
const isMock = computed(() => !!window.newrelayConfig?.commentAutomationMock);

function normalizePostId(value) {
  const raw = String(value || '').trim();
  const match = raw.match(/instagram\.com\/(?:p|reel|tv)\/([^/?#]+)/i);
  return match ? match[1] : raw;
}

onMounted(() => {
  store.dispatch('inboxes/get');
});

const allInboxes = useMapGetter('inboxes/getInboxes');
const instagramInboxes = computed(() =>
  allInboxes.value.filter(inbox => inbox.channel_type === INBOX_TYPES.INSTAGRAM)
);

const steps = computed(() => [
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_TRIGGER'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_CONDITION'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_RESPONSE'),
  t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_REVIEW'),
]);
const currentStep = ref(0);

// Step 1: Basics
const automationName = ref('');
const inboxId = ref(null);
const postId = ref('');

watch(
  instagramInboxes,
  list => {
    if (!inboxId.value && list.length) inboxId.value = list[0].id;
  },
  { immediate: true }
);

// Step 2: Condition
const keyword = ref('');
const matchType = ref('contains');

// Step 3: Response
const publicRepliesText = ref('');
const dmTextBody = ref('');
const templateId = ref(null);

watch(
  () => props.open,
  isOpen => {
    if (!isOpen) return;
    if (isMock.value && !postId.value) postId.value = 'mock-summer-sale';
    if (props.template) {
      publicRepliesText.value = props.template.public_replies.join('\n');
      dmTextBody.value = props.template.dm_text_body || '';
      templateId.value = props.template.id;
    }
  }
);

// Step 4: Review
const isEnabled = ref(true);
const isSaving = ref(false);

const selectedInbox = computed(() =>
  instagramInboxes.value.find(inbox => inbox.id === inboxId.value)
);

const publicReplies = computed(() =>
  publicRepliesText.value
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
);

const canSave = computed(
  () =>
    automationName.value.trim() &&
    inboxId.value &&
    postId.value.trim() &&
    keyword.value.trim() &&
    publicReplies.value.length &&
    dmTextBody.value.trim()
);

const resetForm = () => {
  currentStep.value = 0;
  automationName.value = '';
  inboxId.value = instagramInboxes.value[0]?.id || null;
  postId.value = '';
  keyword.value = '';
  matchType.value = 'contains';
  publicRepliesText.value = '';
  dmTextBody.value = '';
  templateId.value = null;
  isEnabled.value = true;
};

const closeModal = () => {
  emit('update:open', false);
  setTimeout(resetForm, 200);
};

const prevStep = () => {
  if (currentStep.value > 0) {
    currentStep.value -= 1;
  } else {
    closeModal();
  }
};

const save = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('commentAutomationCampaigns/create', {
      campaign: {
        name: automationName.value,
        inbox_id: inboxId.value,
        post_id: normalizePostId(postId.value),
        is_active: isEnabled.value,
      },
      trigger: {
        keyword: keyword.value,
        match_type: matchType.value,
        public_replies: publicReplies.value,
        dm_text_body: dmTextBody.value,
        template_id: templateId.value,
      },
    });
    closeModal();
  } catch (error) {
    useAlert(extractResponseMessage(error) || error.message);
  } finally {
    isSaving.value = false;
  }
};

const nextStep = () => {
  if (currentStep.value < steps.value.length - 1) {
    currentStep.value += 1;
  } else {
    save();
  }
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[100] flex items-center justify-center bg-background/80 backdrop-blur-[8px] p-4 sm:p-6"
      @click.self="closeModal"
    >
      <div
        class="bg-background w-full max-w-[550px] rounded-2xl shadow-xl flex flex-col max-h-[90vh] overflow-hidden relative border border-border/50"
      >
        <div class="flex flex-col p-6 pb-8 border-b border-border">
          <div class="flex items-center justify-between">
            <h2 class="text-base font-medium tracking-tight text-foreground">
              {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.TITLE') }}
            </h2>
            <button
              type="button"
              :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
              @click="closeModal"
            >
              <span class="i-lucide-x size-4" />
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

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.PLATFORM_LABEL')
                  }}
                </label>
                <RelayDropdownMenu v-if="instagramInboxes.length">
                  <RelayDropdownMenuTrigger as-child>
                    <button
                      type="button"
                      class="w-full h-9 px-3 flex items-center justify-between text-sm shadow-sm rounded-md border border-border/80 bg-background cursor-pointer outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                    >
                      <span class="text-foreground">{{
                        selectedInbox?.name ||
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.SELECT_INBOX')
                      }}</span>
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
                      v-for="inbox in instagramInboxes"
                      :key="inbox.id"
                      class="flex items-center justify-between cursor-pointer"
                      @click="inboxId = inbox.id"
                    >
                      <span>{{ inbox.name }}</span>
                      <span
                        v-if="inboxId === inbox.id"
                        class="i-lucide-check size-4"
                      />
                    </RelayDropdownMenuItem>
                  </RelayDropdownMenuContent>
                </RelayDropdownMenu>
                <div
                  v-else
                  class="text-xs text-muted-foreground bg-muted/40 border border-border rounded-md p-3"
                >
                  {{
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.NO_INSTAGRAM_INBOX'
                    )
                  }}
                  <router-link
                    :to="accountScopedRoute('settings_inbox_new')"
                    class="text-primary hover:underline"
                  >
                    {{
                      t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.CONNECT_LINK')
                    }}
                  </router-link>
                </div>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.POST_ID_LABEL') }}
                </label>
                <RelayInput
                  v-model="postId"
                  :placeholder="
                    t(
                      isMock
                        ? 'AUTORESPONDER.CREATE_AUTOMATION_MODAL.POST_ID_PLACEHOLDER_MOCK'
                        : 'AUTORESPONDER.CREATE_AUTOMATION_MODAL.POST_ID_PLACEHOLDER'
                    )
                  "
                />
                <p class="text-xs text-muted-foreground mt-1">
                  {{
                    t(
                      isMock
                        ? 'AUTORESPONDER.CREATE_AUTOMATION_MODAL.POST_ID_HELPER_MOCK'
                        : 'AUTORESPONDER.CREATE_AUTOMATION_MODAL.POST_ID_HELPER'
                    )
                  }}
                </p>
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 1">
            <div class="flex flex-col gap-5">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.KEYWORDS_LABEL')
                  }}
                </label>
                <RelayInput
                  v-model="keyword"
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

              <div class="flex flex-col gap-3">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MATCH_TYPE_LABEL')
                  }}
                </label>
                <div class="grid grid-cols-2 gap-4">
                  <div
                    class="relative border rounded-xl p-4 cursor-pointer transition-colors"
                    :class="
                      matchType === 'contains'
                        ? 'border-primary bg-primary/5 ring-1 ring-primary'
                        : 'border-border hover:border-foreground/20'
                    "
                    @click="matchType = 'contains'"
                  >
                    <div class="text-sm font-semibold text-foreground">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.MATCH_CONTAINS'
                        )
                      }}
                    </div>
                    <div class="text-xs text-muted-foreground mt-1">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.MATCH_CONTAINS_DESC'
                        )
                      }}
                    </div>
                  </div>
                  <div
                    class="relative border rounded-xl p-4 cursor-pointer transition-colors"
                    :class="
                      matchType === 'exact'
                        ? 'border-primary bg-primary/5 ring-1 ring-primary'
                        : 'border-border hover:border-foreground/20'
                    "
                    @click="matchType = 'exact'"
                  >
                    <div class="text-sm font-semibold text-foreground">
                      {{
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MATCH_EXACT')
                      }}
                    </div>
                    <div class="text-xs text-muted-foreground mt-1">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.MATCH_EXACT_DESC'
                        )
                      }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 2">
            <div class="flex flex-col gap-5">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_LABEL'
                    )
                  }}
                </label>
                <RelayTextarea
                  v-model="publicRepliesText"
                  :rows="3"
                  :placeholder="
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_PLACEHOLDER'
                    )
                  "
                  class-name="text-[14px] resize-none"
                />
                <p class="text-xs text-muted-foreground mt-1">
                  {{
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_HELPER'
                    )
                  }}
                </p>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_LABEL') }}
                </label>
                <RelayTextarea
                  v-model="dmTextBody"
                  :rows="4"
                  :placeholder="
                    t(
                      'AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_PLACEHOLDER'
                    )
                  "
                  class-name="text-[14px] resize-none"
                />
              </div>
            </div>
          </template>

          <template v-else-if="currentStep === 3">
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
                      {{ automationName }}
                    </div>
                    <div class="text-[13px] text-muted-foreground mt-0.5">
                      {{ selectedInbox?.name }} &bull;
                      {{ t('AUTORESPONDER.AUTOMATIONS.POST_ID_LABEL') }}
                      {{ postId }}
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
                        t(
                          matchType === 'exact'
                            ? 'AUTORESPONDER.AUTOMATIONS.KEYWORD_EXACT'
                            : 'AUTORESPONDER.AUTOMATIONS.KEYWORD_CONTAINS',
                          { keyword }
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
                        t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.STEP_RESPONSE')
                      }}
                    </div>
                    <div class="text-[13px] text-muted-foreground mt-0.5">
                      {{
                        t(
                          'AUTORESPONDER.CREATE_AUTOMATION_MODAL.SUMMARY_RESPONSE',
                          { count: publicReplies.length }
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
        </div>

        <div
          class="p-4 border-t border-border flex items-center justify-between bg-muted/10"
        >
          <RelayButton variant="outline" @click="prevStep">
            {{
              currentStep === 0
                ? t('AUTORESPONDER.COMMON.CANCEL')
                : t('AUTORESPONDER.COMMON.BACK')
            }}
          </RelayButton>

          <RelayButton
            class="min-w-[100px]"
            :disabled="
              currentStep === steps.length - 1 && (!canSave || isSaving)
            "
            @click="nextStep"
          >
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
