<script setup>
import { ref, computed, watch, onMounted, nextTick, useSlots } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  conversationLabels: {
    type: Array,
    required: true,
  },
});

const slots = useSlots();
const accountLabels = useMapGetter('labels/getLabels');

const activeLabels = computed(() => {
  return accountLabels.value.filter(({ title }) =>
    props.conversationLabels.includes(title)
  );
});

const showAllLabels = ref(false);
const showExpandLabelButton = ref(false);
const labelPosition = ref(-1);
const labelContainer = ref(null);

const computeVisibleLabelPosition = () => {
  const beforeSlot = slots.before ? 100 : 0;
  if (!labelContainer.value) {
    return;
  }

  const labels = Array.from(
    labelContainer.value.querySelectorAll('[data-card-label]')
  );
  let labelOffset = 0;
  showExpandLabelButton.value = false;
  labels.forEach((label, index) => {
    labelOffset += label.offsetWidth + 8;

    if (labelOffset < labelContainer.value.clientWidth - beforeSlot) {
      labelPosition.value = index;
    } else {
      showExpandLabelButton.value = labels.length > 1;
    }
  });
};

watch(activeLabels, () => {
  nextTick(() => computeVisibleLabelPosition());
});

onMounted(() => {
  computeVisibleLabelPosition();
});

const onShowLabels = e => {
  e.stopPropagation();
  showAllLabels.value = !showAllLabels.value;
  nextTick(() => computeVisibleLabelPosition());
};
</script>

<template>
  <div ref="labelContainer" v-resize="computeVisibleLabelPosition">
    <div
      v-if="activeLabels.length || $slots.before"
      class="flex min-w-0 shrink items-end gap-2 gap-y-1"
      :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
    >
      <slot name="before" />
      <span
        v-for="(label, index) in activeLabels"
        :key="label ? label.id : index"
        data-card-label
        class="mb-0 inline-flex h-5 max-w-[calc(100%-0.5rem)] items-center gap-1 rounded-md border border-border px-1.5 text-[11px] font-medium text-muted-foreground"
        :class="{
          'invisible absolute': !showAllLabels && index > labelPosition,
        }"
        :title="label.description"
      >
        <span
          class="size-2 shrink-0 rounded-sm"
          :style="{ background: label.color }"
        />
        <span class="truncate">{{ label.title }}</span>
      </span>
      <button
        v-if="showExpandLabelButton"
        type="button"
        :title="
          showAllLabels
            ? $t('CONVERSATION.CARD.HIDE_LABELS')
            : $t('CONVERSATION.CARD.SHOW_LABELS')
        "
        class="ml-0 mr-6 flex h-5 shrink-0 items-center px-1 text-muted-foreground rtl:ml-6 rtl:mr-0 rtl:rotate-180"
        @click="onShowLabels"
      >
        <span
          class="size-3"
          :class="
            showAllLabels ? 'i-lucide-chevron-left' : 'i-lucide-chevron-right'
          "
        />
      </button>
    </div>
  </div>
</template>
