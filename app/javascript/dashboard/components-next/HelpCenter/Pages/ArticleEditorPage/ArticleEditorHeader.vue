<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { OnClickOutside } from '@vueuse/components';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import {
  ARTICLE_EDITOR_STATUS_OPTIONS,
  ARTICLE_STATUSES,
  ARTICLE_MENU_ITEMS,
} from 'dashboard/helper/portalHelper';
import wootConstants from 'dashboard/constants/globals';

import ButtonGroup from 'dashboard/components-next/buttonGroup/ButtonGroup.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  isUpdating: {
    type: Boolean,
    default: false,
  },
  isSaved: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: '',
  },
  articleId: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['goBack', 'previewArticle']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const isArticlePublishing = ref(false);

const { ARTICLE_STATUS_TYPES } = wootConstants;

const showArticleActionMenu = ref(false);

const articleMenuItems = computed(() => {
  const statusOptions = ARTICLE_EDITOR_STATUS_OPTIONS[props.status] ?? [];
  return statusOptions.map(option => {
    const { label, value, icon } = ARTICLE_MENU_ITEMS[option];
    return {
      label: t(label),
      value,
      action: 'update-status',
      icon,
    };
  });
});

const statusText = computed(() =>
  t(
    `HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.STATUS.${props.isUpdating ? 'SAVING' : 'SAVED'}`
  )
);

const onClickGoBack = () => emit('goBack');

const previewArticle = () => emit('previewArticle');

const getStatusMessage = (status, isSuccess) => {
  const messageType = isSuccess ? 'SUCCESS' : 'ERROR';
  const statusMap = {
    [ARTICLE_STATUS_TYPES.PUBLISH]: 'PUBLISH_ARTICLE',
    [ARTICLE_STATUS_TYPES.ARCHIVE]: 'ARCHIVE_ARTICLE',
    [ARTICLE_STATUS_TYPES.DRAFT]: 'DRAFT_ARTICLE',
  };

  return statusMap[status]
    ? t(`HELP_CENTER.${statusMap[status]}.API.${messageType}`)
    : '';
};

const updateArticleStatus = async ({ value }) => {
  showArticleActionMenu.value = false;
  const status = getArticleStatus(value);
  if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
    isArticlePublishing.value = true;
  }
  const { portalSlug } = route.params;

  try {
    await store.dispatch('articles/update', {
      portalSlug,
      articleId: props.articleId,
      status,
    });

    useAlert(getStatusMessage(status, true));

    if (status === ARTICLE_STATUS_TYPES.ARCHIVE) {
      useTrack(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'header' });
    } else if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
      useTrack(PORTALS_EVENTS.PUBLISH_ARTICLE);
    }
    isArticlePublishing.value = false;
  } catch (error) {
    useAlert(error?.message ?? getStatusMessage(status, false));
    isArticlePublishing.value = false;
  }
};
</script>

<template>
  <div class="mb-6 flex items-center justify-between py-4">
    <RelayButton
      variant="ghost"
      size="sm"
      class="pl-2 text-[13px] text-muted-foreground hover:text-foreground"
      @click="onClickGoBack"
    >
      <span class="i-lucide-chevron-left size-4" aria-hidden="true" />
      {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.BACK_TO_ARTICLES') }}
    </RelayButton>
    <div class="flex items-center gap-4">
      <span
        v-if="isUpdating || isSaved"
        class="hidden text-[13px] text-muted-foreground transition-all duration-300 sm:inline-block"
      >
        {{ statusText }}
      </span>
      <RelayButton
        variant="outline"
        class="h-9 px-4 text-[13px] font-medium shadow-xs"
        :disabled="!articleId"
        @click="previewArticle"
      >
        {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PREVIEW') }}
      </RelayButton>
      <ButtonGroup class="flex items-center" no-animation>
        <RelayButton
          class="h-9 px-4 font-medium shadow-xs ltr:rounded-r-none rtl:rounded-l-none ltr:border-r ltr:border-primary-foreground/20 rtl:border-l rtl:border-primary-foreground/20"
          :disabled="
            status === ARTICLE_STATUSES.PUBLISHED ||
            !articleId ||
            isArticlePublishing
          "
          @click="updateArticleStatus({ value: ARTICLE_STATUSES.PUBLISHED })"
        >
          <span
            v-if="isArticlePublishing"
            class="i-lucide-loader-circle size-4 animate-spin"
            aria-hidden="true"
          />
          {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH') }}
        </RelayButton>
        <div class="relative">
          <OnClickOutside @trigger="showArticleActionMenu = false">
            <RelayButton
              :disabled="!articleId"
              class="h-9 px-2 shadow-xs ltr:rounded-l-none rtl:rounded-r-none"
              @click.stop="showArticleActionMenu = !showArticleActionMenu"
            >
              <span class="i-lucide-chevron-down size-4" aria-hidden="true" />
            </RelayButton>
            <DropdownMenu
              v-if="showArticleActionMenu"
              :menu-items="articleMenuItems"
              class="top-full mt-2 ltr:right-0 rtl:left-0"
              @action="updateArticleStatus($event)"
            />
          </OnClickOutside>
        </div>
      </ButtonGroup>
    </div>
  </div>
</template>
