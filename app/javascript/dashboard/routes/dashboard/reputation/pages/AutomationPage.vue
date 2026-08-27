<script setup>
/* eslint-disable */
// Port of NewRelay reference `reputation/SettingsView.vue` (auto-responder / gating / alerts /
// badge). Kept separate from the existing config hub (SettingsPage.vue) which owns integrations,
// request channels, QR and spam. Persists to the reputation settings endpoint under the
// `automation` key (Configuration owns the sibling keys in the same jsonb blob).
import { reactive, ref, onMounted } from 'vue';
import { RelaySwitch, RelayInput, RelayButton } from 'dashboard/components-next/relay';
import { Bot, Shield, Bell, Code, Sparkles, Save, Check, Copy } from 'lucide-vue-next';

const axios = window.axios;
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const settingsUrl = () => `/api/v1/accounts/${accountId}/reputation/settings`;

const defaults = {
  aiAutoDraft: true,
  aiAutoPublish5Star: true,
  aiTone: 'Friendly',
  aiDelay: '15_mins',
  enableSmartRouting: true,
  positiveThreshold: '4',
  negativeRedirectUrl: '',
  notifyOnNegative: true,
  dailyDigest: true,
  alertEmail: '',
};
const settings = reactive({ ...defaults });

onMounted(async () => {
  try {
    const { data } = await axios.get(settingsUrl());
    Object.assign(settings, data?.config?.automation || {});
  } catch (e) { /* no saved settings yet */ }
});

const isSaved = ref(false);
async function handleSave() {
  try { await axios.patch(settingsUrl(), { config: { automation: { ...settings } } }); } catch (e) { /* keep UI optimistic */ }
  isSaved.value = true;
  setTimeout(() => { isSaved.value = false; }, 2500);
}

// split the closing tag so the SFC parser doesn't end the script block early
const widgetSnippet = `<script src="https://cdn.newrelay.com/widgets/reputation-badge.js" data-site-id="nr_847291" async><\/script>`;
const copiedSnippet = ref(false);
function copyCode() {
  navigator.clipboard.writeText(widgetSnippet);
  copiedSnippet.value = true;
  setTimeout(() => { copiedSnippet.value = false; }, 2000);
}

