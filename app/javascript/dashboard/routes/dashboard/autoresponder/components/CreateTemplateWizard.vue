<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  RelayButton,
  RelayInput,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import { CHANNEL_LOGO_URLS } from '../constants/channels';

defineProps({
  open: { type: Boolean, default: false },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();

const closeWizard = () => emit('update:open', false);

const templateType = ref('message');
const activePreviewTab = ref('Instagram DM');
const selectedCategory = ref('');
const selectedLanguage = ref('English (US)');

const categoryOptions = ['Welcome Messages', 'Pricing', 'Support'];
const languageOptions = ['English (US)', 'Spanish', 'French'];

const variables = [
  '{{first_name}}',
  '{{last_name}}',
  '{{business_name}}',
  '{{account_name}}',
  '{{custom_field}}',
];
const firstNameVar = '{{first_name}}';

const previewTabs = computed(() => [
  {
    id: 'Instagram DM',
    logo: CHANNEL_LOGO_URLS.Instagram,
    activeClass: 'border-fuchsia-600 text-fuchsia-600',
  },
  {
    id: 'WhatsApp',
    logo: CHANNEL_LOGO_URLS.WhatsApp,
    activeClass: 'border-emerald-600 text-emerald-600',
  },
  {
    id: 'Facebook Comment',
    logo: CHANNEL_LOGO_URLS.Facebook,
    activeClass: 'border-blue-600 text-blue-600',
  },
]);
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-[120] bg-background flex flex-col h-screen overflow-hidden"
    >
      <div
        class="h-[88px] border-b border-border flex items-center justify-center relative shrink-0"
      >
        <h2 class="text-base font-semibold text-foreground">
          {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.TITLE') }}
        </h2>
        <button
          type="button"
          class="absolute right-6 top-1/2 -translate-y-1/2 text-muted-foreground hover:bg-muted p-2 rounded-full transition-colors"
          @click="closeWizard"
        >
          <span class="i-lucide-x size-5" />
        </button>
      </div>

      <div class="flex-1 flex overflow-hidden">
        <div class="flex-1 flex flex-col min-h-0">
          <div class="flex-1 overflow-y-auto px-12 lg:px-20 py-10">
            <div class="w-full">
              <div class="mb-8">
                <h1
                  class="text-xl font-semibold tracking-tight text-foreground"
                >
                  {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.HEADING') }}
                </h1>
                <p class="text-sm text-muted-foreground mt-1">
                  {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.SUBHEADING') }}
                </p>
              </div>

              <div class="flex flex-col gap-8">
                <div class="flex flex-col gap-3">
                  <span class="text-[13.5px] font-medium text-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.TEMPLATE_TYPE')
                    }}
                  </span>
                  <div class="grid grid-cols-2 gap-4">
                    <div
                      class="relative border rounded-xl p-5 cursor-pointer transition-all duration-200"
                      :class="
                        templateType === 'message'
                          ? 'border-primary bg-primary/5 shadow-sm'
                          : 'border-border hover:border-border/80'
                      "
                      @click="templateType = 'message'"
                    >
                      <div class="flex items-start gap-4">
                        <div
                          class="size-10 rounded-lg bg-primary/10 flex items-center justify-center shrink-0"
                        >
                          <span
                            class="i-lucide-message-square size-5 text-primary"
                          />
                        </div>
                        <div class="flex flex-col gap-1">
                          <span class="text-sm font-semibold text-foreground">
                            {{
                              t(
                                'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.MESSAGE_TEMPLATE'
                              )
                            }}
                          </span>
                          <span
                            class="text-[13px] text-muted-foreground leading-snug"
                          >
                            {{
                              t(
                                'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.MESSAGE_TEMPLATE_DESC'
                              )
                            }}
                          </span>
                        </div>
                      </div>
                      <div
                        v-if="templateType === 'message'"
                        class="absolute top-4 right-4 size-5 rounded-full bg-primary flex items-center justify-center"
                      >
                        <span
                          class="i-lucide-check size-3 text-primary-foreground"
                        />
                      </div>
                      <div
                        v-else
                        class="absolute top-4 right-4 size-5 rounded-full border border-border"
                      />
                    </div>

                    <div
                      class="relative border rounded-xl p-5 cursor-pointer transition-all duration-200"
                      :class="
                        templateType === 'comment'
                          ? 'border-primary bg-primary/5 shadow-sm'
                          : 'border-border hover:border-border/80'
                      "
                      @click="templateType = 'comment'"
                    >
                      <div class="flex items-start gap-4">
                        <div
                          class="size-10 rounded-lg bg-amber-500/10 flex items-center justify-center shrink-0"
                        >
                          <span
                            class="i-lucide-message-circle size-5 text-amber-500"
                          />
                        </div>
                        <div class="flex flex-col gap-1">
                          <span class="text-sm font-semibold text-foreground">
                            {{
                              t(
                                'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.COMMENT_TEMPLATE'
                              )
                            }}
                          </span>
                          <span
                            class="text-[13px] text-muted-foreground leading-snug"
                          >
                            {{
                              t(
                                'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.COMMENT_TEMPLATE_DESC'
                              )
                            }}
                          </span>
                        </div>
                      </div>
                      <div
                        v-if="templateType === 'comment'"
                        class="absolute top-4 right-4 size-5 rounded-full bg-primary flex items-center justify-center"
                      >
                        <span
                          class="i-lucide-check size-3 text-primary-foreground"
                        />
                      </div>
                      <div
                        v-else
                        class="absolute top-4 right-4 size-5 rounded-full border border-border"
                      />
                    </div>
                  </div>
                </div>

                <div class="flex flex-col gap-2">
                  <label class="text-[13.5px] font-medium text-foreground">
                    {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_LABEL') }}
                  </label>
                  <RelayInput
                    :placeholder="
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_PLACEHOLDER')
                    "
                    class-name="h-10 text-sm"
                  />
                  <span class="text-xs text-muted-foreground">
                    {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.NAME_HELPER') }}
                  </span>
                </div>

                <div class="flex flex-col gap-2">
                  <label class="text-[13.5px] font-medium text-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.DESCRIPTION_LABEL'
                      )
                    }}
                    <span class="text-muted-foreground font-normal">{{
                      t('AUTORESPONDER.COMMON.OPTIONAL')
                    }}</span>
                  </label>
                  <textarea
                    class="min-h-[100px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                    :placeholder="
                      t(
                        'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.DESCRIPTION_PLACEHOLDER'
                      )
                    "
                  />
                  <span class="text-xs text-muted-foreground">
                    {{
                      t(
                        'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.DESCRIPTION_HELPER'
                      )
                    }}
                  </span>
                </div>

                <div class="flex flex-col gap-2">
                  <label class="text-[13.5px] font-medium text-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.CATEGORY_LABEL')
                    }}
                    <span class="text-muted-foreground font-normal">{{
                      t('AUTORESPONDER.COMMON.OPTIONAL')
                    }}</span>
                  </label>
                  <RelayDropdownMenu>
                    <RelayDropdownMenuTrigger as-child>
                      <button
                        type="button"
                        class="w-full h-10 rounded-md border border-input bg-transparent px-3 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 text-left flex items-center justify-between transition-colors hover:bg-muted/50"
                      >
                        <span
                          :class="{
                            'text-muted-foreground': !selectedCategory,
                          }"
                        >
                          {{
                            selectedCategory ||
                            t(
                              'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.CATEGORY_PLACEHOLDER'
                            )
                          }}
                        </span>
                        <span
                          class="i-lucide-chevron-down size-4 text-muted-foreground"
                        />
                      </button>
                    </RelayDropdownMenuTrigger>
                    <RelayDropdownMenuContent align="start" class="w-[430px]">
                      <RelayDropdownMenuItem
                        v-for="c in categoryOptions"
                        :key="c"
                        @click="selectedCategory = c"
                      >
                        {{ c }}
                      </RelayDropdownMenuItem>
                    </RelayDropdownMenuContent>
                  </RelayDropdownMenu>
                  <span class="text-xs text-muted-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.CATEGORY_HELPER')
                    }}
                  </span>
                </div>

                <div class="flex flex-col gap-2">
                  <label class="text-[13.5px] font-medium text-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.LANGUAGE_LABEL')
                    }}
                  </label>
                  <RelayDropdownMenu>
                    <RelayDropdownMenuTrigger as-child>
                      <button
                        type="button"
                        class="w-full h-10 rounded-md border border-input bg-transparent px-3 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 text-left flex items-center justify-between transition-colors hover:bg-muted/50"
                      >
                        <span class="text-foreground">{{
                          selectedLanguage
                        }}</span>
                        <span
                          class="i-lucide-chevron-down size-4 text-muted-foreground"
                        />
                      </button>
                    </RelayDropdownMenuTrigger>
                    <RelayDropdownMenuContent align="start" class="w-[430px]">
                      <RelayDropdownMenuItem
                        v-for="l in languageOptions"
                        :key="l"
                        @click="selectedLanguage = l"
                      >
                        {{ l }}
                      </RelayDropdownMenuItem>
                    </RelayDropdownMenuContent>
                  </RelayDropdownMenu>
                  <span class="text-xs text-muted-foreground">
                    {{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.LANGUAGE_HELPER')
                    }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div
            class="bg-background border-t border-border px-12 py-5 flex items-center justify-between shrink-0"
          >
            <RelayButton
              variant="outline"
              class="h-10 px-6 font-medium"
              @click="closeWizard"
            >
              {{ t('AUTORESPONDER.COMMON.CANCEL') }}
            </RelayButton>
            <RelayButton
              class="h-10 px-6 font-medium gap-2"
              @click="closeWizard"
            >
              {{ t('AUTORESPONDER.COMMON.NEXT') }}
              <span class="i-lucide-chevron-right size-4" />
            </RelayButton>
          </div>
        </div>

        <div
          class="w-[45%] shrink-0 border-l border-border bg-muted/10 flex flex-col h-full overflow-y-auto"
        >
          <div class="p-8 flex flex-col gap-8">
            <div class="flex flex-col gap-4">
              <div class="flex flex-col gap-1">
                <h3 class="text-sm font-semibold text-foreground">
                  {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_TITLE') }}
                </h3>
                <p class="text-[13px] text-muted-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_SUBTITLE')
                  }}
                </p>
              </div>

              <div
                class="bg-card border border-border rounded-xl overflow-hidden shadow-sm flex flex-col mt-2"
              >
                <div class="flex border-b border-border pt-1 px-2">
                  <button
                    v-for="tab in previewTabs"
                    :key="tab.id"
                    type="button"
                    class="flex items-center gap-2 px-3 pb-2.5 pt-2 text-xs font-medium border-b-2 -mb-px transition-colors"
                    :class="
                      activePreviewTab === tab.id
                        ? tab.activeClass
                        : 'border-transparent text-muted-foreground hover:text-foreground'
                    "
                    @click="activePreviewTab = tab.id"
                  >
                    <img :src="tab.logo" class="size-3.5 rounded-sm" />
                    {{ tab.id }}
                  </button>
                </div>

                <div class="p-4 bg-background min-h-[300px] flex flex-col">
                  <div
                    class="flex items-center justify-between pb-3 border-b border-border/60 mb-4"
                  >
                    <div class="flex items-center gap-2">
                      <span
                        class="i-lucide-chevron-left size-5 text-muted-foreground"
                      />
                      <img
                        src="https://i.pravatar.cc/150?u=1"
                        class="size-8 rounded-full"
                      />
                      <div class="flex flex-col">
                        <span
                          class="text-[13px] font-semibold text-foreground leading-none"
                          >{{
                            t(
                              'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.DEMO_USERNAME'
                            )
                          }}</span
                        >
                        <span
                          class="text-[11px] text-muted-foreground mt-0.5 leading-none"
                        >
                          {{
                            t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.ACTIVE_NOW')
                          }}
                        </span>
                      </div>
                    </div>
                    <span class="i-lucide-info size-5 text-muted-foreground" />
                  </div>

                  <div
                    class="bg-muted/50 rounded-2xl rounded-tl-sm p-4 text-[13.5px] text-foreground self-start max-w-[85%] relative shadow-sm border border-border/50"
                  >
                    {{
                      t(
                        'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_GREETING',
                        {
                          name: firstNameVar,
                        }
                      )
                    }}<br /><br />
                    {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.PREVIEW_BODY') }}
                  </div>
                  <span
                    class="text-[10px] text-muted-foreground self-center mt-3"
                    >{{
                      t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.DEMO_TIME')
                    }}</span
                  >
                </div>
              </div>
            </div>

            <div class="flex flex-col gap-4">
              <div class="flex flex-col gap-1">
                <h3 class="text-sm font-semibold text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.ABOUT_VARIABLES')
                  }}
                </h3>
                <p class="text-[13px] text-muted-foreground">
                  {{
                    t(
                      'AUTORESPONDER.CREATE_TEMPLATE_WIZARD.ABOUT_VARIABLES_DESC'
                    )
                  }}
                </p>
              </div>

              <div class="flex flex-wrap gap-2 mt-1">
                <div
                  v-for="v in variables"
                  :key="v"
                  class="px-3 py-1.5 rounded-md bg-primary/5 text-primary border border-primary/10 text-xs font-medium cursor-pointer hover:bg-primary/10 transition-colors"
                >
                  {{ v }}
                </div>
              </div>
            </div>

            <div
              class="bg-primary/5 border border-primary/10 rounded-xl p-5 flex flex-col gap-2 mt-2"
            >
              <div class="flex items-center gap-2">
                <span class="i-lucide-shield size-4 text-primary" />
                <span class="text-sm font-semibold text-foreground">
                  {{
                    t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.SAVE_TIME_TITLE')
                  }}
                </span>
              </div>
              <p class="text-[13px] text-muted-foreground leading-relaxed">
                {{ t('AUTORESPONDER.CREATE_TEMPLATE_WIZARD.SAVE_TIME_DESC') }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
