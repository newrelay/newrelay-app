import { defineConfig, loadEnv } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';
import compression from 'vite-plugin-compression';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const isStandaloneUI = env.STANDALONE_UI === 'true' || process.env.STANDALONE_UI === 'true';
  const backendTarget = env.BACKEND_URL || process.env.BACKEND_URL || 'http://localhost:3000';

  return {
    plugins: [
      ...(isStandaloneUI ? [] : [ruby()]),
      vue(vueOptions),
      yaml(),
      compression({ algorithm: 'gzip' }),
      compression({ algorithm: 'brotliCompress', ext: '.br' }),
    ],
    server: {
      port: 5173,
      proxy: {
        '/api': { target: backendTarget, changeOrigin: true, secure: false },
        '/auth': { target: backendTarget, changeOrigin: true, secure: false },
        '/cable': { target: backendTarget, ws: true, changeOrigin: true, secure: false },
        '/rails': { target: backendTarget, changeOrigin: true, secure: false },
        '/enterprise': { target: backendTarget, changeOrigin: true, secure: false },
        '/platform': { target: backendTarget, changeOrigin: true, secure: false },
        '/public': { target: backendTarget, changeOrigin: true, secure: false },
        '/resend_confirmation': { target: backendTarget, changeOrigin: true, secure: false },
        '/hc': { target: backendTarget, changeOrigin: true, secure: false },
        '/swagger': { target: backendTarget, changeOrigin: true, secure: false },
        '/super_admin': { target: backendTarget, changeOrigin: true, secure: false },
        '/installation': { target: backendTarget, changeOrigin: true, secure: false },
        '/brand-assets': { target: backendTarget, changeOrigin: true, secure: false },
        '/uploads': { target: backendTarget, changeOrigin: true, secure: false },
      },
    },
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
      },
    },
    resolve: { alias: aliases },
  };
});
