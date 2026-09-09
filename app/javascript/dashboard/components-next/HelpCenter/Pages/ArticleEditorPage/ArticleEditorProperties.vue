<script setup>
import { reactive, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import {
  RelayInput,
  RelayTextarea,
  RelayLabel,
} from 'dashboard/components-next/relay';
import { RELAY_MODAL_CLOSE_BUTTON_CLASS } from 'dashboard/components-next/relay/modal/constants';

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
      <button
        type="button"
        :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
        @click="emit('close')"
      >
        <span class="i-lucide-x size-4" aria-hidden="true" />
      </button>
    </div>
    <div class="flex flex-col gap-4 px-2.5 pb-2">
      <div class="flex flex-col gap-1.5">
        <RelayLabel>
          {{
            t(
              'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_DESCRIPTION'
            )
          }}
        </RelayLabel>
        <RelayTextarea
          v-model="state.description"
          :placeholder="
            t(
              'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_DESCRIPTION_PLACEHOLDER'
            )
          "
        />
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel>
          {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TITLE') }}
        </RelayLabel>
        <RelayInput
          v-model="state.title"
          :placeholder="
            t(
              'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TITLE_PLACEHOLDER'
            )
          "
        />
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel>
          {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TAGS') }}
        </RelayLabel>
        <TagInput
          v-model="state.tags"
          :placeholder="
            t(
              'HELP_CENTER.EDIT_ARTICLE_PAGE.ARTICLE_PROPERTIES.META_TAGS_PLACEHOLDER'
            )
          "
          class="w-full"
        />
      </div>
    </div>
  </div>
</template>
