<script setup>
import { useI18n } from 'vue-i18n';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS } from '../constants/channels';

defineProps({
  open: { type: Boolean, default: false },
  template: { type: Object, default: null },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();

const closePanel = () => emit('update:open', false);
const previewVariables = ['{{first_name}}', '{{business_name}}'];
</script>

<template>
  <div
    v-if="open && template"
    class="w-full lg:w-[400px] shrink-0 bg-card border border-border shadow-sm rounded-xl flex flex-col sticky top-6"
  >
    <div class="flex-1 flex flex-col min-h-0 overflow-y-auto">
      <div
        class="px-6 py-5 border-b border-border flex items-center justify-between sticky top-0 bg-background/95 backdrop-blur z-10"
      >
        <h2 class="text-base font-semibold tracking-tight text-foreground">
          {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.TITLE') }}
        </h2>
        <button
          type="button"
          class="p-1.5 text-muted-foreground hover:bg-muted rounded-full transition-colors"
          @click="closePanel"
        >
          <span class="i-lucide-x size-4" />
        </button>
      </div>

      <div class="p-6 flex flex-col gap-6">
        <div
          class="border border-border/80 rounded-xl p-5 flex flex-col gap-5 bg-card shadow-sm"
        >
          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <h3 class="text-[15px] font-semibold text-foreground">
                {{ template.name }}
              </h3>
              <RelayBadge
                variant="secondary"
                class="bg-primary/10 text-primary border-none font-medium px-2 rounded-md"
              >
                {{
                  template.type === 'Message'
                    ? t('AUTORESPONDER.COMMON.TYPE_MESSAGE')
                    : t('AUTORESPONDER.COMMON.TYPE_COMMENT')
                }}
              </RelayBadge>
              <span
                v-if="template.favorite"
                class="i-lucide-star size-4 text-amber-400 fill-amber-400 ml-1"
              />
            </div>
            <p class="text-[13px] text-muted-foreground leading-relaxed">
              {{ template.description }}
            </p>
          </div>

          <div class="flex items-center gap-4">
            <div
              v-for="ch in template.channels"
              :key="ch"
              class="flex items-center gap-1.5"
            >
              <img :src="CHANNEL_LOGO_URLS[ch]" class="size-4 rounded-sm" />
              <span class="text-[13px] font-medium text-foreground">{{
                ch
              }}</span>
            </div>
          </div>

          <div class="flex flex-col gap-2.5">
            <div class="flex items-center gap-2 text-[13px]">
              <span class="i-lucide-history size-4 text-muted-foreground" />
              <span class="text-muted-foreground">
                {{
                  t('AUTORESPONDER.TEMPLATE_PREVIEW.USED_TIMES', {
                    count: template.usage,
                  })
                }}
              </span>
            </div>
            <div class="flex items-center gap-2 text-[13px]">
              <span class="i-lucide-clock size-4 text-muted-foreground" />
              <span class="text-muted-foreground">
                {{
                  t('AUTORESPONDER.TEMPLATE_PREVIEW.LAST_UPDATED', {
                    date: template.updated,
                  })
                }}
              </span>
            </div>
          </div>

          <div
            class="mt-2 border border-border rounded-lg p-4 bg-background shadow-sm relative"
          >
            <p
              class="text-[13.5px] leading-relaxed text-foreground whitespace-pre-wrap"
            >
              {{ template.description }}
            </p>
          </div>

          <div class="flex flex-col gap-2.5 mt-1">
            <span class="text-[12.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.VARIABLES_USED') }}
            </span>
            <div class="flex items-center gap-2 flex-wrap">
              <span
                v-for="variable in previewVariables"
                :key="variable"
                class="text-xs font-medium text-primary bg-primary/10 px-2 py-1 rounded-md"
                >{{ variable }}</span
              >
            </div>
          </div>
        </div>

        <div
          class="border border-border/80 rounded-xl p-5 flex flex-col gap-4 bg-card shadow-sm"
        >
          <h3 class="text-sm font-semibold text-foreground mb-1">
            {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.DETAILS_TITLE') }}
          </h3>

          <div class="flex items-center justify-between text-[13px]">
            <span class="text-muted-foreground">{{
              t('AUTORESPONDER.TEMPLATE_PREVIEW.TYPE')
            }}</span>
            <RelayBadge
              variant="secondary"
              class="bg-primary/10 text-primary border-none font-medium px-2 rounded-md"
            >
              {{
                template.type === 'Message'
                  ? t('AUTORESPONDER.COMMON.TYPE_MESSAGE')
                  : t('AUTORESPONDER.COMMON.TYPE_COMMENT')
              }}
            </RelayBadge>
          </div>

          <div class="flex items-center justify-between text-[13px]">
            <span class="text-muted-foreground">{{
              t('AUTORESPONDER.TEMPLATE_PREVIEW.CREATED_ON')
            }}</span>
            <span class="font-semibold text-foreground">{{
              template.updated
            }}</span>
          </div>

          <div class="flex items-center justify-between text-[13px]">
            <span class="text-muted-foreground">{{
              t('AUTORESPONDER.TEMPLATE_PREVIEW.CHANNELS')
            }}</span>
            <div class="flex items-center gap-1.5">
              <img
                v-for="ch in template.channels"
                :key="ch"
                :src="CHANNEL_LOGO_URLS[ch]"
                class="size-4 rounded-sm"
              />
            </div>
          </div>

          <RelayButton
            variant="outline"
            class="w-full mt-2 gap-2 text-primary border-primary/20 bg-primary/5 hover:bg-primary/10 shadow-sm"
          >
            <span class="i-lucide-zap size-4" />
            {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.USE_IN_AUTOMATION') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
