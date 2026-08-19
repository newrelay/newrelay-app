import axios from 'axios';

class ArticlesAPI {
  constructor() {
    this.baseUrl = '';
  }

  searchArticles(portalSlug, locale, query) {
    const { customDomain } = window.portalConfig || {};
    const isCustomDomain = customDomain && customDomain.length > 0;
    const path = isCustomDomain
      ? `${this.baseUrl}/${locale}/articles.json?query=${encodeURIComponent(query)}`
      : `${this.baseUrl}/hc/${portalSlug}/${locale}/articles.json?query=${encodeURIComponent(query)}`;
    return axios.get(path);
  }
}

export default new ArticlesAPI();
