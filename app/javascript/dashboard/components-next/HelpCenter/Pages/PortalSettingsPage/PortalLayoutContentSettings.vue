<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';

import { RelayButton, RelayLabel } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

const PORTAL_LAYOUTS = {
  CLASSIC: 'classic',
  DOCUMENTATION: 'documentation',
};

// `prefix` is the link the help center auto-fills; the DB only stores the handle.
const SOCIAL_PLATFORMS = [
  {
    key: 'facebook',
    label: 'Facebook',
    icon: 'i-ri-facebook-circle-fill',
    prefix: 'facebook.com/',
  },
  { key: 'x', label: 'X', icon: 'i-ri-twitter-x-fill', prefix: 'x.com/' },
  {
    key: 'instagram',
    label: 'Instagram',
    icon: 'i-ri-instagram-fill',
    prefix: 'instagram.com/',
  },
  {
    key: 'linkedin',
    label: 'LinkedIn',
    icon: 'i-ri-linkedin-box-fill',
    prefix: 'linkedin.com/',
  },
  {
    key: 'youtube',
    label: 'YouTube',
    icon: 'i-ri-youtube-fill',
    prefix: 'youtube.com/',
  },
  {
    key: 'tiktok',
    label: 'TikTok',
    icon: 'i-ri-tiktok-fill',
    prefix: 'tiktok.com/',
  },
  {
    key: 'github',
    label: 'GitHub',
    icon: 'i-ri-github-fill',
    prefix: 'github.com/',
  },
  {
    key: 'whatsapp',
    label: 'WhatsApp',
    icon: 'i-ri-whatsapp-fill',
    prefix: 'wa.me/',
  },
];

const portalConfig = computed(() => props.activePortal?.config || {});

const state = reactive({
  layout: PORTAL_LAYOUTS.CLASSIC,
  socialProfiles: {},
  widgetColor: '',
  liveChatWidgetInboxId: '',
});
const visiblePlatforms = ref([]);
const showAddMenu = ref(false);

const liveChatWidgets = computed(() => {
  const inboxes = store.getters['inboxes/getInboxes'];
  const widgetOptions = inboxes
    .filter(inbox => inbox.channel_type === 'Channel::WebWidget')
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }));

  return [
    {
      value: '',
      label: t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.NONE_OPTION'),
    },
    ...widgetOptions,
  ];
});

const platformByKey = key => SOCIAL_PLATFORMS.find(p => p.key === key);

const trimmedHandle = key => (state.socialProfiles[key] || '').trim();

const buildSocialProfiles = () =>
  visiblePlatforms.value.reduce((acc, key) => {
    const handle = trimmedHandle(key);
    if (handle) acc[key] = handle;
    return acc;
  }, {});

const resetFromPortal = () => {
  const savedProfiles = portalConfig.value.social_profiles || {};
  state.layout = portalConfig.value.layout || PORTAL_LAYOUTS.CLASSIC;
  state.widgetColor = props.activePortal?.color || '';
  state.liveChatWidgetInboxId = props.activePortal?.inbox?.id || '';
  state.socialProfiles = SOCIAL_PLATFORMS.reduce((acc, { key }) => {
    acc[key] = savedProfiles[key] || '';
    return acc;
  }, {});
  visiblePlatforms.value = SOCIAL_PLATFORMS.map(p => p.key).filter(key =>
    (savedProfiles[key] || '').trim()
  );
};

watch(() => props.activePortal, resetFromPortal, {
  immediate: true,
  deep: true,
});

const visiblePlatformDetails = computed(() =>
  visiblePlatforms.value.map(platformByKey)
);

const addablePlatforms = computed(() =>
  SOCIAL_PLATFORMS.filter(p => !visiblePlatforms.value.includes(p.key)).map(
    p => ({ label: p.label, value: p.key, action: p.key, icon: p.icon })
  )
);

const addPlatform = ({ value }) => {
  if (!visiblePlatforms.value.includes(value)) {
    visiblePlatforms.value.push(value);
  }
  showAddMenu.value = false;
};

const removePlatform = key => {
  visiblePlatforms.value = visiblePlatforms.value.filter(k => k !== key);
  state.socialProfiles[key] = '';
};

