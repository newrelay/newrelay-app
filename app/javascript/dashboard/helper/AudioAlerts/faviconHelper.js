export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    if (!favicon.dataset.originalHref) {
      favicon.dataset.originalHref = favicon.getAttribute('href');
    }
    const newFileName = `/favicon-badge-${favicon.sizes[[0]]}.png`;
    favicon.href = newFileName;
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    if (!favicon.dataset.originalHref) {
      favicon.dataset.originalHref = favicon.getAttribute('href');
    }
  });

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        const oldFileName =
          favicon.dataset.originalHref || `/favicon-${favicon.sizes[[0]]}.png`;
        favicon.href = oldFileName;
      });
    }
  });
};
