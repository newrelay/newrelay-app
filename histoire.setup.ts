import { createI18n } from 'vue-i18n';
import i18nMessages from 'dashboard/i18n';
import './app/javascript/design-system/histoire.scss';

export function setupVue3({ app }) {
  const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages: i18nMessages,
  });
  app.use(i18n);
}