const getPayload = () => ({
  id: props.activePortal.id,
  slug: props.activePortal.slug,
  color: state.widgetColor,
  inbox_id: state.liveChatWidgetInboxId,
  config: {
    layout: state.layout,
    social_profiles: buildSocialProfiles(),
  },
});

defineExpose({
  getPayload,
});
</script>

<template>
  <div
    class="flex w-full flex-col gap-6 rounded-2xl border border-border/40 bg-card p-6 shadow-sm"
  >
    <h2 class="flex items-center gap-2 text-base font-medium text-foreground">
      <span
        class="i-lucide-paintbrush size-4 text-primary"
        aria-hidden="true"
      />
      {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SECTION_EXPERIENCE') }}
    </h2>

    <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px]">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.LABEL') }}
        </RelayLabel>
        <ComboBox
          v-model="state.liveChatWidgetInboxId"
          :options="liveChatWidgets"
          :placeholder="
            t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.PLACEHOLDER')
          "
        />
        <p class="mt-1 text-[12px] text-muted-foreground">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.LIVE_CHAT_WIDGET.HELP_TEXT') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px]">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.BRAND_COLOR.LABEL') }}
        </RelayLabel>
        <div class="flex items-center gap-3">
          <label
            class="relative cursor-pointer transition-transform hover:scale-105"
          >
            <input v-model="state.widgetColor" type="color" class="sr-only" />
            <span
              class="block size-10 rounded-full border-2 border-background shadow-sm ring-1 ring-border/50"
              :style="{ backgroundColor: state.widgetColor || '#2781F6' }"
            />
          </label>
          <div
            class="flex h-10 items-center rounded-md border border-border/80 bg-muted/30 px-3 text-[14px] font-medium uppercase shadow-sm"
          >
            {{ state.widgetColor || '—' }}
          </div>
        </div>
      </div>
    </div>

    <div class="space-y-4 border-t border-border/40 pt-6">
      <div class="space-y-1">
        <h3 class="text-[14px] font-semibold text-foreground">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.HEADER') }}
        </h3>
        <p class="text-[13px] text-muted-foreground">
          {{ t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.DESCRIPTION') }}
        </p>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <button
          type="button"
          class="relative flex cursor-pointer flex-col rounded-xl border-2 p-4 text-left transition-all"
          :class="
            state.layout === PORTAL_LAYOUTS.CLASSIC
              ? 'border-primary bg-primary/5'
              : 'border-border/60 bg-card hover:border-border'
          "
          @click="state.layout = PORTAL_LAYOUTS.CLASSIC"
        >
          <div class="mb-2 flex items-center justify-between">
            <span class="text-[14px] font-medium text-foreground">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.CLASSIC.TITLE'
                )
              }}
            </span>
            <span
              class="flex size-4 items-center justify-center rounded-full border"
              :class="
                state.layout === PORTAL_LAYOUTS.CLASSIC
                  ? 'border-primary'
                  : 'border-border'
              "
            >
              <span
                v-if="state.layout === PORTAL_LAYOUTS.CLASSIC"
                class="size-2 rounded-full bg-primary"
              />
            </span>
          </div>
          <p class="mb-4 h-8 text-[12px] text-muted-foreground">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.CLASSIC.DESCRIPTION'
              )
            }}
          </p>
          <div
            class="flex-1 space-y-2.5 rounded-lg border border-border/40 bg-background p-2.5"
          >
            <div
              class="flex h-8 w-full items-center justify-center rounded bg-muted"
            >
              <div class="h-2 w-1/2 rounded-full bg-border" />
            </div>
            <div class="grid grid-cols-2 gap-2">
              <div class="h-6 rounded bg-muted" />
              <div class="h-6 rounded bg-muted" />
              <div class="h-6 rounded bg-muted" />
              <div class="h-6 rounded bg-muted" />
            </div>
          </div>
        </button>

        <button
          type="button"
          class="relative flex cursor-pointer flex-col rounded-xl border-2 p-4 text-left transition-all"
          :class="
            state.layout === PORTAL_LAYOUTS.DOCUMENTATION
              ? 'border-primary bg-primary/5'
              : 'border-border/60 bg-card hover:border-border'
          "
          @click="state.layout = PORTAL_LAYOUTS.DOCUMENTATION"
        >
          <div class="mb-2 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="text-[14px] font-medium text-foreground">
                {{
                  t(
                    'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.SIDEBAR.TITLE'
                  )
                }}
              </span>
              <span
                class="rounded bg-primary/10 px-1.5 py-0.5 text-[10px] font-medium text-primary"
              >
                {{ t('GENERAL.BETA') }}
              </span>
            </div>
            <span
              class="flex size-4 items-center justify-center rounded-full border"
              :class="
                state.layout === PORTAL_LAYOUTS.DOCUMENTATION
                  ? 'border-primary'
                  : 'border-border'
              "
            >
              <span
                v-if="state.layout === PORTAL_LAYOUTS.DOCUMENTATION"
                class="size-2 rounded-full bg-primary"
              />
            </span>
          </div>
          <p class="mb-4 h-8 text-[12px] text-muted-foreground">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.LAYOUT.SIDEBAR.DESCRIPTION'
              )
            }}
          </p>
          <div
            class="flex flex-1 gap-2 rounded-lg border border-border/40 bg-background p-2"
          >
            <div class="flex w-1/3 flex-col gap-1.5 rounded bg-muted p-1.5">
              <div class="h-1.5 w-full rounded-full bg-border/60" />
              <div class="h-1.5 w-3/4 rounded-full bg-border/60" />
              <div class="h-1.5 w-5/6 rounded-full bg-border/60" />
            </div>
            <div class="flex-1 space-y-1.5 rounded bg-muted/30 p-1.5">
              <div class="mb-3 h-2 w-1/2 rounded-full bg-border/80" />
              <div class="h-10 w-full rounded bg-muted" />
              <div class="h-10 w-full rounded bg-muted" />
            </div>
          </div>
        </button>
      </div>

      <div
        v-if="state.layout === PORTAL_LAYOUTS.DOCUMENTATION"
        class="mt-2 space-y-4 border-t border-border/40 pt-6"
      >
        <div class="space-y-1">
          <h3 class="text-[14px] font-semibold text-foreground">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.HEADER'
              )
            }}
          </h3>
          <p class="text-[13px] text-muted-foreground">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.DESCRIPTION'
              )
            }}
          </p>
        </div>

        <div class="max-w-md space-y-3">
          <div
            v-for="platform in visiblePlatformDetails"
            :key="platform.key"
            class="flex items-center gap-2 rounded-lg border border-border/80 bg-background px-3 py-1.5 shadow-sm focus-within:ring-1 focus-within:ring-primary/30"
          >
            <Icon
              :icon="platform.icon"
              class="size-4 shrink-0 text-foreground opacity-80"
            />
            <span
              class="shrink-0 select-none text-[13.5px] text-muted-foreground"
            >
              {{ platform.prefix }}
            </span>
            <input
              v-model="state.socialProfiles[platform.key]"
              type="text"
              class="min-w-0 flex-1 bg-transparent text-[14px] text-foreground outline-none placeholder:text-muted-foreground/50"
              :placeholder="
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.PLACEHOLDER'
                )
              "
            />
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-7 shrink-0 text-muted-foreground"
              :aria-label="
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.REMOVE'
                )
              "
              @click="removePlatform(platform.key)"
            >
              <span class="i-lucide-x size-3.5 opacity-60" />
            </RelayButton>
          </div>
        </div>

        <div
          v-if="addablePlatforms.length"
          v-on-clickaway="() => (showAddMenu = false)"
          class="relative pt-1"
        >
          <RelayButton
            variant="outline"
            size="sm"
            class="h-8"
            @click="showAddMenu = !showAddMenu"
          >
            <span class="i-lucide-plus size-3.5 opacity-70" />
            {{
              t('HELP_CENTER.PORTAL_SETTINGS.LAYOUT_CONTENT.SOCIAL_LINKS.ADD')
            }}
          </RelayButton>
          <DropdownMenu
            v-if="showAddMenu"
            :menu-items="addablePlatforms"
            class="top-full mt-1 w-52 ltr:left-0 rtl:right-0"
            @action="addPlatform"
          />
        </div>
      </div>
    </div>
  </div>
</template>
