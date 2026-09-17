<script setup>
import { ref, computed, onMounted } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
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

const route = useRoute();
const { shouldShowPaywall } = usePolicy();

const showAssistantSwitcherDropdown = ref(false);
const createAssistantDialogRef = ref(null);

const store = useStore();
const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');

const currentAssistantId = computed(() => route.params.assistantId);
const isFetchingAssistants = computed(() => uiFlags.value?.fetchingList);

const activeAssistant = computed(() => {
  const id = Number(currentAssistantId.value);
  return (
    assistants.value?.find(assistant => Number(assistant.id) === id) ||
    assistants.value?.[0] ||
    null
  );
});

const activeAssistantName = computed(() => activeAssistant.value?.name || '');

onMounted(() => {
  if (props.showAssistantSwitcher && !assistants.value?.length) {
    store.dispatch('captainAssistants/get');
  }
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
  <section
    class="flex h-full min-h-0 w-full flex-col overflow-hidden bg-background"
  >
    <header class="z-10 shrink-0">
      <div class="mx-auto mb-6 w-full max-w-7xl px-6 pt-6">
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
                    class="h-auto max-w-[14rem] justify-start gap-1.5 border-0 !px-0 text-xl font-semibold text-foreground hover:bg-transparent hover:opacity-80"
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
                    class="absolute ltr:left-0 rtl:right-0 top-12"
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
      </div>
    </header>
    <main class="flex min-h-0 flex-1 flex-col overflow-y-auto">
      <div
        class="mx-auto flex min-h-full w-full max-w-7xl flex-1 flex-col px-6 pb-6"
      >
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
        <div
          v-else-if="isEmpty"
          class="m-auto flex min-h-0 w-full flex-1 flex-col"
        >
          <slot name="emptyState" />
        </div>
        <slot v-else name="body" />
        <slot />
      </div>
    </main>
    <footer v-if="showPaginationFooter" class="shrink-0">
      <div class="mx-auto w-full max-w-7xl px-6 pb-6">
        <PaginationFooter
          :current-page="currentPage"
          :total-items="totalCount"
          :items-per-page="itemsPerPage"
          @update:current-page="handlePageChange"
        />
      </div>
    </footer>
    <CreateAssistantDialog ref="createAssistantDialogRef" type="create" />
  </section>
</template>
