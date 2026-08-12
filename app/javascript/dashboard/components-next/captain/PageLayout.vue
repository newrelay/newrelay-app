<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { RelayButton } from 'dashboard/components-next/relay';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Policy from 'dashboard/components/policy.vue';
import AssistantSwitcher from 'dashboard/components-next/captain/pageComponents/switcher/AssistantSwitcher.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  totalCount: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 25,
  },
  headerTitle: {
    type: String,
    default: '',
  },
  headerSubtitle: {
    type: String,
    default: '',
  },
  backUrl: {
    type: [String, Object],
    default: '',
  },
  buttonPolicy: {
    type: Array,
    default: () => [],
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  featureFlag: {
    type: String,
    default: '',
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  showKnowMore: {
    type: Boolean,
    default: true,
  },
  isEmpty: {
    type: Boolean,
    default: false,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
  showAssistantSwitcher: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['click', 'close', 'update:currentPage']);

const { t } = useI18n();

const route = useRoute();
const { shouldShowPaywall } = usePolicy();

const showAssistantSwitcherDropdown = ref(false);
const createAssistantDialogRef = ref(null);

const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');

const currentAssistantId = computed(() => route.params.assistantId);
const isFetchingAssistants = computed(() => uiFlags.value?.fetchingList);

const activeAssistantName = computed(() => {
  return (
    assistants.value?.find(
      assistant => assistant.id === Number(currentAssistantId.value)
    )?.name || t('CAPTAIN.ASSISTANT_SWITCHER.NEW_ASSISTANT')
  );
});

const showPaywall = computed(() => {
  return shouldShowPaywall(props.featureFlag);
});

const handleButtonClick = () => {
  emit('click');
};

const handlePageChange = event => {
  emit('update:currentPage', event);
};

const toggleAssistantSwitcher = () => {
  showAssistantSwitcherDropdown.value = !showAssistantSwitcherDropdown.value;
};

const handleCreateAssistant = () => {
  showAssistantSwitcherDropdown.value = false;
  createAssistantDialogRef.value.dialogRef.open();
};
</script>

<template>
  <section class="flex h-full w-full flex-col overflow-hidden bg-background">
    <div
      class="mx-auto flex h-full w-full max-w-7xl flex-col overflow-hidden p-6 lg:px-10"
    >
      <header class="z-10 mb-6 shrink-0">
        <div
          class="flex w-full flex-col items-start justify-between gap-4 sm:flex-row"
          :class="headerSubtitle ? 'sm:items-start' : 'sm:items-center'"
        >
          <div class="space-y-1">
            <div class="flex items-center gap-3">
              <BackButton v-if="backUrl" :back-url="backUrl" />
              <div
                v-if="showAssistantSwitcher && !showPaywall"
                class="relative flex items-center"
              >
                <OnClickOutside
                  @trigger="showAssistantSwitcherDropdown = false"
                >
                  <RelayButton
                    variant="ghost"
                    class="h-auto max-w-[14rem] gap-1.5 border-0 px-0 text-xl font-semibold text-foreground hover:bg-transparent hover:opacity-80"
                    :disabled="isFetchingAssistants"
                    @click="toggleAssistantSwitcher"
                  >
                    <span
                      v-if="isFetchingAssistants"
                      class="i-lucide-loader-circle size-4 shrink-0 animate-spin text-muted-foreground"
                    />
                    <span class="min-w-0 truncate">
                      {{ activeAssistantName }}
                    </span>
                    <span
                      class="i-lucide-chevron-down size-4 shrink-0 text-muted-foreground opacity-50"
                    />
                  </RelayButton>

                  <AssistantSwitcher
                    v-if="showAssistantSwitcherDropdown"
                    class="absolute ltr:left-0 rtl:right-0 top-9"
                    @close="showAssistantSwitcherDropdown = false"
                    @create-assistant="handleCreateAssistant"
                  />
                </OnClickOutside>
              </div>
              <div class="flex items-center gap-3">
                <div
                  v-if="showAssistantSwitcher && !showPaywall && headerTitle"
                  class="hidden h-5 w-px bg-border sm:block"
                />
                <h1
                  v-if="headerTitle"
                  class="hidden text-xl font-medium text-muted-foreground sm:block"
                >
                  {{ headerTitle }}
                </h1>
                <div v-if="showKnowMore" class="flex items-center gap-2">
                  <div class="h-5 w-px bg-border" />
                  <slot name="knowMore" />
                </div>
              </div>
            </div>
            <p
              v-if="headerSubtitle"
              class="text-[13.5px] text-muted-foreground"
            >
              {{ headerSubtitle }}
            </p>
          </div>

          <div class="flex w-full items-center gap-3 sm:w-auto">
            <slot name="search" />
            <div
              v-if="!showPaywall && buttonLabel"
              v-on-clickaway="() => emit('close')"
              class="relative shrink-0"
            >
              <Policy class="contents" :permissions="buttonPolicy">
                <RelayButton class="h-9 shrink-0" @click="handleButtonClick">
                  <span class="i-lucide-plus mr-1.5 size-4" />
                  {{ buttonLabel }}
                </RelayButton>
              </Policy>
              <slot name="action" />
            </div>
          </div>
        </div>
        <slot name="subHeader" />
      </header>
      <main class="min-h-0 flex-1 overflow-y-auto">
        <slot v-if="!showPaywall" name="controls" />
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-muted-foreground"
        >
          <Spinner />
        </div>
        <div v-else-if="showPaywall">
          <slot name="paywall" />
        </div>
        <div v-else-if="isEmpty" class="flex h-full min-h-0 flex-col">
          <slot name="emptyState" />
        </div>
        <slot v-else name="body" />
        <slot />
      </main>
    </div>
    <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalCount"
        :items-per-page="itemsPerPage"
        class="max-w-[67rem]"
        @update:current-page="handlePageChange"
      />
    </footer>
    <CreateAssistantDialog ref="createAssistantDialogRef" type="create" />
  </section>
</template>
