<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { RelayBadge } from 'dashboard/components-next/relay';
import { CHANNEL_NAME_BY_TYPE } from '../constants/channels';

const props = defineProps({
  open: { type: Boolean, default: false },
  activity: { type: Object, default: null },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();

const closePanel = () => emit('update:open', false);

const STATUS_BADGE_CLASS = {
  pending: 'bg-muted text-muted-foreground',
  public_replied: 'bg-blue-500/10 text-blue-600 dark:text-blue-400',
  dm_sent: 'bg-primary/10 text-primary',
  dm_failed: 'bg-destructive/10 text-destructive',
  engaged: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
};

const STATUS_RANK = {
  pending: 0,
  public_replied: 1,
  dm_sent: 2,
  dm_failed: 2,
  engaged: 3,
};

const statusLabel = status =>
  t(`AUTORESPONDER.ACTIVITY.STATUS_${status.toUpperCase()}`);

const reached = computed(() => {
  const rank = props.activity ? STATUS_RANK[props.activity.status] : -1;
  return {
    matched: rank >= 0,
    replied: rank >= 1,
    dm: rank >= 2,
    dmFailed: props.activity?.status === 'dm_failed',
    engaged: rank >= 3,
  };
});
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
              <span
                :class="getInboxIconByType(activity.inbox.channel_type)"
                class="size-5 text-foreground"
              />
              <span class="text-sm font-medium text-foreground">
                {{ CHANNEL_NAME_BY_TYPE[activity.inbox.channel_type] }}
              </span>
            </div>
            <RelayBadge
              variant="secondary"
              class="border-none font-medium px-2.5 py-0.5 rounded-md"
              :class="STATUS_BADGE_CLASS[activity.status]"
            >
              {{ statusLabel(activity.status) }}
            </RelayBadge>
          </div>
          <div class="text-[13px] text-muted-foreground">
            {{ dynamicTime(activity.sent_at || activity.created_at) }}
          </div>
        </div>
      </div>

      <div class="p-6 flex flex-col gap-6">
        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.CONTACT')
          }}</span>
          <div v-if="activity.contact" class="flex items-center gap-3 mt-1">
            <img
              :src="activity.contact.avatar_url"
              class="size-9 rounded-full object-cover bg-muted"
            />
            <span class="text-[13.5px] font-medium text-foreground">{{
              activity.contact.name
            }}</span>
          </div>
          <div v-else class="flex items-center gap-3 mt-1">
            <div
              class="size-9 rounded-full bg-muted flex items-center justify-center shrink-0"
            >
              <span class="i-lucide-user size-4 text-muted-foreground" />
            </div>
            <div class="flex flex-col">
              <span class="text-[13.5px] font-medium text-foreground">{{
                t('AUTORESPONDER.ACTIVITY.UNKNOWN_CONTACT')
              }}</span>
              <span class="text-[12.5px] text-muted-foreground">{{
                activity.commenter_id
              }}</span>
            </div>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.TRIGGER')
          }}</span>
          <div class="mt-1">
            <span class="text-[13.5px] text-muted-foreground">{{
              t('AUTORESPONDER.ACTIVITY.KEYWORD_LABEL', {
                keyword: activity.trigger.keyword,
              })
            }}</span>
          </div>
        </div>

        <hr class="border-border" />

        <div class="flex flex-col gap-2">
          <span class="text-[13px] font-medium text-foreground">{{
            t('AUTORESPONDER.ACTIVITY_DETAILS.AUTOMATION')
          }}</span>
          <div class="mt-1">
            <span class="text-[13.5px] font-medium text-foreground">{{
              activity.campaign.name
            }}</span>
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
                t('AUTORESPONDER.ACTIVITY.COMMENT_ID_LABEL')
              }}</span>
              <span class="text-[13px] font-medium text-foreground break-all">{{
                activity.comment_id
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
                <div
                  class="size-2 rounded-full"
                  :class="
                    reached.matched ? 'bg-primary' : 'bg-muted-foreground/30'
                  "
                />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_TRIGGER')
              }}</span>
            </div>

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-border flex items-center justify-center shadow-sm z-10"
              >
                <div
                  class="size-2 rounded-full"
                  :class="
                    reached.replied ? 'bg-primary' : 'bg-muted-foreground/30'
                  "
                />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_MATCHED')
              }}</span>
            </div>

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-border flex items-center justify-center shadow-sm z-10"
              >
                <span
                  v-if="reached.dmFailed"
                  class="i-lucide-alert-circle size-3 text-destructive"
                />
                <div
                  v-else
                  class="size-2 rounded-full"
                  :class="reached.dm ? 'bg-primary' : 'bg-muted-foreground/30'"
                />
              </div>
              <span class="text-[13px] text-foreground font-medium">{{
                reached.dmFailed
                  ? t('AUTORESPONDER.ACTIVITY_DETAILS.DELIVERY_FAILED')
                  : t('AUTORESPONDER.ACTIVITY_DETAILS.TIMELINE_SENT')
              }}</span>
            </div>

            <div class="relative flex items-center justify-between">
              <div
                class="absolute -left-6 size-[22px] rounded-full bg-background border border-primary/30 flex items-center justify-center shadow-sm z-10"
              >
                <span
                  class="size-3 text-primary"
                  :class="
                    reached.engaged
                      ? 'i-lucide-check-circle-2'
                      : 'i-lucide-circle'
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
