/// <reference types="vitest" />
import { defineConfig } from 'vitest/config';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';

export default defineConfig({
  plugins: [vue(vueOptions), yaml()],
  resolve: { alias: aliases },
  test: {
    environment: 'jsdom',
    include: ['app/**/*.{test,spec}.?(c|m)[jt]s?(x)'],
    coverage: {
      reporter: ['lcov', 'text', 'json-summary'],
      include: ['app/**/*.js', 'app/**/*.vue'],
      exclude: [
        'app/**/*.@(spec|stories|routes).js',
        '**/specs/**/*',
        '**/i18n/**/*',
      ],
      // Unset VITEST_COVERAGE_MIN = report only. Target for new critical
      // paths is 95% (docs/adr/0003).
      ...(Number(process.env.VITEST_COVERAGE_MIN) > 0
        ? {
            thresholds: {
              lines: Number(process.env.VITEST_COVERAGE_MIN),
              functions: Number(process.env.VITEST_COVERAGE_MIN),
              statements: Number(process.env.VITEST_COVERAGE_MIN),
            },
          }
        : {}),
    },
    globals: true,
    outputFile: 'coverage/sonar-report.xml',
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
      },
    },
    server: {
      deps: {
        inline: ['tinykeys', '@material/mwc-icon', 'prosemirror-state'],
      },
    },
    setupFiles: ['fake-indexeddb/auto', 'vitest.setup.js'],
    mockReset: true,
    clearMocks: true,
  },
});
