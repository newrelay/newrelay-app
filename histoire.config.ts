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
        // Vue's bundler build re-exports its API via a multi-package-deep
        // `export * from` chain (vue -> @vue/runtime-dom ->
        // @vue/runtime-core). Vite's SSR export analysis doesn't reliably
        // resolve wildcard re-exports across that many package boundaries,
        // so named imports like `ref`/`mergeModels` come back undefined at
        // render time during story collection. The self-contained browser
        // build lists every export explicitly in one file, sidestepping it.
        vue: require.resolve('vue/dist/vue.runtime.esm-browser.js'),
      },
    },
    // Without this, Vite's dep-optimizer pre-bundles 'vue' into its own
    // esbuild chunk (used by the live preview server), which is a SEPARATE
    // module instance from the one story collection's SSR run loads via
    // the alias above. Vue keeps module-scoped render state (e.g. the
    // "current rendering instance" used by renderSlot); mixing two
    // instances means that state is null where the other instance expects
    // it, crashing render with "Cannot read properties of null". Excluding
    // 'vue' forces every consumer to resolve the same literal file.
    optimizeDeps: {
      exclude: ['vue'],
    },
  },
  // vite-node@0.34's fallbackCJS heuristic (hardcoded on by histoire's
  // collector, see @histoire/... collect/index.js) has a bug: its /esm/
  // folder regex replacement drops the matched filename, turning e.g.
  // "@babel/runtime/helpers/esm/typeof.js" into ".../helpers/esm" (a
  // directory Node can't resolve via the package's exports map). This hits
  // any dependency with an esm/ subfolder (@babel/runtime, @twilio/voice-sdk,
  // ...), which is common enough to break collection for most story files.
  // Inlining anything matching vite-node's own /esm/ pattern skips the
  // buggy guess entirely (inline deps are checked before it runs).
  viteNodeInlineDeps: [/\/(es|esm)\/.*\.js$/],
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
