<script setup>
import { computed } from 'vue';
import { RELAY_TABLE_HEAD_CLASS } from 'dashboard/components-next/relay/chrome/constants';

const props = defineProps({
  headers: {
    type: Array,
    default: () => [],
  },
  items: {
    type: Array,
    default: () => [],
  },
  noDataMessage: {
    type: String,
    default: '',
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const hasHeaderSlot = computed(() => !!props.headers.length);
const showHeaders = computed(
  () => hasHeaderSlot.value && props.items.length > 0
);
</script>

<template>
  <div class="w-full">
    <table class="min-w-full table-auto divide-y divide-border">
      <thead v-if="showHeaders" class="border-t border-border">
        <tr>
          <th
            v-for="(header, index) in headers"
            :key="index"
            class="py-4 text-start ltr:pr-4 rtl:pl-4"
            :class="RELAY_TABLE_HEAD_CLASS"
          >
            <slot :name="`header-${index}`" :header="header">
              {{ header }}
            </slot>
          </th>
        </tr>
      </thead>
      <tbody class="divide-y divide-border text-muted-foreground">
        <template v-if="items.length">
          <slot name="row" :items="items" />
        </template>
        <tr v-else-if="noDataMessage && !loading">
          <td
            :colspan="headers.length || 1"
            class="py-20 text-center text-body-main !text-base text-muted-foreground"
          >
            {{ noDataMessage }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
