<script setup>
import { ref } from 'vue';
import RelaySidebar from './RelaySidebar.vue';

const collapsed = ref(false);
const activeHref = ref('/ai/faqs');

const sections = [
  {
    items: [
      {
        title: 'Customer Engagement',
        icon: 'i-lucide-message-circle',
        children: [
          { title: 'Inbox', href: '/inbox' },
          { title: 'Conversations', href: '/conversations' },
        ],
      },
      {
        title: 'Relay AI',
        icon: 'i-lucide-brain-circuit',
        children: [
          { title: 'FAQs', href: '/ai/faqs' },
          { title: 'Documents', href: '/ai/documents' },
          { title: 'Playground', href: '/ai/playground' },
        ],
      },
      {
        title: 'CRM & Sales',
        icon: 'i-lucide-users',
        children: [
          { title: 'Contacts', href: '/contacts' },
          { title: 'Companies', href: '/companies' },
        ],
      },
    ],
  },
  {
    label: 'Administration',
    items: [
      {
        title: 'Settings',
        icon: 'i-lucide-settings',
        href: '/admin/settings',
      },
    ],
  },
];

const onNavigate = href => {
  activeHref.value = href;
};
</script>

<template>
  <Story title="Relay/Sidebar" :layout="{ type: 'single', iframe: true }">
    <Variant title="Expanded">
      <div class="flex h-[520px] bg-n-background">
        <RelaySidebar
          v-model:collapsed="collapsed"
          brand-name="newrelay"
          :sections="sections"
          :active-href="activeHref"
          @navigate="onNavigate"
        />
        <div
          class="flex flex-1 items-center justify-center text-sm text-n-slate-11"
        >
          Active: {{ activeHref }}
        </div>
      </div>
    </Variant>

    <Variant title="Collapsed">
      <div class="flex h-[520px] bg-n-background">
        <RelaySidebar
          collapsed
          brand-name="newrelay"
          :sections="sections"
          :active-href="activeHref"
        />
      </div>
    </Variant>
  </Story>
</template>
