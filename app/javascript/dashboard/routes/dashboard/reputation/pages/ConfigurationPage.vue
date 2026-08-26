<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed } from 'vue';
import {
  MessageSquare, Mail, MessageCircle, Video, Plus, Sparkles, Copy, Check,
  QrCode, Download, Printer, Bot, ShieldCheck, ChevronDown, Star, ExternalLink,
  Signal, Wifi, MoreVertical, Paperclip, Smile, Mic, Trash2, Archive, Phone, Info,
  ChevronLeft, CheckCircle2,
} from 'lucide-vue-next';
import {
  RelaySwitch,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem,
} from 'dashboard/components-next/relay';
import { defaultSmsTemplates, defaultEmailTemplates, defaultWhatsAppTemplates } from '../components/data/outreachTemplates';

const activeTab = ref('channels');
const tabs = [
  { id: 'channels', label: 'Channels & Templates' },
  { id: 'qr_link', label: 'Review Link & QR Hub' },
  { id: 'ai_outreach', label: 'Relay AI Automations' },
  { id: 'spam_shield', label: 'Spam & Protection Shield' },
];

// ---------- Tab 1: Channels & Templates ----------
const CHANNELS = [
  { id: 'sms', label: 'SMS', icon: MessageSquare },
  { id: 'email', label: 'Email', icon: Mail },
  { id: 'whatsapp', label: 'WhatsApp', icon: MessageCircle },
  { id: 'video', label: 'Video Testimonial', icon: Video },
];
const selectedChannel = ref('sms');
const channelLabel = computed(() => CHANNELS.find(c => c.id === selectedChannel.value).label);
const smsTemplateId = ref(defaultSmsTemplates[0].id);
const emailTemplateId = ref(defaultEmailTemplates[0].id);
const whatsappTemplateId = ref(defaultWhatsAppTemplates[0].id);
const smsMessage = ref(defaultSmsTemplates[0].message);
const emailSubject = ref(defaultEmailTemplates[0].subject);
const emailBody = ref(defaultEmailTemplates[0].body);
const whatsappHeader = ref(defaultWhatsAppTemplates[0].headerText);
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
    else if (selectedChannel.value === 'whatsapp') { whatsappTemplateId.value = id; whatsappHeader.value = t.headerText; whatsappBody.value = t.bodyText; }
  },
});
const TAGS = ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}'];
function insertTag(tag) {
  if (selectedChannel.value === 'sms') smsMessage.value += ` ${tag}`;
  else if (selectedChannel.value === 'email') emailBody.value += ` ${tag}`;
  else if (selectedChannel.value === 'whatsapp') whatsappBody.value += ` ${tag}`;
  else videoPrompt.value += ` ${tag}`;
}
const fillVars = t => (t || '')
  .replaceAll('{{FirstName}}', 'Sarah')
  .replaceAll('{{BusinessName}}', 'New Relay')
  .replaceAll('{{ReviewLink}}', 'relay.to/r/apex-dental')
  .replaceAll('{{EmployeeName}}', 'Alex');
const pvEmailSubject = computed(() => fillVars(emailSubject.value));
const pvEmailBody = computed(() => fillVars(emailBody.value));
const pvSms = computed(() => fillVars(smsMessage.value));
const pvWaHeader = computed(() => fillVars(whatsappHeader.value));
const pvWaBody = computed(() => fillVars(whatsappBody.value));
const pvVideo = computed(() => fillVars(videoPrompt.value));

// ---------- Tab 2: Review Link & QR Hub ----------
const customSlug = ref('apex-dental');
const reviewLink = computed(() => `https://relay.to/r/${customSlug.value}`);
const isLinkCopied = ref(false);
function copyReviewLink() {
  navigator.clipboard?.writeText(reviewLink.value);
  isLinkCopied.value = true;
  setTimeout(() => { isLinkCopied.value = false; }, 2000);
}
const selectedDestination = ref('google');
const destinationLabels = {
  google: 'Google Business Profile (Direct Pop-up)',
  smart: 'Smart Multi-Platform Landing Page',
  yelp: 'Yelp Business Page',
  trustpilot: 'Trustpilot Verified Portal',
};
const qrFrame = ref('badge');
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

