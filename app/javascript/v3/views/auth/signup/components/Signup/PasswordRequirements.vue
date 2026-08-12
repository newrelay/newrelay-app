<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  password: { type: String, default: '' },
});
const MIN_PASSWORD_LENGTH = 6;
const SPECIAL_CHAR_REGEX = /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/;

const { t } = useI18n();

const requirements = computed(() => {
  const password = props.password || '';
  return [
    {
      id: 'length',
      met: password.length >= MIN_PASSWORD_LENGTH,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH', {
        min: MIN_PASSWORD_LENGTH,
      }),
    },
    {
      id: 'uppercase',
      met: /[A-Z]/.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE'),
    },
    {
      id: 'lowercase',
      met: /[a-z]/.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE'),
    },
    {
      id: 'number',
      met: /[0-9]/.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER'),
    },
    {
      id: 'special',
      met: SPECIAL_CHAR_REGEX.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL'),
    },
  ];
});
</script>

<template>
  <div
    class="absolute top-full start-0 z-50 w-full mt-2 text-xs rounded-lg px-4 py-3 bg-popover text-popover-foreground border border-border shadow-lg"
  >
    <ul role="list" class="space-y-1.5">
      <li
        v-for="item in requirements"
        :key="item.id"
        class="flex gap-1.5 items-center"
      >
        <span
          class="flex-none size-3 block"
          :class="[
            item.met ? 'i-lucide-circle-check-big' : 'i-lucide-circle',
            item.met ? 'text-success' : 'text-muted-foreground',
          ]"
        />
        <span :class="item.met ? 'text-foreground' : 'text-muted-foreground'">
          {{ item.label }}
        </span>
      </li>
    </ul>
  </div>
</template>
