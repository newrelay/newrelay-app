<script setup>
import { computed } from 'vue';
import { messageStamp } from 'shared/helpers/timeHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelaySwitch } from 'dashboard/components-next/relay';

const props = defineProps({
  automation: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle', 'edit', 'delete', 'clone']);

const readableDate = date => messageStamp(new Date(date), 'LLL d, yyyy');
const readableDateWithTime = date =>
  messageStamp(new Date(date), 'LLL d, yyyy hh:mm a');

const automationActive = computed({
  get: () => props.automation.active,
  set: active => {
    const { id, name } = props.automation;
    emit('toggle', {
      id,
      name,
      status: !active,
    });
  },
});
</script>

<template>
  <div
    class="group grid grid-cols-[1.5fr_100px_1fr_120px] items-center px-6 py-4 transition-colors hover:bg-muted/20"
  >
    <div class="min-w-0 pr-4">
      <div class="truncate text-[14px] font-medium text-foreground">
        {{ automation.name }}
      </div>
      <div
        v-if="automation.description"
        class="mt-0.5 truncate text-[13px] text-muted-foreground"
      >
        {{ automation.description }}
      </div>
    </div>

    <div>
      <RelaySwitch v-model="automationActive" />
    </div>

    <div
      class="whitespace-nowrap text-[13.5px] text-muted-foreground"
      :title="readableDateWithTime(automation.created_on)"
    >
      {{ readableDate(automation.created_on) }}
    </div>

    <div
      class="flex items-center justify-end gap-2 opacity-0 transition-opacity group-hover:opacity-100"
    >
      <RelayButton
        v-tooltip.top="$t('AUTOMATION.FORM.EDIT')"
        variant="ghost"
        size="icon"
        class="size-8 text-muted-foreground hover:bg-muted hover:text-foreground"
        :disabled="loading"
        @click="$emit('edit', automation)"
      >
        <Icon icon="i-lucide-pencil" class="size-4" />
      </RelayButton>
      <RelayButton
        v-tooltip.top="$t('AUTOMATION.CLONE.TOOLTIP')"
        variant="ghost"
        size="icon"
        class="size-8 text-muted-foreground hover:bg-muted hover:text-foreground"
        :disabled="loading"
        @click="$emit('clone', automation)"
      >
        <Icon icon="i-lucide-copy" class="size-4" />
      </RelayButton>
      <RelayButton
        v-tooltip.top="$t('AUTOMATION.FORM.DELETE')"
        variant="ghost"
        size="icon"
        class="size-8 text-muted-foreground hover:bg-destructive/10 hover:text-destructive"
        :disabled="loading"
        @click="$emit('delete', automation)"
      >
        <Icon icon="i-lucide-trash-2" class="size-4" />
      </RelayButton>
    </div>
  </div>
</template>
