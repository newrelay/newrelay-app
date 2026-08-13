import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig, loadEnv, type Plugin } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';
import compression from 'vite-plugin-compression';

import { handleMockRequest } from './app/javascript/mocks/mockHandlers.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PROXY_PATH_PREFIXES = [
  '/api',
  '/auth',
  '/rails',
  '/enterprise',
  '/platform',
  '/public',
  '/resend_confirmation',
  '/hc',
  '/swagger',
  '/super_admin',
  '/installation',
  '/brand-assets',
  '/uploads',
  '/cable',
];

const ASSET_EXTENSION =
  /\.(js|mjs|css|map|svg|png|jpe?g|gif|webp|ico|woff2?|ttf|eot|json|txt|xml|wasm|vue)$/i;

function isAuthShellPath(pathname: string): boolean {
  return (
    pathname === '/app/login' ||
    pathname.startsWith('/app/login/') ||
    pathname.startsWith('/app/auth/')
  );
}

function shouldBypassHtmlRouter(pathname: string): boolean {
  if (!pathname || pathname === '/login.html' || pathname === '/index.html') {
    return true;
  }

  if (
    pathname.startsWith('/@') ||
    pathname.startsWith('/__') ||
    pathname.startsWith('/node_modules')
  ) {
    return true;
  }

  if (pathname.startsWith('/app/javascript')) {
    return true;
  }

  if (
    PROXY_PATH_PREFIXES.some(
      prefix => pathname === prefix || pathname.startsWith(`${prefix}/`)
    )
  ) {
    return true;
  }

  if (ASSET_EXTENSION.test(pathname)) {
    return true;
  }

  return false;
}

/** Route /app/login and /app/auth/* to login.html (v3app); everything else to index.html (dashboard). */
function standaloneHtmlRouterPlugin(): Plugin {
  return {
    name: 'standalone-html-router',
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (req.method !== 'GET' && req.method !== 'HEAD') {
          next();
          return;
        }

        const rawUrl = req.url ?? '/';
        const queryIndex = rawUrl.indexOf('?');
        const pathname =
          queryIndex === -1 ? rawUrl : rawUrl.slice(0, queryIndex);
        const search = queryIndex === -1 ? '' : rawUrl.slice(queryIndex);

        if (shouldBypassHtmlRouter(pathname)) {
          next();
          return;
        }

        const accept = req.headers.accept ?? '';
        const wantsHtml =
          accept.includes('text/html') || accept.includes('*/*') || !accept;

        if (!wantsHtml) {
          next();
          return;
        }

        const shell = isAuthShellPath(pathname) ? '/login.html' : '/index.html';
        req.url = `${shell}${search}`;
        next();
      });
    },
  };
}

function mockApiPlugin() {
  return {
    name: 'vite-mock-api-plugin',
    // Seed a fake auth cookie so mock mode skips the login page. This plugin
    // is only registered when MOCK_API=true, so server mode never seeds it.
    transformIndexHtml() {
      return [
        {
          tag: 'script',
          injectTo: 'head-prepend' as const,
          children: `if (!document.cookie.includes('cw_d_session_info')) {
  document.cookie = 'cw_d_session_info=' + encodeURIComponent(JSON.stringify({
    'access-token': 'mock-access-token', 'client': 'mock-client',
    'uid': 'john.doe@example.com', 'expiry': '9999999999'
  })) + '; path=/; max-age=31536000';
}`,
        },
      ];
    },
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

  // Rewrite Set-Cookie domains to localhost so auth cookies from a remote
  // backend (e.g. https://app.newrelay.com) stick during standalone UI dev.
  const proxyEntry = {
    target: backendTarget,
    changeOrigin: true,
    secure: false,
    cookieDomainRewrite: 'localhost',
  };
  const proxy = Object.fromEntries(
    [
      '/api',
      '/auth',
      '/rails',
      '/enterprise',
      '/platform',
      '/public',
      '/resend_confirmation',
      '/hc',
      '/swagger',
      '/super_admin',
      '/installation',
      '/brand-assets',
      '/uploads',
    ].map(path => [path, proxyEntry])
  );
  proxy['/cable'] = { ...proxyEntry, ws: true };

  return {
    ...(isStandaloneUI
      ? {
          appType: 'mpa' as const,
          build: {
            rollupOptions: {
              input: {
                main: path.resolve(__dirname, 'index.html'),
                login: path.resolve(__dirname, 'login.html'),
              },
            },
          },
        }
      : {}),
    plugins: [
      ...(isStandaloneUI ? [standaloneHtmlRouterPlugin()] : []),
      ...(isMockAPI ? [mockApiPlugin()] : []),
      ...(isStandaloneUI ? [] : [ruby()]),
      vue(vueOptions),
      yaml(),
      compression({ algorithm: 'gzip' }),
      compression({ algorithm: 'brotliCompress', ext: '.br' }),
    ],
    server: {
      port: 5173,
      proxy,
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
