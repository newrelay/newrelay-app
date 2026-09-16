<script>
import Avatar from 'next/avatar/Avatar.vue';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { mapGetters } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Avatar,
    Spinner,
    EmptyState,
    NextButton,
  },
  props: {
    notifications: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
    onClickNotification: {
      type: Function,
      default: () => {},
    },
    onMarkAllDoneClick: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      notificationMetadata: 'notifications/getMeta',
    }),
    showEmptyResult() {
      return !this.isLoading && this.notifications.length === 0;
    },
  },
  methods: {
    dynamicTime,
  },
};
</script>

<template>
  <section class="flex h-full flex-col overflow-hidden bg-background px-4 py-8">
    <div class="flex w-full items-center justify-between gap-2 mb-4">
      <h6 class="text-base font-medium tracking-tight text-foreground">
        {{ $t('NOTIFICATIONS_PAGE.HEADER') }}
      </h6>
      <NextButton
        v-if="notificationMetadata.unreadCount"
        type="submit"
        sm
        :label="$t('NOTIFICATIONS_PAGE.MARK_ALL_DONE')"
        :is-loading="isUpdating"
        @click="onMarkAllDoneClick"
      />
    </div>
    <table class="overflow-auto">
      <tbody v-show="!isLoading">
        <tr
          v-for="notificationItem in notifications"
          :key="notificationItem.id"
          :class="{
            'font-semibold': notificationItem.read_at === null,
          }"
          class="border-b border-border cursor-pointer hover:bg-muted last:border-b-0"
          @click="() => onClickNotification(notificationItem)"
        >
          <td class="p-2.5 text-foreground">
            <div
              class="overflow-hidden flex-col max-w-[31.25rem] whitespace-nowrap text-ellipsis"
            >
              <h5 class="text-sm m-0 text-foreground">
                {{
                  `#${
                    notificationItem.primary_actor
                      ? notificationItem.primary_actor.id
                      : $t(`NOTIFICATIONS_PAGE.DELETE_TITLE`)
                  }`
                }}
              </h5>
              <span
                class="overflow-hidden text-foreground whitespace-nowrap text-ellipsis"
              >
                {{ notificationItem.push_message_title }}
              </span>
            </div>
          </td>
          <td class="text-right">
            <span class="text-xs">
              {{
                $t(
                  `NOTIFICATIONS_PAGE.TYPE_LABEL.${notificationItem.notification_type}`
                )
              }}
            </span>
          </td>
          <td class="w-[3.25rem]">
            <Avatar
              v-if="notificationItem.primary_actor.meta.assignee"
              :src="notificationItem.primary_actor.meta.assignee.thumbnail"
              :size="28"
              :name="notificationItem.primary_actor.meta.assignee.name"
              rounded-full
            />
          </td>
          <td>
            <div class="text-right min-w-[9.125rem] ltr:mr-2 rtl:ml-2">
              <span class="text-muted-foreground text-xs">
                {{ dynamicTime(notificationItem.last_activity_at) }}
              </span>
            </div>
          </td>
          <td>
            <div
              v-if="!notificationItem.read_at"
              class="w-2.5 h-2.5 rounded-full bg-primary"
            />
          </td>
        </tr>
      </tbody>
    </table>
    <EmptyState
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.LIST.404')"
    />
    <div
      v-if="isLoading"
      class="text-base flex items-center justify-center p-10"
    >
      <Spinner />
      <span>{{ $t('NOTIFICATIONS_PAGE.LIST.LOADING_MESSAGE') }}</span>
    </div>
  </section>
</template>
