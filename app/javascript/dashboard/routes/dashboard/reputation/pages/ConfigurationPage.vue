<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed } from 'vue';
import {
  MessageSquare, Mail, MessageCircle, Video, Plus, Sparkles, Copy, Check,
  QrCode, Download, Bot, ShieldCheck, Link as LinkIcon,
} from 'lucide-vue-next';
import { RelaySwitch } from 'dashboard/components-next/relay';
import { defaultSmsTemplates, defaultEmailTemplates, defaultWhatsAppTemplates } from '../components/data/outreachTemplates';

const activeTab = ref('channels');
const tabs = [
  { id: 'channels', label: 'Channels & Templates' },
  { id: 'qr_link', label: 'Review Link & QR Hub' },
  { id: 'ai_outreach', label: 'Relay AI Automations' },
  { id: 'spam_shield', label: 'Spam & Protection Shield' },
];

// --- Tab 1: Channels & Templates ---
const CHANNELS = [
  { id: 'sms', label: 'SMS', icon: MessageSquare },
  { id: 'email', label: 'Email', icon: Mail },
  { id: 'whatsapp', label: 'WhatsApp', icon: MessageCircle },
  { id: 'video', label: 'Video Testimonial', icon: Video },
];
const selectedChannel = ref('sms');
const smsTemplateId = ref(defaultSmsTemplates[0].id);
const emailTemplateId = ref(defaultEmailTemplates[0].id);
const whatsappTemplateId = ref(defaultWhatsAppTemplates[0].id);
const smsMessage = ref(defaultSmsTemplates[0].message);
const emailSubject = ref(defaultEmailTemplates[0].subject);
const emailBody = ref(defaultEmailTemplates[0].body);
const whatsappBody = ref(defaultWhatsAppTemplates[0].bodyText);
const videoPrompt = ref('Hi {{FirstName}}, we would love a quick 45-second video sharing your experience with {{BusinessName}}!');

const channelTemplates = computed(() => {
  if (selectedChannel.value === 'sms') return defaultSmsTemplates;
  if (selectedChannel.value === 'email') return defaultEmailTemplates;
  if (selectedChannel.value === 'whatsapp') return defaultWhatsAppTemplates;
  return [];
});
const channelTemplateId = computed({
  get() {
    if (selectedChannel.value === 'sms') return smsTemplateId.value;
    if (selectedChannel.value === 'email') return emailTemplateId.value;
    if (selectedChannel.value === 'whatsapp') return whatsappTemplateId.value;
    return '';
  },
  set(id) {
    const t = channelTemplates.value.find(x => x.id === id);
    if (!t) return;
    if (selectedChannel.value === 'sms') { smsTemplateId.value = id; smsMessage.value = t.message; }
    else if (selectedChannel.value === 'email') { emailTemplateId.value = id; emailSubject.value = t.subject; emailBody.value = t.body; }
    else if (selectedChannel.value === 'whatsapp') { whatsappTemplateId.value = id; whatsappBody.value = t.bodyText; }
  },
});
const TAGS = ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}'];
function insertTag(tag) {
  if (selectedChannel.value === 'sms') smsMessage.value += ` ${tag}`;
  else if (selectedChannel.value === 'email') emailBody.value += ` ${tag}`;
  else if (selectedChannel.value === 'whatsapp') whatsappBody.value += ` ${tag}`;
  else videoPrompt.value += ` ${tag}`;
}

