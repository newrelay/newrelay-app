<script setup>
import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';
import { TWILIO_CONTENT_TEMPLATE_TYPES } from 'shared/constants/messages';

const props = defineProps({
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSelect']);

const { t } = useI18n();
const store = useStore();
const query = ref('');
const isRefreshing = ref(false);

const twilioTemplates = computed(() => {
  const inbox = store.getters['inboxes/getInbox'](props.inboxId);
  return inbox?.content_templates?.templates || [];
});

const filteredTemplateMessages = computed(() =>
  twilioTemplates.value.filter(
    template =>
      template.friendly_name
        .toLowerCase()
        .includes(query.value.toLowerCase()) && template.status === 'approved'
  )
);

const getTemplateType = template => {
  if (template.template_type === TWILIO_CONTENT_TEMPLATE_TYPES.MEDIA) {
    return t('CONTENT_TEMPLATES.PICKER.TYPES.MEDIA');
  }
  if (template.template_type === TWILIO_CONTENT_TEMPLATE_TYPES.QUICK_REPLY) {
    return t('CONTENT_TEMPLATES.PICKER.TYPES.QUICK_REPLY');
  }
  if (template.template_type === TWILIO_CONTENT_TEMPLATE_TYPES.CALL_TO_ACTION) {
    return t('CONTENT_TEMPLATES.PICKER.TYPES.CALL_TO_ACTION');
  }
  return t('CONTENT_TEMPLATES.PICKER.TYPES.TEXT');
};

const refreshTemplates = async () => {
  isRefreshing.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', props.inboxId);
    useAlert(t('CONTENT_TEMPLATES.PICKER.REFRESH_SUCCESS'));
  } catch (error) {
    useAlert(t('CONTENT_TEMPLATES.PICKER.REFRESH_ERROR'));
  } finally {
    isRefreshing.value = false;
  }
};
</script>

<template>
  <div class="w-full">
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-black/10 outline outline-1 outline-border hover:outline-border dark:hover:outline-border focus-within:outline-primary dark:focus-within:outline-primary"
      >
        <fluent-icon icon="search" class="text-foreground" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('CONTENT_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-foreground ! !outline-0 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>
      <button
        :disabled="isRefreshing"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-black/10 outline outline-1 outline-border hover:outline-border dark:hover:outline-border hover:bg-accent dark:hover:bg-secondary disabled:opacity-50 disabled:cursor-not-allowed"
        :title="t('CONTENT_TEMPLATES.PICKER.REFRESH_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="text-foreground size-4"
          :class="{ 'animate-spin': isRefreshing }"
        />
      </button>
    </div>
    <div
      class="bg-background outline-card outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div
        v-for="(template, i) in filteredTemplateMessages"
        :key="template.content_sid"
      >
        <button
          class="block p-2.5 w-full text-left rounded-lg cursor-pointer hover:bg-accent dark:hover:bg-secondary"
          @click="emit('onSelect', template)"
        >
          <div>
            <div class="flex justify-between items-center mb-2.5">
              <p class="text-sm">
                {{ template.friendly_name }}
              </p>
              <div class="flex gap-2">
                <span
                  class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-muted text-foreground"
                >
                  {{ getTemplateType(template) }}
                </span>
                <span
                  class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-muted text-foreground"
                >
                  {{
                    `${t('CONTENT_TEMPLATES.PICKER.LABELS.LANGUAGE')}: ${template.language}`
                  }}
                </span>
              </div>
            </div>

            <!-- Body -->
            <div>
              <p class="text-xs font-medium text-muted-foreground">
                {{ t('CONTENT_TEMPLATES.PICKER.BODY') }}
              </p>
              <p class="text-sm label-body">
                {{ template.body || t('CONTENT_TEMPLATES.PICKER.NO_CONTENT') }}
              </p>
            </div>

            <div class="flex justify-between items-center mt-3">
              <div>
                <p class="text-xs font-medium text-muted-foreground">
                  {{ t('CONTENT_TEMPLATES.PICKER.LABELS.CATEGORY') }}
                </p>
                <p class="text-sm">{{ template.category || 'utility' }}</p>
              </div>
              <div class="text-xs text-muted-foreground">
                {{ new Date(template.created_at).toLocaleDateString() }}
              </div>
            </div>
          </div>
        </button>
        <hr
          v-if="i != filteredTemplateMessages.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-border my-2.5 mx-auto max-w-[95%]"
        />
      </div>
      <div v-if="!filteredTemplateMessages.length" class="py-8 text-center">
        <div v-if="query && twilioTemplates.length">
          <p>
            {{ t('CONTENT_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <div v-else-if="!twilioTemplates.length" class="space-y-4">
          <p class="text-muted-foreground">
            {{ t('CONTENT_TEMPLATES.PICKER.NO_TEMPLATES_AVAILABLE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.label-body {
  font-family: monospace;
}
</style>
