<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const store = useStore();
const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const uiFlags = computed(() => store.getters['notifications/getUIFlags']);

const connectChannel = () => {
  router.push(accountScopedRoute('settings_inbox_list'));
};

const learnMore = () => {
  window.open('https://chatwoot.com/docs', '_blank');
};

const exploreDemo = () => {
  window.open('https://chatwoot.com/docs', '_blank');
};
</script>

<template>
  <div
    class="flex-1 flex flex-col items-center justify-center p-8 bg-background text-foreground animate-in fade-in duration-300 overflow-y-auto w-full h-full min-h-0"
  >
    <div v-if="uiFlags.isFetching" class="flex justify-center my-4">
      <Spinner class="text-primary" />
    </div>

    <div v-else class="flex flex-col items-center w-full max-w-4xl">
      <!-- Hero Section -->
      <div class="flex flex-col items-center text-center mb-10 max-w-lg">
        <div
          class="size-20 rounded-full bg-primary/5 flex items-center justify-center mb-6 relative"
        >
          <div
            class="absolute inset-2 rounded-full border border-primary/10 bg-background flex items-center justify-center"
          >
            <span class="i-lucide-inbox size-8 text-primary" />
          </div>
        </div>
        <h2 class="text-xl font-semibold text-foreground mb-2 tracking-tight">
          {{ t('INBOX.EMPTY.TITLE') }}
        </h2>
        <p class="text-sm text-muted-foreground leading-relaxed">
          {{ t('INBOX.EMPTY.DESCRIPTION') }}
        </p>
      </div>

      <!-- Action Buttons -->
      <div
        class="flex flex-col sm:flex-row items-center gap-4 mb-16 justify-center w-full"
      >
        <RelayButton
          class="h-10 px-6 text-sm font-medium min-w-[160px]"
          @click="connectChannel"
        >
          {{ t('INBOX.EMPTY.CONNECT_CHANNEL') }}
        </RelayButton>
        <RelayButton
          variant="outline"
          class="h-10 px-6 text-sm font-medium min-w-[160px] gap-1"
          @click="learnMore"
        >
          {{ t('INBOX.EMPTY.LEARN_MORE') }}
          <span class="i-lucide-external-link size-3.5 opacity-70" />
        </RelayButton>
      </div>

      <!-- Supported Channels -->
      <div class="w-full max-w-3xl flex flex-col items-center">
        <div class="w-full flex items-center mb-8 gap-4">
          <div class="h-px bg-border flex-1" />
          <span
            class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider"
          >
            {{ t('INBOX.EMPTY.SUPPORTED_CHANNELS') }}
          </span>
          <div class="h-px bg-border flex-1" />
        </div>

        <!-- Channel Icons -->
        <div class="flex items-center justify-center gap-6 sm:gap-10 flex-wrap">
          <!-- WhatsApp -->
          <div class="flex flex-col items-center gap-2 cursor-default">
            <div
              class="size-12 rounded-xl border border-border/60 bg-card flex items-center justify-center shadow-xs"
            >
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg"
                alt="WhatsApp"
                class="size-6 opacity-90 dark:opacity-80"
              />
            </div>
            <span class="text-xs font-normal text-muted-foreground">
              {{ t('INBOX.EMPTY.WHATSAPP') }}
            </span>
          </div>

          <!-- Email -->
          <div class="flex flex-col items-center gap-2 cursor-default">
            <div
              class="size-12 rounded-xl border border-border/60 bg-card flex items-center justify-center shadow-xs"
            >
              <span class="i-lucide-mail size-6 text-[#007BFF] opacity-90" />
            </div>
            <span class="text-xs font-normal text-muted-foreground">
              {{ t('INBOX.EMPTY.EMAIL') }}
            </span>
          </div>

          <!-- SMS -->
          <div class="flex flex-col items-center gap-2 cursor-default">
            <div
              class="size-12 rounded-xl border border-border/60 bg-card flex items-center justify-center shadow-xs"
            >
              <span
                class="i-lucide-message-square size-6 text-emerald-500 opacity-90"
              />
            </div>
            <span class="text-xs font-normal text-muted-foreground">
              {{ t('INBOX.EMPTY.SMS') }}
            </span>
          </div>

          <!-- Messenger -->
          <div class="flex flex-col items-center gap-2 cursor-default">
            <div
              class="size-12 rounded-xl border border-border/60 bg-card flex items-center justify-center shadow-xs"
            >
              <span
                class="i-lucide-message-circle size-6 text-[#0084FF] opacity-90"
              />
            </div>
            <span class="text-xs font-normal text-muted-foreground">
              {{ t('INBOX.EMPTY.MESSENGER') }}
            </span>
          </div>

          <!-- Instagram -->
          <div class="flex flex-col items-center gap-2 cursor-default">
            <div
              class="size-12 rounded-xl border border-border/60 bg-card flex items-center justify-center shadow-xs"
            >
              <span
                class="i-lucide-instagram size-6 text-[#E1306C] opacity-90"
              />
            </div>
            <span class="text-xs font-normal text-muted-foreground">
              {{ t('INBOX.EMPTY.INSTAGRAM') }}
            </span>
          </div>

          <!-- Live Chat -->
          <div class="flex flex-col items-center gap-2 cursor-default">
            <div
              class="size-12 rounded-xl border border-border/60 bg-card flex items-center justify-center shadow-xs"
            >
              <span
                class="i-lucide-message-square size-6 text-indigo-500 opacity-90"
              />
            </div>
            <span class="text-xs font-normal text-muted-foreground">
              {{ t('INBOX.EMPTY.LIVE_CHAT') }}
            </span>
          </div>
        </div>

        <!-- Footer Demo Workspace -->
        <div
          class="mt-12 flex flex-col sm:flex-row items-center gap-6 justify-center"
        >
          <a
            href="https://chatwoot.com/docs"
            target="_blank"
            rel="noopener noreferrer"
            class="text-xs text-muted-foreground hover:text-primary flex items-center gap-1.5 transition-colors"
          >
            <span class="i-lucide-help-circle size-4" />
            {{ t('INBOX.EMPTY.LEARN_HOW_WORKS') }}
          </a>
          <RelayButton
            variant="outline"
            size="sm"
            class="h-8 text-xs gap-1.5"
            @click="exploreDemo"
          >
            {{ t('INBOX.EMPTY.EXPLORE_DEMO') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