// --- Tab 2: Review Link & QR Hub ---
const reviewLink = ref(`${window.location.origin}/r/apex-dental`);
const linkCopied = ref(false);
function copyLink() {
  navigator.clipboard?.writeText(reviewLink.value);
  linkCopied.value = true;
  setTimeout(() => { linkCopied.value = false; }, 2000);
}
const qrFrame = ref('badge');
const qrFrames = [
  { id: 'badge', label: 'Badge' },
  { id: 'stars', label: 'Stars' },
  { id: 'simple', label: 'Simple' },
];
const qrTitle = ref('Scan to Rate Us on Google');
const qrSubtitle = ref('Takes only 30 seconds!');
const includeLogo = ref(true);
const isQrDownloaded = ref(false);
function selectQrFrame(frame) {
  qrFrame.value = frame;
  if (frame === 'badge') { qrTitle.value = 'Scan to Rate Us on Google'; qrSubtitle.value = 'Takes only 30 seconds!'; }
  else if (frame === 'stars') { qrTitle.value = 'How Was Your Visit?'; qrSubtitle.value = 'We appreciate your feedback!'; }
  else { qrTitle.value = 'Scan with Camera'; qrSubtitle.value = ''; }
}
function downloadQrCode() {
  isQrDownloaded.value = true;
  setTimeout(() => { isQrDownloaded.value = false; }, 2000);
}

// --- Tab 3: Relay AI Automations ---
const aiSettings = ref({
  enableAutoReply: false,
  minRating: '4_stars',
  customInstructions: 'Thank customers for their feedback, address any concerns politely, and offer support contact.',
});
const ratingOptions = [
  { value: '5_stars', label: '5 Stars only' },
  { value: '4_stars', label: '4 Stars & above' },
  { value: '3_stars', label: '3 Stars & above' },
  { value: 'all', label: 'All reviews (1-5 Stars)' },
];
const isAiSaved = ref(false);
function saveAiConfig() {
  isAiSaved.value = true;
  setTimeout(() => { isAiSaved.value = false; }, 2000);
}

