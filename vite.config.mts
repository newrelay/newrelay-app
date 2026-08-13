import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';
import compression from 'vite-plugin-compression';

const isStandaloneUI = process.env.STANDALONE_UI === 'true';

export default defineConfig({
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
      '/api': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/auth': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/cable': { target: process.env.BACKEND_URL || 'http://localhost:3000', ws: true, changeOrigin: true, secure: false },
      '/rails': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/enterprise': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/platform': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/public': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/resend_confirmation': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/hc': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/swagger': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/super_admin': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/installation': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/brand-assets': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
      '/uploads': { target: process.env.BACKEND_URL || 'http://localhost:3000', changeOrigin: true, secure: false },
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
});
