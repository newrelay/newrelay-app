<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import { extractResponseMessage } from 'shared/helpers/CustomErrors';

const { t } = useI18n();
const { accountId, accountScopedRoute } = useAccount();

const commenterName = ref('You');
const commentText = ref('What is the PRICE on this?');
const sending = ref(false);
const error = ref('');
const thread = ref([]);

const canSend = computed(
  () => commentText.value.trim() && commenterName.value.trim() && !sending.value
);

async function postComment() {
  if (!canSend.value) return;
  sending.value = true;
  error.value = '';
  const text = commentText.value.trim();
  const name = commenterName.value.trim();
  try {
    const { data } = await window.axios.post(
      `/api/v1/accounts/${accountId.value}/comment_automation/mock_comment`,
      { text, name }
    );
    thread.value.push({
      id: `${Date.now()}-you`,
      name,
      text,
      kind: 'comment',
    });
    if (data.matched) {
      thread.value.push({
        id: `${Date.now()}-reply`,
        name: t('AUTORESPONDER.MOCK_POST.PUBLIC_REPLY'),
        text: data.public_reply,
        kind: 'reply',
      });
      thread.value.push({
        id: `${Date.now()}-dm`,
        name: t('AUTORESPONDER.MOCK_POST.DM'),
        text: data.dm,
        kind: 'dm',
      });
    } else {
      thread.value.push({
        id: `${Date.now()}-nomatch`,
        name: '',
        text: t('AUTORESPONDER.MOCK_POST.NO_MATCH'),
        kind: 'nomatch',
      });
    }
    commentText.value = '';
  } catch (err) {
    error.value =
      extractResponseMessage(err) || t('AUTORESPONDER.MOCK_POST.NOT_CONNECTED');
  } finally {
    sending.value = false;
  }
}
</script>

<template>
  <div class="h-[calc(100vh-80px)] overflow-y-auto bg-muted/20 p-6 md:p-8">
    <div class="max-w-[480px] mx-auto flex flex-col gap-6">
      <div>
        <h1 class="text-base font-medium text-foreground">
          {{ t('AUTORESPONDER.MOCK_POST.TITLE') }}
        </h1>
        <p class="text-sm text-muted-foreground mt-1">
          {{ t('AUTORESPONDER.MOCK_POST.SUBTITLE') }}
        </p>
      </div>

      <div
        class="bg-card border border-border rounded-xl overflow-hidden shadow-sm"
      >
        <div
          class="aspect-square bg-muted flex items-center justify-center border-b border-border"
        >
          <span class="i-lucide-image size-12 text-muted-foreground" />
        </div>
        <div class="p-4 flex flex-col gap-3 max-h-[320px] overflow-y-auto">
          <p v-if="!thread.length" class="text-[13px] text-muted-foreground">
            {{ t('AUTORESPONDER.MOCK_POST.HINT') }}
          </p>
          <div
            v-for="item in thread"
            :key="item.id"
            class="flex flex-col gap-0.5"
          >
            <span
              v-if="item.name"
              class="text-[12px] font-medium text-foreground"
            >
              {{ item.name }}
            </span>
            <p
              class="text-[13px] leading-relaxed"
              :class="
                item.kind === 'dm'
                  ? 'text-primary'
                  : item.kind === 'nomatch'
                    ? 'text-muted-foreground'
                    : 'text-foreground'
              "
            >
              {{ item.text }}
            </p>
          </div>
        </div>
        <form
          class="p-4 border-t border-border flex flex-col gap-3"
          @submit.prevent="postComment"
        >
          <div class="flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('AUTORESPONDER.MOCK_POST.NAME_LABEL') }}
            </RelayLabel>
            <RelayInput
              v-model="commenterName"
              :placeholder="t('AUTORESPONDER.MOCK_POST.NAME_PLACEHOLDER')"
            />
          </div>
          <div class="flex gap-2">
            <RelayInput
              v-model="commentText"
              class="flex-1"
              :placeholder="t('AUTORESPONDER.MOCK_POST.PLACEHOLDER')"
            />
            <RelayButton type="submit" :disabled="!canSend">
              {{
                sending
                  ? t('AUTORESPONDER.MOCK_POST.SENDING')
                  : t('AUTORESPONDER.MOCK_POST.SEND')
              }}
            </RelayButton>
          </div>
          <p v-if="error" class="text-[13px] text-destructive">
            {{ error }}
          </p>
          <RelayButton
            v-if="error"
            as="router-link"
            :to="accountScopedRoute('autoresponder_settings')"
            variant="outline"
            class="border border-border hover:border-transparent w-fit"
          >
            {{ t('AUTORESPONDER.MOCK_POST.CONNECT') }}
          </RelayButton>
        </form>
      </div>
    </div>
  </div>
</template>
