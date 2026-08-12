<script setup>
import { reactive, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';

import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  article: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['saveArticle', 'close']);

const saveArticle = debounce(value => emit('saveArticle', value), 400, false);

const { t } = useI18n();

const state = reactive({
  title: '',
  description: '',
  tags: [],
});

const updateState = () => {
  state.title = props.article.meta?.title || '';
  state.description = props.article.meta?.description || '';
  state.tags = props.article.meta?.tags || [];
};

watch(
  state,
  newState => {
    saveArticle({
      title: newState.title,
      description: newState.description,
      tags: newState.tags,
    });
  },
  { deep: true }
);

onMounted(() => {
  updateState();
});
</script>

<template>
  <div
    class="absolute flex w-[25rem] flex-col gap-1.5 rounded-xl border border-border/80 bg-background p-1.5 shadow-lg"
  >
    <div
      class="mb-1 flex items-center justify-between border-b border-border/40 px-2.5 py-2"
    >
      <h3 class="text-[13.5px] font-medium text-foreground">
        {{
          t(
            'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.ARTICLE_PROPERTIES'
          )
        }}
      </h3>
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-7 text-muted-foreground hover:text-foreground"
        @click="emit('close')"
      >
        <span class="i-lucide-x size-3.5" aria-hidden="true" />
      </RelayButton>
    </div>
    <div class="flex flex-col gap-2 px-2.5 pb-2">
      <div>
        <div class="flex w-full justify-between gap-4 py-2">
          <label
            class="min-w-[6.25rem] whitespace-nowrap text-[13px] font-medium text-foreground"
          >
            {{
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_DESCRIPTION'
              )
            }}
          </label>
          <TextArea
            v-model="state.description"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_DESCRIPTION_PLACEHOLDER'
              )
            "
            class="w-[13.75rem]"
            custom-text-area-wrapper-class="!p-0 !border-0 !rounded-none !bg-transparent transition-none"
            custom-text-area-class="max-h-[9.375rem]"
            auto-height
            min-height="3rem"
          />
        </div>
        <div class="flex justify-between w-full gap-2 py-2">
          <InlineInput
            v-model="state.title"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TITLE_PLACEHOLDER'
              )
            "
            :label="
              t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TITLE')
            "
            custom-label-class="min-w-[7.5rem]"
          />
        </div>
        <div class="flex justify-between w-full gap-3 py-2">
          <label
            class="min-w-[7.5rem] whitespace-nowrap text-[13px] font-medium text-foreground"
          >
            {{
              t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TAGS')
            }}
          </label>
          <TagInput
            v-model="state.tags"
            :placeholder="
              t(
                'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TAGS_PLACEHOLDER'
              )
            "
            class="w-[14rem]"
          />
        </div>
      </div>
    </div>
  </div>
</template>
