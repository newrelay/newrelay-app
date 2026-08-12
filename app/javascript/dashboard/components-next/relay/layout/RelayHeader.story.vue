<script setup>
import { ref } from 'vue';
import RelayHeader from './RelayHeader.vue';
import RelaySidebar from './RelaySidebar.vue';
import Badge from '../badge/Badge.vue';

const collapsed = ref(false);
const lastAction = ref('—');

const sections = [
  {
    items: [
      {
        title: 'Relay AI',
        icon: 'i-lucide-brain-circuit',
        children: [
          { title: 'FAQs', href: '/ai/faqs' },
          { title: 'Documents', href: '/ai/documents' },
        ],
      },
    ],
  },
];
</script>

<template>
  <Story title="Relay/Header" :layout="{ type: 'single', iframe: true }">
    <Variant title="Default">
      <div class="bg-n-background">
        <RelayHeader
          title="Relay AI"
          @toggle-sidebar="
            collapsed = !collapsed;
            lastAction = 'toggleSidebar';
          "
          @open-search="lastAction = 'openSearch'"
        >
          <template #actions>
            <Badge variant="secondary">Beta</Badge>
          </template>
        </RelayHeader>
        <p class="p-4 text-sm text-n-slate-11">Last action: {{ lastAction }}</p>
      </div>
    </Variant>

    <Variant title="With sidebar shell">
      <div class="flex h-[480px] flex-col bg-n-background">
        <RelayHeader title="FAQs" @toggle-sidebar="collapsed = !collapsed" />
        <div class="flex min-h-0 flex-1">
          <RelaySidebar
            v-model:collapsed="collapsed"
            brand-name="newrelay"
            :sections="sections"
            active-href="/ai/faqs"
          />
          <div
            class="flex flex-1 items-center justify-center text-sm text-n-slate-11"
          >
            Page content
          </div>
        </div>
      </div>
    </Variant>
  </Story>
</template>
