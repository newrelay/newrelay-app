const DEFAULT_FAVICON_COLOR = '#ff4f16';
const LOGO_SVG_PATH = '/brand-assets/logo_thumbnail.svg';

let logoSvgText;
let requestId = 0;

const isCustomFavicon = url => {
  if (!url || typeof url !== 'string') return false;
  return (
    !url.includes('logo_thumbnail.svg') &&
    !/\/favicon[^/]*\.(svg|png|ico)(\?|$)/i.test(url)
  );
};

const iconLinks = () =>
  document.querySelectorAll('link[rel="icon"], link.favicon');

const assignIcon = (link, href) => {
  const showingBadge = (link.getAttribute('href') || '').includes(
    'favicon-badge'
  );
  link.dataset.originalHref = href;
  if (!showingBadge) link.setAttribute('href', href);
};

/**
 * Point the tab icon at the active theme primary.
 * A custom uploaded favicon is left in place.
 */
export const applyThemeFavicon = color => {
  if (typeof document === 'undefined') return;
  if (!iconLinks().length) return;

  requestId += 1;
  const token = requestId;
  const primary = /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(color || '')
    ? color
    : DEFAULT_FAVICON_COLOR;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', primary);

  const custom = window.globalConfig?.LOGO_THUMBNAIL;
  if (isCustomFavicon(custom)) {
    iconLinks().forEach(link => assignIcon(link, custom));
    return;
  }

  if (primary.toLowerCase() === DEFAULT_FAVICON_COLOR) {
    iconLinks().forEach(link => assignIcon(link, LOGO_SVG_PATH));
    return;
  }

  const paint = svg => {
    if (token !== requestId) return;
    const themed = svg.replace(
      /(<rect\b[^>]*\bfill=")#[0-9a-fA-F]{3,8}(")/,
      `$1${primary}$2`
    );
    const href = `data:image/svg+xml,${encodeURIComponent(themed)}`;
    iconLinks().forEach(link => assignIcon(link, href));
  };

  if (logoSvgText) {
    paint(logoSvgText);
    return;
  }

  fetch(LOGO_SVG_PATH)
    .then(response => (response.ok ? response.text() : null))
    .then(text => {
      if (!text) return;
      logoSvgText = text;
      paint(text);
    })
    .catch(() => {});
};