// --- Tab 4: Spam & Protection Shield ---
const spamSettings = ref({ autoFlagRating: '3_stars_below', blocklistKeywords: '' });
const autoFlagOptions = [
  { value: '3_stars_below', label: '3 Stars & below' },
  { value: '2_stars_below', label: '2 Stars & below' },
  { value: '1_star_only', label: '1 Star only' },
  { value: 'disabled', label: 'Disabled (Flag none)' },
];
const isSpamSaved = ref(false);
function saveSpamConfig() {
  isSpamSaved.value = true;
  setTimeout(() => { isSpamSaved.value = false; }, 2000);
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full bg-background p-6 lg:p-8">
    <div class="max-w-7xl mx-auto space-y-7">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-lg font-semibold text-foreground">Configuration</h1>
            <span class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Showcase — the live request templates and QR generator are in Reputation Settings">Demo</span>
          </div>
          <p class="text-sm text-muted-foreground mt-1">Collect verified 5-star customer reviews across Google, Yelp, and Facebook via automated multi-channel sequences.</p>
        </div>
      </div>

      <!-- Tabs -->
      <div class="border-b border-border/80 flex items-center gap-7 overflow-x-auto">
        <button v-for="tab in tabs" :key="tab.id" type="button" class="pb-3 -mb-px text-sm font-medium whitespace-nowrap border-b-2 transition-colors cursor-pointer" :class="activeTab === tab.id ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'" @click="activeTab = tab.id">
          {{ tab.label }}
        </button>
      </div>

      <!-- TAB 1: Channels & Templates -->
      <div v-if="activeTab === 'channels'" class="space-y-6">
        <div class="bg-card border border-border rounded-2xl shadow-xs p-6 space-y-5">
          <div class="flex items-start justify-between gap-4 flex-wrap">
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">{{ CHANNELS.find(c => c.id === selectedChannel).label }} Request Template</h2>
              <p class="text-[13px] text-muted-foreground mt-0.5">{{ selectedChannel === 'video' ? 'Customize the video testimonial prompts and recording interface.' : 'Customize the automated message sent to your customers.' }}</p>
            </div>
            <div class="flex items-center gap-1.5 flex-wrap">
              <button v-for="ch in CHANNELS" :key="ch.id" type="button" class="h-8 px-3 rounded-lg border text-xs font-medium inline-flex items-center gap-1.5 cursor-pointer transition-colors" :class="selectedChannel === ch.id ? 'bg-primary/10 border-primary text-primary' : 'bg-card border-border text-muted-foreground hover:bg-muted'" @click="selectedChannel = ch.id">
                <component :is="ch.icon" class="size-3.5" /> {{ ch.label }}
              </button>
            </div>
          </div>

          <div v-if="selectedChannel !== 'video'" class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1 flex flex-col gap-1.5">
              <label class="text-[13px] font-medium text-foreground">{{ CHANNELS.find(c => c.id === selectedChannel).label }} Template</label>
              <select v-model="channelTemplateId" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer">
                <option v-for="t in channelTemplates" :key="t.id" :value="t.id">{{ t.name }}</option>
              </select>
            </div>
            <div class="flex items-end">
              <button class="h-10 px-4 rounded-md border border-border bg-card hover:bg-muted text-sm font-semibold inline-flex items-center gap-2 cursor-pointer"><Plus class="size-4" /> New Template</button>
            </div>
          </div>

          <!-- Email subject -->
          <div v-if="selectedChannel === 'email'" class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Email Subject Line</label>
            <input v-model="emailSubject" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30" />
          </div>

          <div class="flex flex-col gap-1.5">
            <div class="flex items-center justify-between">
              <label class="text-[13px] font-medium text-foreground">{{ selectedChannel === 'video' ? 'Video Prompt' : selectedChannel === 'email' ? 'Email Body Copy' : 'Message Content' }}</label>
              <span v-if="selectedChannel === 'sms'" class="text-[11.5px] text-muted-foreground font-mono">{{ smsMessage.length }} / 160 characters ({{ Math.ceil(smsMessage.length / 160) || 1 }} SMS)</span>
            </div>
            <textarea v-if="selectedChannel === 'sms'" v-model="smsMessage" rows="4" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
            <textarea v-else-if="selectedChannel === 'email'" v-model="emailBody" rows="5" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
            <textarea v-else-if="selectedChannel === 'whatsapp'" v-model="whatsappBody" rows="4" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
            <textarea v-else v-model="videoPrompt" rows="4" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
          </div>

          <div class="flex flex-wrap items-center gap-1.5">
            <span class="text-[12px] text-muted-foreground mr-1">Insert tag:</span>
            <button v-for="tag in TAGS" :key="tag" type="button" class="font-mono text-[11px] px-2 py-1 rounded-md bg-muted hover:bg-primary/20 text-foreground cursor-pointer" @click="insertTag(tag)">{{ tag }}</button>
          </div>
        </div>
      </div>

      <!-- TAB 2: Review Link & QR Hub -->
      <div v-else-if="activeTab === 'qr_link'" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-card border border-border rounded-2xl shadow-xs p-6 space-y-5">
          <div class="flex items-center gap-2">
            <LinkIcon class="size-4 text-primary" />
            <h2 class="text-[15px] font-semibold text-foreground">Your Review Link</h2>
          </div>
          <p class="text-[13px] text-muted-foreground">Share this smart link anywhere — it routes reviewers to the right platform automatically.</p>
          <div class="flex items-center gap-2">
            <input readonly :value="reviewLink" class="flex-1 h-10 px-3 text-sm rounded-md border border-border bg-muted/30 font-mono text-muted-foreground focus:outline-none" />
            <button class="h-10 px-4 rounded-md bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer hover:bg-primary/90" @click="copyLink">
              <Check v-if="linkCopied" class="size-4" /><Copy v-else class="size-4" /> {{ linkCopied ? 'Copied' : 'Copy' }}
            </button>
          </div>
        </div>

        <div class="bg-card border border-border rounded-2xl shadow-xs p-6 space-y-5">
          <div class="flex items-center gap-2">
            <QrCode class="size-4 text-primary" />
            <h2 class="text-[15px] font-semibold text-foreground">QR Code Hub</h2>
          </div>
          <div class="flex items-center gap-2">
            <button v-for="f in qrFrames" :key="f.id" type="button" class="h-8 px-3 rounded-lg border text-xs font-medium cursor-pointer transition-colors" :class="qrFrame === f.id ? 'bg-primary/10 border-primary text-primary' : 'bg-card border-border text-muted-foreground hover:bg-muted'" @click="selectQrFrame(f.id)">{{ f.label }}</button>
          </div>
          <div class="flex flex-col items-center gap-3 p-6 rounded-xl bg-muted/30 border border-border">
            <div class="text-sm font-semibold text-foreground text-center">{{ qrTitle }}</div>
            <div class="size-36 rounded-lg bg-card border border-border grid grid-cols-5 grid-rows-5 gap-0.5 p-2">
              <span v-for="n in 25" :key="n" class="rounded-sm" :class="(n * 7) % 3 === 0 ? 'bg-foreground' : 'bg-transparent'"></span>
            </div>
            <div v-if="qrSubtitle" class="text-[12px] text-muted-foreground">{{ qrSubtitle }}</div>
          </div>
          <div class="flex items-center justify-between">
            <label class="flex items-center gap-2 text-[13px] text-foreground cursor-pointer">
              <RelaySwitch v-model="includeLogo" /> Include business logo
            </label>
            <button class="h-9 px-4 rounded-md bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer hover:bg-primary/90" @click="downloadQrCode">
              <Check v-if="isQrDownloaded" class="size-4" /><Download v-else class="size-4" /> {{ isQrDownloaded ? 'Downloaded' : 'Download QR' }}
            </button>
          </div>
        </div>
      </div>

      <!-- TAB 3: Relay AI Automations -->
      <div v-else-if="activeTab === 'ai_outreach'" class="max-w-2xl space-y-6">
        <div class="bg-card border border-border rounded-2xl shadow-xs p-6 space-y-5">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2.5">
              <div class="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center"><Bot class="size-5" /></div>
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">Relay AI Auto-Reply</h2>
                <p class="text-[12.5px] text-muted-foreground">Automatically draft and publish on-brand responses to new reviews.</p>
              </div>
            </div>
            <RelaySwitch v-model="aiSettings.enableAutoReply" />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Auto-reply to</label>
            <select v-model="aiSettings.minRating" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer">
              <option v-for="opt in ratingOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
            </select>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Custom AI Instructions</label>
            <textarea v-model="aiSettings.customInstructions" rows="4" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
          </div>
          <div class="flex items-center justify-end gap-2">
            <button class="h-9 px-4 rounded-md bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer hover:bg-primary/90" @click="saveAiConfig">
              <Check v-if="isAiSaved" class="size-4" /><Sparkles v-else class="size-4" /> {{ isAiSaved ? 'Saved' : 'Save Automation' }}
            </button>
          </div>
        </div>
      </div>

      <!-- TAB 4: Spam & Protection Shield -->
      <div v-else class="max-w-2xl space-y-6">
        <div class="bg-card border border-border rounded-2xl shadow-xs p-6 space-y-5">
          <div class="flex items-center gap-2.5">
            <div class="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center"><ShieldCheck class="size-5" /></div>
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Spam & Protection Shield</h2>
              <p class="text-[12.5px] text-muted-foreground">Auto-flag suspicious low-rated reviews and filter abusive language.</p>
            </div>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Auto-flag reviews rated</label>
            <select v-model="spamSettings.autoFlagRating" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer">
              <option v-for="opt in autoFlagOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
            </select>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Blocklist keywords <span class="text-muted-foreground font-normal">(comma-separated)</span></label>
            <textarea v-model="spamSettings.blocklistKeywords" rows="3" placeholder="scam, fake, competitor…" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
          </div>
          <div class="flex items-center justify-end gap-2">
            <button class="h-9 px-4 rounded-md bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer hover:bg-primary/90" @click="saveSpamConfig">
              <Check v-if="isSpamSaved" class="size-4" /><ShieldCheck v-else class="size-4" /> {{ isSpamSaved ? 'Saved' : 'Save Protection Rules' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
