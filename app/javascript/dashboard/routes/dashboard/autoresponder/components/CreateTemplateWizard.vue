<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import {
  RelayButton,
  RelayInput,
  RelayCheckbox,
} from 'dashboard/components-next/relay';

const props = defineProps({
  open: { type: Boolean, default: false },
  template: { type: Object, default: null },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();
const store = useStore();

const name = ref('');
const templateType = ref('message');
const publicRepliesText = ref('');
const dmTextBody = ref('');
const favorite = ref(false);
const isSaving = ref(false);

const isEditMode = computed(() => !!props.template);

watch(
  () => props.open,
  isOpen => {
    if (!isOpen) return;
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

const canSave = computed(
  () =>
    name.value.trim() && publicReplies.value.length && dmTextBody.value.trim()
);

const closeWizard = () => emit('update:open', false);

const save = async () => {
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
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[120] flex items-center justify-center bg-background/80 backdrop-blur-md p-4 sm:p-6"
      @click.self="closeWizard"
    >
      <div
        class="bg-background w-full max-w-[520px] rounded-2xl shadow-xl flex flex-col max-h-[90vh] overflow-hidden relative border border-border/50"
      >
        <div
          class="flex items-center justify-between p-6 pb-4 border-b border-border"
        >
          <h2 class="text-xl font-semibold tracking-tight text-foreground">
            {{
              isEditMode
                ? t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.EDIT_TITLE')
                : t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.TITLE')
            }}
          </h2>
          <button
            type="button"
            class="p-1 text-muted-foreground hover:bg-muted rounded-full transition-colors"
            @click="closeWizard"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-6 flex flex-col gap-6">
          <div class="flex flex-col gap-3">
            <span class="text-[13.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.TEMPLATE_TYPE') }}
            </span>
            <div class="grid grid-cols-2 gap-4">
              <div
                class="relative border rounded-xl p-4 cursor-pointer transition-colors"
                :class="
                  templateType === 'message'
                    ? 'border-primary bg-primary/5 ring-1 ring-primary'
                    : 'border-border hover:border-foreground/20'
                "
                @click="templateType = 'message'"
              >
                <div class="text-sm font-semibold text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.MESSAGE_TEMPLATE')
                  }}
                </div>
                <div class="text-xs text-muted-foreground mt-1">
                  {{
                    t(
                      'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.MESSAGE_TEMPLATE_DESC'
                    )
                  }}
                </div>
              </div>
              <div
                class="relative border rounded-xl p-4 cursor-pointer transition-colors"
                :class="
                  templateType === 'comment'
                    ? 'border-primary bg-primary/5 ring-1 ring-primary'
                    : 'border-border hover:border-foreground/20'
                "
                @click="templateType = 'comment'"
              >
                <div class="text-sm font-semibold text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.COMMENT_TEMPLATE')
                  }}
                </div>
                <div class="text-xs text-muted-foreground mt-1">
                  {{
                    t(
                      'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.COMMENT_TEMPLATE_DESC'
                    )
                  }}
                </div>
              </div>
            </div>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_LABEL') }}
            </label>
            <RelayInput
              v-model="name"
              :placeholder="
                t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_PLACEHOLDER')
              "
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{
                t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_LABEL')
              }}
            </label>
            <textarea
              v-model="publicRepliesText"
              rows="3"
              :placeholder="
                t(
                  'AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_PLACEHOLDER'
                )
              "
              class="w-full p-3 resize-none text-sm shadow-sm rounded-md border border-border/80 bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
            <p class="text-xs text-muted-foreground mt-1">
              {{
                t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.PUBLIC_REPLIES_HELPER')
              }}
            </p>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_LABEL') }}
            </label>
            <textarea
              v-model="dmTextBody"
              rows="4"
              :placeholder="
                t('AUTORESPONDER.CREATE_AUTOMATION_MODAL.MESSAGE_PLACEHOLDER')
              "
              class="w-full p-3 resize-none text-sm shadow-sm rounded-md border border-border/80 bg-background focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>

          <label class="flex items-center gap-2 cursor-pointer">
            <RelayCheckbox v-model="favorite" />
            <span class="text-[13.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.FAVORITE_LABEL') }}
            </span>
          </label>
        </div>

        <div
          class="p-4 border-t border-border flex items-center justify-between bg-muted/10"
        >
          <RelayButton variant="outline" @click="closeWizard">
            {{ t('AUTORESPONDER.COMMON.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="min-w-[100px]"
            :disabled="!canSave || isSaving"
            @click="save"
          >
            {{ t('AUTORESPONDER.COMMON.SAVE_CHANGES') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>
