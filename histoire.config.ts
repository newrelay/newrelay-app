import { defineConfig } from 'histoire';
import { HstVue } from '@histoire/plugin-vue';
// eslint-disable-next-line no-unused-vars
import { aliases } from './vite.shared';

export default defineConfig({
  setupFile: './histoire.setup.ts',
  plugins: [HstVue()],
  storyMatch: ['**/*.story.vue'],
  collectMaxThreads: 4,
  vite: {
    server: {
      port: 6179,
    },
    resolve: {
      alias: {
        ...aliases,
        '@sentry/vue': '@sentry/vue/build/esm/index.js',
      },
    },
  },
  viteIgnorePlugins: ['vite-plugin-ruby'],
  theme: {
    darkClass: 'dark',
    title: '@chatwoot/design',
    logo: {
      square: './design-system/images/logo-thumbnail.svg',
      light: './design-system/images/logo.png',
      dark: './design-system/images/logo-dark.png',
    },
  },
  defaultStoryProps: {
    icon: 'carbon:cube',
    iconColor: '#1F93FF',
    layout: {
      type: 'grid',
      width: '80%',
    },
  },
  tree: {
    file: 'title',
    order: 'asc',
  },
});
