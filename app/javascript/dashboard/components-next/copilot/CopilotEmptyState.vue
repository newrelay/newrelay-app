<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

defineProps({
  hasAssistants: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['useSuggestion']);
const { t } = useI18n();
const route = useRoute();

const routePromptMap = {
  conversations: [
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.CONTENT',
    },
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
    },
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.RATE.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.RATE.CONTENT',
    },
  ],
  dashboard: [
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.CONTENT',
    },
    {
      label: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.LABEL',
      prompt: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.CONTENT',
    },
  ],
};

const getCurrentRoute = () => {
  const path = route.path;
  if (path.includes('/conversations')) return 'conversations';
  if (path.includes('/dashboard')) return 'dashboard';
  if (path.includes('/inbox')) return 'dashboard';
  return 'dashboard';
};

const promptOptions = computed(() => {
  const currentRoute = getCurrentRoute();
  return routePromptMap[currentRoute] || routePromptMap.conversations;
});

const handleSuggestion = opt => {
  emit('useSuggestion', t(opt.prompt));
};
</script>

<template>
  <div class="flex flex-1 w-full flex-col gap-6">
    <div class="flex flex-col gap-4">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 ring-4 ring-primary/5"
      >
        <span class="i-lucide-brain-circuit size-5 text-primary" />
      </div>
      <div class="space-y-2">
        <h3 class="text-[20px] font-[600] leading-8 text-foreground">
          {{ $t('CAPTAIN.COPILOT.PANEL_TITLE') }}
        </h3>
        <p class="text-sm leading-relaxed text-muted-foreground">
          {{ $t('CAPTAIN.COPILOT.KICK_OFF_MESSAGE') }}
        </p>
      </div>
    </div>

    <div v-if="!hasAssistants" class="w-full space-y-2">
      <p class="text-sm leading-relaxed text-muted-foreground">
        {{ $t('CAPTAIN.ASSISTANTS.NO_ASSISTANTS_AVAILABLE') }}
      </p>
      <router-link
        :to="{
          name: 'captain_assistants_create_index',
          params: {
            accountId: route.params.accountId,
          },
        }"
        class="text-sm text-muted-foreground underline hover:text-foreground"
      >
        {{ $t('CAPTAIN.ASSISTANTS.ADD_NEW') }}
      </router-link>
    </div>

    <div v-else class="w-full space-y-2">
      <span class="block text-xs text-muted-foreground">
        {{ $t('CAPTAIN.COPILOT.TRY_THESE_PROMPTS') }}
      </span>
      <div class="space-y-1.5">
        <button
          v-for="prompt in promptOptions"
          :key="prompt.label"
          type="button"
          class="flex w-full items-center justify-between rounded-lg border border-border/60 bg-accent px-3 py-2.5 text-sm font-medium text-foreground transition-colors hover:bg-accent/80"
          @click="handleSuggestion(prompt)"
        >
          <span>{{ t(prompt.label) }}</span>
          <span class="i-lucide-chevron-right size-4 text-muted-foreground" />
        </button>
      </div>
    </div>
  </div>
</template>
