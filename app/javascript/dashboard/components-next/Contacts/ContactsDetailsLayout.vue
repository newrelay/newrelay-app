<script setup>
import { computed, useSlots, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: () => ({}),
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['goToContactsList', 'toggleBlock']);

const { t } = useI18n();
const slots = useSlots();
const route = useRoute();

const isContactSidebarOpen = ref(false);

const contactId = computed(() => route.params.contactId);

const selectedContactName = computed(() => {
  return props.selectedContact?.name;
});

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('CONTACTS_LAYOUT.HEADER.BREADCRUMB.CONTACTS'),
      link: '#',
    },
  ];
  if (props.selectedContact) {
    items.push({
      label: selectedContactName.value,
    });
  }
  return items;
});

const isContactBlocked = computed(() => {
  return props.selectedContact?.blocked;
});

const handleBreadcrumbClick = () => {
  emit('goToContactsList');
};

const toggleBlock = () => {
  emit('toggleBlock', isContactBlocked.value);
};

const handleConversationSidebarToggle = () => {
  isContactSidebarOpen.value = !isContactSidebarOpen.value;
};

const closeMobileSidebar = () => {
  if (!isContactSidebarOpen.value) return;
  isContactSidebarOpen.value = false;
};
</script>

<template>
  <section
    class="flex h-full w-full justify-evenly overflow-hidden bg-background"
  >
    <div
      class="flex h-full w-full flex-col transition-all duration-300 ltr:2xl:ml-56 rtl:2xl:mr-56"
    >
      <header
        class="sticky top-0 z-10 border-b border-border/40 bg-background px-6 3xl:px-0"
      >
        <div class="mx-auto w-full max-w-[40.625rem]">
          <div
            class="flex w-full flex-col items-start justify-between gap-2 py-5 xs:flex-row xs:items-center"
          >
            <Breadcrumb
              :items="breadcrumbItems"
              @click="handleBreadcrumbClick"
            />
            <div class="flex items-center gap-2">
              <Button
                :label="
                  !isContactBlocked
                    ? $t('CONTACTS_LAYOUT.HEADER.BLOCK_CONTACT')
                    : $t('CONTACTS_LAYOUT.HEADER.UNBLOCK_CONTACT')
                "
                size="sm"
                slate
                :is-loading="isUpdating"
                :disabled="isUpdating"
                @click="toggleBlock"
              />
              <VoiceCallButton
                :phone="selectedContact?.phoneNumber"
                :contact-id="contactId"
                :label="$t('CONTACT_PANEL.CALL')"
                size="sm"
              />
              <ComposeConversation :contact-id="contactId">
                <template #trigger>
                  <Button
                    :label="$t('CONTACTS_LAYOUT.HEADER.SEND_MESSAGE')"
                    size="sm"
                  />
                </template>
              </ComposeConversation>
            </div>
          </div>
        </div>
      </header>
      <main class="flex-1 overflow-y-auto bg-muted/10 px-6 3xl:px-px">
        <div class="mx-auto w-full max-w-[40.625rem] py-4">
          <slot name="default" />
        </div>
      </main>
    </div>

    <!-- Desktop sidebar -->
    <div
      v-if="slots.sidebar"
      class="hidden max-w-md min-w-52 w-full justify-end overflow-y-auto border-l border-border/40 bg-card py-6 lg:block"
    >
      <slot name="sidebar" />
    </div>

    <!-- Mobile sidebar container -->
    <div
      v-if="slots.sidebar"
      class="fixed top-0 z-50 flex h-full justify-end transition-all duration-200 ease-in-out ltr:right-0 rtl:left-0 lg:hidden"
      :class="isContactSidebarOpen ? 'w-full' : 'w-16'"
    >
      <div
        v-on-click-outside="[
          closeMobileSidebar,
          { ignore: ['#contact-sidebar-content'] },
        ]"
        class="relative order-1 top-28 flex h-fit w-fit items-start border border-border bg-card p-1 transition-all duration-500 ease-in-out xs:top-24"
        :class="[
          isContactSidebarOpen
            ? 'justify-end ltr:rounded-l-full rtl:rounded-r-full ltr:rounded-r-none rtl:rounded-l-none'
            : 'justify-center rounded-full ltr:mr-6 rtl:ml-6',
        ]"
      >
        <Button
          ghost
          slate
          sm
          class="!rounded-full rtl:rotate-180"
          :class="{ 'bg-accent': isContactSidebarOpen }"
          :icon="
            isContactSidebarOpen
              ? 'i-lucide-panel-right-close'
              : 'i-lucide-panel-right-open'
          "
          data-contact-sidebar-toggle
          @click="handleConversationSidebarToggle"
        />
      </div>

      <Transition
        enter-active-class="transition-transform duration-200 ease-in-out"
        leave-active-class="transition-transform duration-200 ease-in-out"
        enter-from-class="ltr:translate-x-full rtl:-translate-x-full"
        enter-to-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-from-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-to-class="ltr:translate-x-full rtl:-translate-x-full"
      >
        <div
          v-if="isContactSidebarOpen"
          id="contact-sidebar-content"
          class="order-2 w-[85%] overflow-y-auto border-border/40 bg-card py-6 shadow-lg sm:w-[50%] ltr:border-l rtl:border-r"
        >
          <slot name="sidebar" />
        </div>
      </Transition>
    </div>
  </section>
</template>