// ---------- Tab 3: Relay AI Automations ----------
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

// ---------- Tab 4: Spam & Protection Shield ----------
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
      <div class="border-b border-border flex items-center gap-6 text-[13px] font-semibold overflow-x-auto">
        <button v-for="tab in tabs" :key="tab.id" type="button" class="py-3 border-b-2 transition-colors -mb-[1px] whitespace-nowrap cursor-pointer" :class="activeTab === tab.id ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'" @click="activeTab = tab.id">
          {{ tab.label }}
        </button>
      </div>

      <!-- ================= TAB 1: CHANNELS & TEMPLATES ================= -->
      <div v-if="activeTab === 'channels'" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <!-- Editor -->
        <div class="lg:col-span-8 bg-card border border-border rounded-2xl shadow-xs p-6 sm:p-7 space-y-6">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border">
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">{{ channelLabel }} Request Template</h2>
                <p class="text-[13px] text-muted-foreground mt-0.5">{{ selectedChannel === 'video' ? 'Customize the video testimonial prompt and recording interface.' : 'Customize the automated message sent to your customers.' }}</p>
              </div>
              <div class="flex items-center gap-1.5 flex-wrap">
                <button v-for="ch in CHANNELS" :key="ch.id" type="button" class="h-8 px-3 rounded-lg border text-xs font-medium inline-flex items-center gap-1.5 cursor-pointer transition-colors" :class="selectedChannel === ch.id ? 'bg-primary/10 border-primary text-primary' : 'bg-card border-border text-muted-foreground hover:bg-muted'" @click="selectedChannel = ch.id">
                  <component :is="ch.icon" class="size-3.5" /> {{ ch.label }}
                </button>
              </div>
            </div>

            <div v-if="selectedChannel !== 'video'" class="flex flex-col sm:flex-row gap-3">
              <div class="flex-1 flex flex-col gap-1.5">
                <label class="text-[13px] font-medium text-foreground">{{ channelLabel }} Template</label>
                <select v-model="channelTemplateId" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer">
                  <option v-for="t in channelTemplates" :key="t.id" :value="t.id">{{ t.name }}</option>
                </select>
              </div>
              <div class="flex items-end">
                <button class="h-10 px-4 rounded-md border border-border bg-card hover:bg-muted text-sm font-semibold inline-flex items-center gap-2 cursor-pointer"><Plus class="size-4" /> New Template</button>
              </div>
            </div>

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

        <!-- Live phone preview -->
        <div class="lg:col-span-4 bg-muted/40 rounded-2xl border border-border p-5 flex flex-col items-center justify-center relative overflow-hidden min-h-[520px]">
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="w-[260px] h-[460px] bg-card rounded-[30px] shadow-2xl border border-border flex flex-col overflow-hidden relative z-10">
              <div class="pt-3 px-4 pb-1 flex items-center justify-between text-[10.5px] font-medium text-foreground/80 shrink-0 select-none">
                <span class="font-semibold text-foreground">9:41</span>
                <div class="flex items-center gap-1 text-foreground/70"><Signal class="size-2.5" /><Wifi class="size-2.5" /><div class="w-4 h-2 rounded-[2px] border border-foreground/70 p-0.5 flex items-center"><div class="h-full w-2 bg-foreground/80 rounded-[1px]"></div></div></div>
              </div>

              <!-- EMAIL -->
              <div v-if="selectedChannel === 'email'" class="flex-1 flex flex-col overflow-hidden">
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-2"><ChevronLeft class="size-4 text-primary shrink-0" /><span class="text-xs font-semibold text-foreground">Inbox</span></div>
                  <div class="flex items-center gap-2 text-muted-foreground"><Archive class="size-3.5" /><Trash2 class="size-3.5" /><MoreVertical class="size-3.5" /></div>
                </div>
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-muted/30">
                  <div class="space-y-1 pb-2 border-b border-border/40">
                    <div class="text-[12px] font-bold text-foreground leading-tight">{{ pvEmailSubject }}</div>
                    <div class="flex items-center justify-between pt-1">
                      <div class="flex items-center gap-2 min-w-0"><div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">NR</div><div class="min-w-0"><div class="text-[11px] font-semibold text-foreground truncate">New Relay</div><div class="text-[9px] text-muted-foreground truncate">to sarah.j@gmail.com</div></div></div>
                      <span class="text-[9px] text-muted-foreground shrink-0">9:41 AM</span>
                    </div>
                  </div>
                  <div class="p-3 bg-card border border-border/60 rounded-2xl shadow-xs space-y-3">
                    <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground">{{ pvEmailBody }}</div>
                    <div class="p-2.5 rounded-xl bg-primary/10 border border-primary/20 text-center space-y-2">
                      <div class="text-[11px] font-semibold text-primary">Rate on {{ destinationLabels[selectedDestination].split(' ')[0] }}</div>
                      <div class="flex justify-center gap-1 text-amber-500"><Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-500 text-amber-500" /></div>
                      <div class="w-full py-1.5 rounded-lg bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1 shadow-xs"><span>Leave a Review</span><ExternalLink class="size-2.5" /></div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- WHATSAPP -->
              <div v-else-if="selectedChannel === 'whatsapp'" class="flex-1 flex flex-col overflow-hidden">
                <div class="px-3 py-2 bg-emerald-600 dark:bg-emerald-700 text-white flex items-center justify-between shrink-0 shadow-xs">
                  <div class="flex items-center gap-2 min-w-0"><ChevronLeft class="size-4 shrink-0" /><div class="size-7 rounded-full bg-white/20 text-white flex items-center justify-center font-bold text-[10.5px] shrink-0 border border-white/30">NR</div><div class="min-w-0"><div class="flex items-center gap-1"><span class="text-xs font-semibold truncate text-white">New Relay</span><CheckCircle2 class="size-3 text-emerald-200 shrink-0" /></div><span class="text-[9px] text-emerald-100 block truncate">Business Account</span></div></div>
                  <div class="flex items-center gap-2.5 text-white/90"><Phone class="size-3.5" /><MoreVertical class="size-3.5" /></div>
                </div>
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-muted/40">
                  <div class="flex justify-center"><span class="text-[9px] bg-card text-muted-foreground px-2 py-0.5 rounded-md shadow-xs font-medium">Today</span></div>
                  <div class="bg-card text-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs border border-border/40 text-xs space-y-2 max-w-[94%]">
                    <div class="text-[12px] font-semibold text-foreground">{{ pvWaHeader }}</div>
                    <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground">{{ pvWaBody }}</div>
                    <div class="flex items-center justify-end gap-1 text-[8.5px] text-muted-foreground"><span>9:41 AM</span><span class="text-primary font-bold">✓✓</span></div>
                  </div>
                </div>
                <div class="p-2 bg-card border-t border-border/40 flex items-center gap-1.5 shrink-0"><Smile class="size-4 text-muted-foreground shrink-0" /><div class="flex-1 h-6 bg-muted/60 rounded-full px-2.5 text-[9.5px] text-muted-foreground flex items-center truncate">Message</div><Paperclip class="size-3.5 text-muted-foreground shrink-0" /><div class="size-6 rounded-full bg-emerald-600 text-white flex items-center justify-center shrink-0"><Mic class="size-2.5" /></div></div>
              </div>

              <!-- VIDEO -->
              <div v-else-if="selectedChannel === 'video'" class="flex-1 flex flex-col overflow-hidden bg-muted/30">
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20"><div class="flex items-center gap-1 text-primary"><ChevronLeft class="size-4 shrink-0" /><span class="text-[11px] font-medium">Record</span></div><Info class="size-3.5 text-primary shrink-0" /></div>
                <div class="flex-1 flex flex-col items-center justify-center p-4 gap-4 text-center">
                  <div class="size-16 rounded-full bg-primary/10 text-primary flex items-center justify-center"><Video class="size-7" /></div>
                  <div class="text-[12.5px] leading-relaxed text-foreground whitespace-pre-wrap">{{ pvVideo }}</div>
                  <div class="w-full py-2 rounded-lg bg-primary text-primary-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 shadow-xs">Record Video Testimonial 🎥</div>
                </div>
              </div>

              <!-- SMS -->
              <div v-else class="flex-1 flex flex-col overflow-hidden">
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20"><div class="flex items-center gap-1 text-primary"><ChevronLeft class="size-4 shrink-0" /><span class="text-[11px] font-medium">Messages</span></div><div class="flex flex-col items-center"><div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[9px]">NR</div><span class="text-[9.5px] font-semibold text-foreground">New Relay</span></div><Info class="size-3.5 text-primary shrink-0" /></div>
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-muted/30">
                  <div class="text-[9.5px] text-center text-muted-foreground font-medium">Text Message · Today 9:41 AM</div>
                  <div class="bg-primary text-primary-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs text-xs space-y-2 max-w-[94%]">
                    <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap">{{ pvSms }}</div>
                    <div class="text-[8.5px] text-right opacity-80">Delivered</div>
                  </div>
                </div>
                <div class="p-2 bg-card border-t border-border/40 flex items-center gap-1.5 shrink-0"><div class="size-5 rounded-full bg-muted flex items-center justify-center text-muted-foreground font-bold text-xs shrink-0">+</div><div class="flex-1 h-6 bg-muted/60 rounded-full px-2.5 text-[9.5px] text-muted-foreground flex items-center truncate">Text Message</div></div>
              </div>
            </div>
            <div class="text-center mt-2.5"><span class="text-[11px] text-muted-foreground font-medium">{{ channelLabel }} Preview</span></div>
        </div>
      </div>

      <!-- ================= TAB 2: REVIEW LINK & QR HUB ================= -->
      <div v-else-if="activeTab === 'qr_link'" class="space-y-6">
        <!-- Review Shortlink & Routing -->
        <div class="bg-card rounded-2xl border border-border p-6 sm:p-7 shadow-xs space-y-5">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-3.5 border-b border-border">
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Review Shortlink & Routing</h2>
              <p class="text-[12.5px] text-muted-foreground mt-0.5">Customize your permanent review shortlink and primary destination platform.</p>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-[11px] font-medium px-2 py-0.5 rounded-md bg-muted text-muted-foreground">SSL Encrypted</span>
              <span class="text-[11px] font-medium px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">Active</span>
            </div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-12 gap-5 items-end">
            <div class="md:col-span-7 flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Custom Link Slug</label>
              <div class="flex items-center">
                <span class="h-10 inline-flex items-center px-3 bg-muted/50 text-muted-foreground border border-r-0 border-border rounded-l-md text-[13px] font-mono select-none">https://relay.to/r/</span>
                <input v-model="customSlug" class="h-10 flex-1 min-w-0 px-3 text-[13.5px] font-mono border-y border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30" />
                <button class="h-10 px-3.5 rounded-r-md border border-border bg-background hover:bg-muted text-[13px] inline-flex items-center gap-1.5 shrink-0 cursor-pointer" @click="copyReviewLink">
                  <Check v-if="isLinkCopied" class="size-3.5 text-emerald-500" /><Copy v-else class="size-3.5 text-muted-foreground" /> {{ isLinkCopied ? 'Copied' : 'Copy' }}
                </button>
              </div>
            </div>
            <div class="md:col-span-5 flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Review Destination</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="h-10 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between hover:bg-muted w-full text-left cursor-pointer">
                    <span class="truncate">{{ destinationLabels[selectedDestination] }}</span>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[320px]" align="end">
                  <DropdownMenuItem v-for="(label, key) in destinationLabels" :key="key" class="text-[13px] cursor-pointer" @click="selectedDestination = key">{{ label }}</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>

        <!-- QR Stand Customizer + Mockup -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <div class="lg:col-span-8 bg-card rounded-2xl border border-border p-6 sm:p-7 shadow-xs space-y-6">
            <div class="pb-3.5 border-b border-border">
              <h2 class="text-[15px] font-semibold text-foreground">Printable QR Stand Customizer</h2>
              <p class="text-[12.5px] text-muted-foreground mt-0.5">Customize table-tent signage, call-to-action text, and branding for in-person review collection.</p>
            </div>
            <div class="flex flex-col gap-2">
              <label class="text-[13.5px] font-medium text-foreground">Frame Style</label>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <button type="button" class="flex flex-col items-center justify-center p-3.5 rounded-xl border transition-all text-center cursor-pointer" :class="qrFrame === 'badge' ? 'border-primary bg-primary/5 ring-1 ring-primary/30' : 'border-border/80 bg-background hover:border-border hover:bg-muted/30'" @click="selectQrFrame('badge')">
                  <div class="h-8 w-full flex items-center justify-center mb-1.5"><div class="px-2 py-0.5 rounded-full bg-muted/80 border border-border/80 flex items-center gap-1"><Star class="size-2.5 text-amber-500 fill-amber-500" /><span class="text-[9.5px] font-semibold text-foreground">Google 5.0</span></div></div>
                  <span class="text-[13px] font-medium text-foreground">Google Badge</span>
                  <span class="text-[11px] text-muted-foreground mt-0.5">Verified review pill</span>
                </button>
                <button type="button" class="flex flex-col items-center justify-center p-3.5 rounded-xl border transition-all text-center cursor-pointer" :class="qrFrame === 'stars' ? 'border-primary bg-primary/5 ring-1 ring-primary/30' : 'border-border/80 bg-background hover:border-border hover:bg-muted/30'" @click="selectQrFrame('stars')">
                  <div class="h-8 w-full flex items-center justify-center mb-1.5"><div class="flex items-center gap-0.5 text-amber-500"><Star v-for="s in 5" :key="s" class="size-3 fill-amber-500" /></div></div>
                  <span class="text-[13px] font-medium text-foreground">5-Star Header</span>
                  <span class="text-[11px] text-muted-foreground mt-0.5">Classic gold stars</span>
                </button>
                <button type="button" class="flex flex-col items-center justify-center p-3.5 rounded-xl border transition-all text-center cursor-pointer" :class="qrFrame === 'simple' ? 'border-primary bg-primary/5 ring-1 ring-primary/30' : 'border-border/80 bg-background hover:border-border hover:bg-muted/30'" @click="selectQrFrame('simple')">
                  <div class="h-8 w-full flex items-center justify-center mb-1.5"><QrCode class="size-5 text-muted-foreground" /></div>
                  <span class="text-[13px] font-medium text-foreground">Minimalist QR</span>
                  <span class="text-[11px] text-muted-foreground mt-0.5">Clean stand with URL</span>
                </button>
              </div>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <div class="flex flex-col gap-1.5"><label class="text-[13.5px] font-medium text-foreground">QR Call-To-Action Text</label><input v-model="qrTitle" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30" /></div>
              <div class="flex flex-col gap-1.5"><label class="text-[13.5px] font-medium text-foreground">Sub-text</label><input v-model="qrSubtitle" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30" /></div>
            </div>
            <div class="flex items-center justify-between p-4 bg-muted/20 rounded-xl border border-border/80">
              <div><div class="text-[13.5px] font-medium text-foreground">Center Brand Icon</div><div class="text-[12.5px] text-muted-foreground mt-0.5">Embed your company brand icon in the center of the QR matrix</div></div>
              <RelaySwitch v-model="includeLogo" />
            </div>
          </div>

          <!-- Stand mockup -->
          <div class="lg:col-span-4 bg-muted/40 rounded-2xl border border-border p-5 shadow-xs flex flex-col items-center space-y-4 relative overflow-hidden min-h-[460px]">
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="w-full flex items-center justify-between pb-3 border-b border-border/80 z-10">
              <span class="text-[13px] font-medium text-foreground">Stand Mockup</span>
              <span class="text-[11px] font-medium px-2 py-0.5 rounded-md bg-muted text-muted-foreground">300 DPI Vector</span>
            </div>
            <div class="w-full max-w-[240px] bg-card border border-border rounded-2xl p-5 shadow-md flex flex-col items-center text-center space-y-3.5 z-10">
              <div v-if="qrFrame === 'badge'" class="space-y-1.5 w-full flex flex-col items-center">
                <div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-muted/80 border border-border/80 text-[10.5px] font-semibold text-foreground"><Star class="size-3 text-amber-500 fill-amber-500" /><span>Rated 5.0 on Google</span></div>
                <div class="text-[13px] font-bold text-foreground leading-tight">{{ qrTitle }}</div>
                <div v-if="qrSubtitle" class="text-[11px] text-muted-foreground">{{ qrSubtitle }}</div>
              </div>
              <div v-else-if="qrFrame === 'stars'" class="space-y-1 w-full flex flex-col items-center">
                <div class="flex items-center justify-center gap-1 text-amber-500"><Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-500" /></div>
                <div class="text-[13px] font-bold text-foreground leading-tight">{{ qrTitle }}</div>
                <div v-if="qrSubtitle" class="text-[11px] text-muted-foreground">{{ qrSubtitle }}</div>
              </div>
              <div v-else class="space-y-0.5 w-full flex flex-col items-center pt-0.5">
                <div class="text-[12.5px] font-semibold text-foreground leading-tight">{{ qrTitle }}</div>
                <div v-if="qrSubtitle" class="text-[10.5px] text-muted-foreground">{{ qrSubtitle }}</div>
              </div>
              <div class="size-36 bg-card p-2.5 rounded-xl border border-border shadow-xs flex items-center justify-center relative">
                <svg viewBox="0 0 100 100" class="size-full text-foreground fill-current">
                  <path d="M5 5h30v30H5V5zm5 5v20h20V10H10z"/><path d="M15 15h10v10H15V15z"/><path d="M65 5h30v30H65V5zm5 5v20h20V10H70z"/><path d="M75 15h10v10H75V15z"/><path d="M5 65h30v30H5V65zm5 5v20h20V70H10z"/><path d="M15 75h10v10H15V75z"/>
                  <path d="M45 10h10v10H45zm0 20h10v10H45zm15 15h10v10H60zm-20 0h10v10H40zm25 15h10v10H65zm15 0h10v10H80zm-40 20h10v10H40zm20 0h10v10H60zm20 0h10v10H80zm0-40h10v10H80zm-35 20h10v10H45z"/>
                </svg>
                <div v-if="includeLogo" class="absolute size-7 rounded-full bg-primary text-primary-foreground flex items-center justify-center shadow-md"><Star class="size-3.5 fill-current" /></div>
              </div>
              <div class="text-[11px] font-mono text-muted-foreground truncate w-full">relay.to/r/{{ customSlug }}</div>
            </div>
            <div class="w-full space-y-2 pt-1 z-10">
              <div class="grid grid-cols-2 gap-2">
                <button class="h-9 rounded-md border border-border bg-background hover:bg-muted text-[12px] font-medium inline-flex items-center justify-center gap-1.5 cursor-pointer" @click="downloadQrCode"><Download class="size-3.5 text-primary" /> PNG</button>
                <button class="h-9 rounded-md border border-border bg-background hover:bg-muted text-[12px] font-medium inline-flex items-center justify-center gap-1.5 cursor-pointer" @click="downloadQrCode"><Download class="size-3.5 text-primary" /> SVG</button>
              </div>
              <button class="w-full h-9 rounded-md bg-primary text-primary-foreground text-[12.5px] font-medium inline-flex items-center justify-center gap-1.5 cursor-pointer hover:bg-primary/90" @click="downloadQrCode">
                <Check v-if="isQrDownloaded" class="size-3.5" /><Printer v-else class="size-3.5" /> {{ isQrDownloaded ? 'Downloaded' : 'Print Signage (PDF)' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- ================= TAB 3: RELAY AI AUTOMATIONS ================= -->
      <div v-else-if="activeTab === 'ai_outreach'">
        <div class="bg-card rounded-2xl border border-border p-6 sm:p-7 shadow-xs space-y-6">
          <div class="flex items-center justify-between p-5 bg-muted/20 rounded-xl border border-border/80">
            <div class="flex items-center gap-3">
              <div class="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center"><Bot class="size-5" /></div>
              <div class="space-y-0.5">
                <h3 class="text-[14.5px] font-semibold text-foreground">Enable Auto-Reply with Relay AI</h3>
                <p class="text-[12.5px] text-muted-foreground">Instantly draft and publish responses based on customer reviews</p>
              </div>
            </div>
            <RelaySwitch v-model="aiSettings.enableAutoReply" />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[11.5px] font-semibold text-muted-foreground uppercase tracking-wider">Minimum Rating to Auto-Reply</label>
            <select v-model="aiSettings.minRating" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer"><option v-for="opt in ratingOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option></select>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[11.5px] font-semibold text-muted-foreground uppercase tracking-wider">Custom AI Instructions</label>
            <textarea v-model="aiSettings.customInstructions" rows="4" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
          </div>
          <div class="flex items-center justify-end pt-3 border-t border-border">
            <button class="h-9 px-4 rounded-md bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer hover:bg-primary/90" @click="saveAiConfig"><Check v-if="isAiSaved" class="size-4" /><Sparkles v-else class="size-4" /> {{ isAiSaved ? 'Saved' : 'Save AI Config' }}</button>
          </div>
        </div>
      </div>

      <!-- ================= TAB 4: SPAM & PROTECTION SHIELD ================= -->
      <div v-else>
        <div class="bg-card rounded-2xl border border-border p-6 sm:p-7 shadow-xs space-y-6">
          <div class="pb-3.5 border-b border-border">
            <h2 class="text-[15px] font-semibold text-foreground">Spam Reviews Filters</h2>
            <p class="text-[12.5px] text-muted-foreground mt-0.5">Automatically identify and isolate low rating or fake feedback</p>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[11.5px] font-semibold text-muted-foreground uppercase tracking-wider">Auto-Flag Ratings Under</label>
            <select v-model="spamSettings.autoFlagRating" class="h-10 px-3 text-sm rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer"><option v-for="opt in autoFlagOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option></select>
            <p class="text-[12px] text-muted-foreground">Flagged reviews will be marked as isolated and pending manual validation before public publishing.</p>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[11.5px] font-semibold text-muted-foreground uppercase tracking-wider">Blocklist Keywords</label>
            <textarea v-model="spamSettings.blocklistKeywords" rows="3" placeholder="scam, fake, competitor…" class="w-full text-[13.5px] p-3.5 rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
            <p class="text-[12px] text-muted-foreground">Comma-separated list of terms. Reviews containing these keywords are auto-marked as spam.</p>
          </div>
          <div class="flex items-center justify-end pt-3 border-t border-border">
            <button class="h-9 px-4 rounded-md bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer hover:bg-primary/90" @click="saveSpamConfig"><Check v-if="isSpamSaved" class="size-4" /><ShieldCheck v-else class="size-4" /> {{ isSpamSaved ? 'Saved' : 'Save Spam Config' }}</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
