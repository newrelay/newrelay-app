<script setup>
import { useI18n } from 'vue-i18n';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS } from '../constants/channels';

defineProps({
  open: { type: Boolean, default: false },
  activity: { type: Object, default: null },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();

const closePanel = () => emit('update:open', false);
</script>

<template>
  <div
    v-if="open && activity"
    class="w-full lg:w-[420px] shrink-0 bg-card border border-border shadow-sm rounded-xl flex flex-col sticky top-6"
  >
    <div class="flex-1 flex flex-col min-h-0 overflow-y-auto">
      <div
        class="px-6 py-5 border-b border-border flex flex-col gap-4 sticky top-0 bg-background/95 backdrop-blur z-10"
      >
        <div class="flex items-center justify-between">
          <h2 class="text-[15px] font-semibold tracking-tight text-foreground">
            {{ t('AUTORESPONDER.ACTIVITY_DETAILS.TITLE') }}
          </h2>
          <button
            type="button"
            class="p-1.5 text-muted-foreground hover:bg-muted rounded-full transition-colors -mr-1.5"
            @click="closePanel"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </div>

        <div class="flex flex-col gap-3">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <img
                :src="CHANNEL_LOGO_URLS[activity.channel]"
                class="size-5 rounded-sm"
              />
              <span class="text-sm font-medium text-foreground">
                {{ activity.channel }} {{ activity.channelType }}
              </span>
            </div>
            <RelayBadge
              variant="secondary"
              class="bg-primary/10 text-primary border-none font-medium px-2.5 py-0.5 rounded-md"
            >
              {{ activity.status }}
            </RelayBadge>
          </div>
          <div class="text-[13px] text-muted-foreground">
            {{ activity.time.replace('\n', ' at ') }}
          </div>
        </div>
      </div>

      <div class="p-6 flex flex-col gap-6">
        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.CONTACT')
          }}</span>
          <div class="flex items-center justify-between mt-1">
            <div class="flex items-center gap-3">
              <img
                :src="activity.contact.avatar"
                class="size-9 rounded-full object-cover"
              />
              <div class="flex flex-col">
                <span class="text-[13.5px] font-medium text-foreground">{{
                  activity.contact.name
                }}</span>
                <span class="text-[12.5px] text-primary">{{
                  activity.contact.handle
                }}</span>
              </div>
            </div>
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 text-xs font-medium gap-1.5 text-primary border-primary/20 hover:bg-primary/10"
            >
              {{ t('AUTORESPONDER.ACTIVITY_DETAILS.VIEW_PROFILE') }}
              <span class="i-lucide-external-link size-3" />
            </RelayButton>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.TRIGGER')
          }}</span>
          <div class="flex items-start justify-between mt-1 gap-4">
            <div class="flex flex-col gap-1">
              <span class="text-[13.5px] font-medium text-foreground">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.COMMENT_ON_POST')
              }}</span>
              <span class="text-[13px] text-muted-foreground">{{
                `"${activity.actionSnippet}"`
              }}</span>
            </div>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.AUTOMATION')
          }}</span>
          <div class="flex items-center justify-between mt-1">
            <div class="flex items-center gap-2">
              <span class="text-[13.5px] font-medium text-foreground">{{
                activity.automation
              }}</span>
              <RelayBadge
                variant="secondary"
                class="bg-primary/10 text-primary border-none font-medium px-2 py-0.5 rounded text-[11px]"
              >
                {{ activity.automationType }}
              </RelayBadge>
            </div>
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 text-xs font-medium gap-1.5 text-primary border-primary/20 hover:bg-primary/10"
            >
              {{ t('AUTORESPONDER.ACTIVITY_DETAILS.VIEW_AUTOMATION') }}
              <span class="i-lucide-external-link size-3" />
            </RelayButton>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.ACTION_PERFORMED')
          }}</span>
          <div class="mt-1 flex flex-col gap-1.5">
            <span class="text-[13.5px] font-medium text-foreground">{{
              activity.action
            }}</span>
            <p class="text-[13px] text-muted-foreground leading-relaxed">
              {{ activity.actionSnippet }}
            </p>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.CHANNEL')
          }}</span>
          <div class="flex items-center gap-2 mt-1 cursor-pointer group w-fit">
            <img
              :src="CHANNEL_LOGO_URLS[activity.channel]"
              class="size-4 rounded-sm"
            />
            <span
              class="text-[13.5px] font-medium text-foreground group-hover:underline"
            >
              {{ activity.channel }}
            </span>
            <span
              class="i-lucide-external-link size-3 text-muted-foreground group-hover:text-foreground transition-colors"
            />
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.STATUS')
          }}</span>
          <div class="flex items-center gap-2 mt-1">
            <div
              class="size-5 rounded-full bg-primary/10 flex items-center justify-center"
            >
              <span
                class="size-3.5 text-primary"
                :class="
                  activity.status === 'Successful'
                    ? 'i-lucide-check-circle-2'
                    : 'i-lucide-alert-circle'
                "
              />
            </div>
            <span class="text-[13.5px] text-muted-foreground">
              {{
                activity.status === 'Successful'
                  ? t('AUTORESPONDER.ACTIVITY_DETAILS.DELIVERED_SUCCESS')
                  : t('AUTORESPONDER.ACTIVITY_DETAILS.DELIVERY_FAILED')
              }}
            </span>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.ADDITIONAL_INFO')
          }}</span>
          <div class="flex flex-col gap-3 mt-1">
            <div class="flex items-start">
              <span class="text-[13px] text-muted-foreground w-32 shrink-0">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.ACTIVITY_ID')
              }}</span>
              <span class="text-[13px] font-medium text-foreground break-all">{{
                activity.id
              }}</span>
            </div>
            <div class="flex items-start">
              <span class="text-[13px] text-muted-foreground w-32 shrink-0">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.RESPONSE_TIME')
              }}</span>
              <span class="text-[13px] font-medium text-foreground">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.RESPONSE_TIME_VALUE')
              }}</span>
            </div>
            <div class="flex items-start">
              <span class="text-[13px] text-muted-foreground w-32 shrink-0">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.DEVICE')
              }}</span>
              <span class="text-[13px] font-medium text-foreground">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.DEVICE_VALUE')
              }}</span>
            </div>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-4">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE')
          }}</span>

          <div class="relative pl-6 flex flex-col gap-6 mt-2">
            <div class="absolute left-[11px] top-2 bottom-2 w-px bg-border" />

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-border flex items-center justify-center shadow-sm z-10"
              >
                <div class="size-2 rounded-full bg-primary/40" />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_TRIGGER')
              }}</span>
            </div>

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-border flex items-center justify-center shadow-sm z-10"
              >
                <div class="size-2 rounded-full bg-primary/40" />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_MATCHED')
              }}</span>
            </div>

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-border flex items-center justify-center shadow-sm z-10"
              >
                <div class="size-2 rounded-full bg-primary/40" />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_SENT')
              }}</span>
            </div>

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-primary/30 flex items-center justify-center shadow-sm z-10"
              >
                <span
                  class="size-3 text-primary"
                  :class="
                    activity.status === 'Successful'
                      ? 'i-lucide-check-circle-2'
                      : 'i-lucide-alert-circle'
                  "
                />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_DELIVERED')
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
