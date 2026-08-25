<script setup>
import { ref, computed } from 'vue';
import 'highlight.js/styles/default.css';
import 'highlight.js/lib/common';
import { RelayButton } from 'dashboard/components-next/relay';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  script: {
    type: String,
    default: '',
  },
  lang: {
    type: String,
    default: 'javascript',
  },
  enableCodePen: {
    type: Boolean,
    default: false,
  },
  codepenTitle: {
    type: String,
    default: 'Chatwoot Codepen',
  },
});

const { t } = useI18n();
const isCopied = ref(false);

const buttonLabel = computed(() => {
  return isCopied.value ? 'Copied!' : t('COMPONENTS.CODE.BUTTON_TEXT');
});

const scrubbedScript = computed(() => {
  // remove trailing and leading extra lines and not spaces
  const scrubbed = props.script.replace(/^\s*[\r\n]/gm, '');
  const lines = scrubbed.split('\n');

  // remove extra indentations
  const minIndent = lines.reduce((min, line) => {
    if (line.trim().length === 0) return min;
    const indent = line.match(/^\s*/)[0].length;
    return Math.min(min, indent);
  }, Infinity);

  return lines.map(line => line.slice(minIndent)).join('\n');
});

const codepenScriptValue = computed(() => {
  const lang = props.lang === 'javascript' ? 'js' : props.lang;
  return JSON.stringify({
    title: props.codepenTitle,
    private: true,
    [lang]: scrubbedScript.value,
  });
});

const onCopy = async e => {
  e.preventDefault();
  await copyTextToClipboard(scrubbedScript.value);
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL') || 'Code Copied.');
  isCopied.value = true;
  setTimeout(() => {
    isCopied.value = false;
  }, 2500);
};
</script>

<template>
  <div
    class="relative overflow-hidden rounded-lg border border-border/60 bg-muted/40 text-left shadow-xs"
  >
    <div
      class="absolute end-1.5 top-1.5 z-10 flex items-center gap-1 rounded-md bg-background/80 p-0.5 backdrop-blur-sm"
    >
      <form
        v-if="enableCodePen"
        class="flex items-center"
        action="https://codepen.io/pen/define"
        method="POST"
        target="_blank"
      >
        <input type="hidden" name="data" :value="codepenScriptValue" />
        <RelayButton
          type="submit"
          variant="outline"
          size="sm"
          class="h-7 border-border px-2.5 text-[12px]"
        >
          {{ t('COMPONENTS.CODE.CODEPEN') }}
        </RelayButton>
      </form>
      <RelayButton
        type="button"
        variant="outline"
        size="sm"
        class="h-7 border-border px-2.5 text-[12px]"
        @click="onCopy"
      >
        {{ buttonLabel }}
      </RelayButton>
    </div>
    <highlightjs
      v-if="script"
      :language="lang"
      :code="scrubbedScript"
      class="[&_code]:text-start [&_pre]:m-0"
    />
  </div>
</template>
