<script setup>
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';

const props = defineProps({
  open: { type: Boolean, default: false },
  template: { type: Object, default: null },
});

const emit = defineEmits(['update:open', 'useInAutomation']);
const { t } = useI18n();

const closePanel = () => emit('update:open', false);
const useInAutomation = () => {
  emit('useInAutomation', props.template);
  closePanel();
};
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
                  template.template_type === 'message'
                    ? t('AUTORESPONDER.COMMON.TYPE_MESSAGE')
                    : t('AUTORESPONDER.COMMON.TYPE_COMMENT')
                }}
              </RelayBadge>
              <span
                v-if="template.favorite"
                class="i-lucide-star size-4 text-amber-400 fill-amber-400 ml-1"
              />
            </div>
          </div>

          <div class="flex flex-col gap-2.5">
            <div class="flex items-center gap-2 text-[13px]">
              <span class="i-lucide-history size-4 text-muted-foreground" />
              <span class="text-muted-foreground">
                {{
                  t('AUTORESPONDER.TEMPLATE_PREVIEW.USED_TIMES', {
                    count: template.usage_count,
                  })
                }}
              </span>
            </div>
            <div class="flex items-center gap-2 text-[13px]">
              <span class="i-lucide-clock size-4 text-muted-foreground" />
              <span class="text-muted-foreground">
                {{
                  t('AUTORESPONDER.TEMPLATE_PREVIEW.LAST_UPDATED', {
                    date: dynamicTime(template.updated_at),
                  })
                }}
              </span>
            </div>
          </div>

          <div class="flex flex-col gap-2">
            <span class="text-[12.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.PUBLIC_REPLIES') }}
            </span>
            <div
              v-for="(reply, idx) in template.public_replies"
              :key="idx"
              class="border border-border rounded-lg p-3 bg-background shadow-sm text-[13px] text-foreground whitespace-pre-wrap"
            >
              {{ reply }}
            </div>
          </div>

          <div class="flex flex-col gap-2">
            <span class="text-[12.5px] font-medium text-foreground">
              {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.DM_MESSAGE') }}
            </span>
            <div
              class="border border-border rounded-lg p-3 bg-background shadow-sm text-[13px] text-foreground whitespace-pre-wrap"
            >
              {{ template.dm_text_body }}
            </div>
          </div>
        </div>

        <RelayButton
          variant="outline"
          class="w-full gap-2 text-primary border-primary/20 bg-primary/5 hover:bg-primary/10 shadow-sm"
          @click="useInAutomation"
        >
          <span class="i-lucide-zap size-4" />
          {{ t('AUTORESPONDER.TEMPLATE_PREVIEW.USE_IN_AUTOMATION') }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
