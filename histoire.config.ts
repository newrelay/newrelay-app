import { createRequire } from 'node:module';
import { defineConfig } from 'histoire';
import { HstVue } from '@histoire/plugin-vue';
// eslint-disable-next-line no-unused-vars
import { aliases } from './vite.shared';

const require = createRequire(import.meta.url);

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
        // vite-node's SSR resolver mishandles @sentry/vue's "exports" map
        // (ERR_UNSUPPORTED_DIR_IMPORT during story collection); aliasing to
        // the resolved file sidesteps its subpath resolution entirely.
        '@sentry/vue': require.resolve('@sentry/vue'),
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
