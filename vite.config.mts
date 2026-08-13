import { defineConfig, loadEnv } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';
import compression from 'vite-plugin-compression';

import { handleMockRequest } from './app/javascript/mocks/mockHandlers.js';

function mockApiPlugin() {
  return {
    name: 'vite-mock-api-plugin',
    configureServer(server: any) {
      server.middlewares.use((req: any, res: any, next: any) => {
        if (process.env.MOCK_API === 'true' && req.url && (req.url.startsWith('/api') || req.url.startsWith('/auth'))) {
          const mockResponse = handleMockRequest(req.url, req.method || 'GET');
          if (mockResponse) {
            res.statusCode = mockResponse.status;
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('access-token', 'mock-token-123');
            res.setHeader('client', 'mock-client-456');
            res.setHeader('uid', 'john.doe@example.com');
            res.setHeader('expiry', '9999999999');
            res.end(JSON.stringify(mockResponse.data));
            return;
          }
        }
        next();
      });
    },
  };
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const isStandaloneUI = env.STANDALONE_UI === 'true' || process.env.STANDALONE_UI === 'true';
  const isMockAPI = env.MOCK_API === 'true' || process.env.MOCK_API === 'true';
  const backendTarget = env.BACKEND_URL || process.env.BACKEND_URL || 'http://localhost:3000';

  return {
    plugins: [
      ...(isMockAPI ? [mockApiPlugin()] : []),
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