const inputClass = 'h-9 text-[14px]';
const selectClass =
  'h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground w-full shadow-2xs focus-visible:ring-1 focus-visible:ring-primary/30 outline-none cursor-pointer';
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full bg-background p-6 lg:p-8">
    <div class="max-w-5xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">Automation &amp; Policies</h1>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Manage review gating, Relay AI auto-responder policies, alerts, and website embed widgets.</p>
        </div>
        <RelayButton class="gap-2 shadow-xs text-[13.5px]" @click="handleSave">
          <Check v-if="isSaved" class="size-4 text-emerald-500" />
          <Save v-else class="size-4" />
          {{ isSaved ? 'Saved!' : 'Save Changes' }}
        </RelayButton>
      </div>

      <div class="space-y-6">
        <!-- 1. Relay AI Auto-Responder -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-5">
          <div class="flex items-start justify-between gap-3 border-b border-border pb-4">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg bg-primary/10 text-primary"><Bot class="size-5" /></div>
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">Relay AI Auto-Responder</h2>
                <p class="text-[13px] text-muted-foreground">Automate instant personalized replies to customer reviews across connected platforms.</p>
              </div>
            </div>
            <span class="inline-flex items-center gap-1 text-[11px] py-0.5 px-2 rounded-md border border-primary/30 text-primary">
              <Sparkles class="size-3" /> Relay AI Powered
            </span>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5 text-[13.5px]">
            <div class="flex items-center justify-between p-4 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-foreground">Auto-Draft Smart Replies</div>
                <div class="text-[12px] text-muted-foreground">Pre-generate suggested responses for agent review</div>
              </div>
              <RelaySwitch v-model="settings.aiAutoDraft" />
            </div>
            <div class="flex items-center justify-between p-4 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-foreground">Auto-Publish for 5-Star Reviews</div>
                <div class="text-[12px] text-muted-foreground">Instantly post verified grateful replies to glowing reviews</div>
              </div>
              <RelaySwitch v-model="settings.aiAutoPublish5Star" />
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">AI Response Tone</label>
              <select v-model="settings.aiTone" :class="selectClass">
                <option value="Friendly">Friendly &amp; Enthusiastic</option>
                <option value="Professional">Professional &amp; Courteous</option>
                <option value="Warm">Warm &amp; Grateful</option>
                <option value="Concise">Concise &amp; Direct</option>
              </select>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Natural Response Delay</label>
              <select v-model="settings.aiDelay" :class="selectClass">
                <option value="5_mins">5 minutes</option>
                <option value="15_mins">15 minutes (Recommended)</option>
                <option value="1_hour">1 hour</option>
                <option value="immediate">Immediate</option>
              </select>
            </div>
          </div>
        </div>

        <!-- 2. Smart Review Gating & Sentiment Routing -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-5">
          <div class="flex items-center gap-3 border-b border-border pb-4">
            <div class="p-2 rounded-lg bg-primary/10 text-primary"><Shield class="size-5" /></div>
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Smart Review Gating &amp; Sentiment Routing</h2>
              <p class="text-[13px] text-muted-foreground">Protect brand reputation by directing unhappy customers to an internal private feedback channel.</p>
            </div>
          </div>

          <div class="flex items-center justify-between p-4 rounded-lg bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Enable Smart Sentiment Filtering</div>
              <div class="text-[12px] text-muted-foreground">Redirect scores below the threshold to a private support resolution ticket instead of public sites</div>
            </div>
            <RelaySwitch v-model="settings.enableSmartRouting" />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Public Review Threshold</label>
              <select v-model="settings.positiveThreshold" :class="selectClass">
                <option value="4">4 Stars &amp; Above (Allow 4 and 5 stars to public sites)</option>
                <option value="5">5 Stars Only (Strict 5-star gating)</option>
              </select>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Private Resolution Form URL</label>
              <RelayInput v-model="settings.negativeRedirectUrl" placeholder="https://mycompany.com/feedback" :class-name="inputClass" />
            </div>
          </div>
        </div>

        <!-- 3. Notification & Alert Preferences -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-5">
          <div class="flex items-center gap-3 border-b border-border pb-4">
            <div class="p-2 rounded-lg bg-primary/10 text-primary"><Bell class="size-5" /></div>
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Notification &amp; Alert Preferences</h2>
              <p class="text-[13px] text-muted-foreground">Stay informed whenever new customer reviews or critical negative feedback are submitted.</p>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="flex items-center justify-between p-3.5 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-[13.5px] text-foreground">Immediate Negative Review Alert</div>
                <div class="text-[12px] text-muted-foreground">Alert assigned team when rating is ≤ 3 stars</div>
              </div>
              <RelaySwitch v-model="settings.notifyOnNegative" />
            </div>
            <div class="flex items-center justify-between p-3.5 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-[13.5px] text-foreground">Daily Performance Digest</div>
                <div class="text-[12px] text-muted-foreground">Receive daily summary of new reviews &amp; sentiment</div>
              </div>
              <RelaySwitch v-model="settings.dailyDigest" />
            </div>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Alert Notification Email</label>
            <RelayInput v-model="settings.alertEmail" type="email" placeholder="operations@mycompany.com" :class-name="inputClass" />
          </div>
        </div>

        <!-- 4. Website Trust Badge Embed -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-4">
          <div class="flex items-center justify-between border-b border-border pb-4">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg bg-primary/10 text-primary"><Code class="size-5" /></div>
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">Website Trust Badge Embed</h2>
                <p class="text-[13px] text-muted-foreground">Embed a live synchronized rating badge on your website header or footer.</p>
              </div>
            </div>
            <RelayButton variant="outline" size="sm" class="gap-1.5 text-[12.5px]" @click="copyCode">
              <Check v-if="copiedSnippet" class="size-3.5 text-emerald-500" />
              <Copy v-else class="size-3.5" />
              {{ copiedSnippet ? 'Copied Snippet' : 'Copy Code' }}
            </RelayButton>
          </div>
          <div class="p-3 bg-muted rounded-lg font-mono text-[12.5px] text-foreground overflow-x-auto select-all">{{ widgetSnippet }}</div>
        </div>
      </div>
    </div>
  </div>
</template>
