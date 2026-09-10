export const GOOGLE_ICON_SVG = `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>`;

const platform = partial => ({
  connected: false,
  autoSync: false,
  autoReply: false,
  isComingSoon: false,
  ...partial,
});

export const reputationPlatformCatalog = () => [
  platform({
    id: 'google',
    name: 'Google',
    niches: ['local_search'],
    nicheLabel: 'Local & Search',
    description:
      'Connect with Google Business Profile to sync Google Maps ratings, customer reviews, and automate Relay AI responses.',
    tag: '✓ Popular',
    tagVariant: 'emerald',
    autoSync: true,
    autoReply: true,
    iconSvg: GOOGLE_ICON_SVG,
  }),
  platform({
    id: 'yelp',
    name: 'Yelp',
    niches: ['local_search', 'home_services'],
    nicheLabel: 'Local & Services',
    description:
      'Monitor Yelp local ratings, pull customer feedback in real time, and trigger notifications when mixed sentiment is detected.',
    tag: '✓ Easy setup',
    tagVariant: 'emerald',
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#E00707] fill-current" xmlns="http://www.w3.org/2000/svg"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>`,
  }),
  platform({
    id: 'trustpilot',
    name: 'Trustpilot',
    niches: ['ecommerce', 'b2b_software'],
    nicheLabel: 'E-Commerce & B2B',
    description:
      'Sync verified customer reviews, monitor your TrustScore badge, and direct post-purchase reviewers to your official Trustpilot portal.',
    tag: '✓ Recommended',
    tagVariant: 'primary',
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="4"/><path d="M12 4.2l2.4 5 5.5.8-4 3.9 1 5.5-4.9-2.6-4.9 2.6 1-5.5-4-3.9 5.5-.8 2.4-5z" fill="#FFF"/></svg>`,
  }),
  platform({
    id: 'facebook',
    name: 'Facebook',
    niches: ['local_search'],
    nicheLabel: 'Social & Local',
    description:
      'Aggregate Facebook recommendations, post replies from this workspace, and display verified social proof on your landing pages.',
    tag: '✓ Popular',
    tagVariant: 'emerald',
    autoSync: true,
    autoReply: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#1877F2] fill-current" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>`,
  }),
  platform({
    id: 'tripadvisor',
    name: 'TripAdvisor',
    niches: ['hospitality'],
    nicheLabel: 'Hospitality & Travel',
    description:
      'Collect and manage hospitality, dining, and venue traveler feedback with automatic ranking and traveler score insights.',
    tag: '✓ Easy setup',
    tagVariant: 'emerald',
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#00AF87] fill-current" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="10" fill="#00AF87"/><circle cx="8" cy="12" r="2.5" fill="#FFF"/><circle cx="16" cy="12" r="2.5" fill="#FFF"/><circle cx="8" cy="12" r="1.2" fill="#000"/><circle cx="16" cy="12" r="1.2" fill="#000"/></svg>`,
  }),
  platform({
    id: 'apple_maps',
    name: 'Apple Maps',
    niches: ['local_search'],
    nicheLabel: 'Local & Search',
    description:
      'Publish verified business details, showcase photos, and sync ratings from millions of iOS Apple Maps and Spotlight users.',
    tag: '• Beta',
    tagVariant: 'amber',
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 fill-current text-foreground" xmlns="http://www.w3.org/2000/svg"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.87c.66-.81 1.11-1.94.99-3.07-1 .04-2.16.67-2.82 1.48-.58.67-1.1 1.82-.96 2.93 1.12.09 2.19-.58 2.79-1.34z"/></svg>`,
  }),
  platform({
    id: 'amazon',
    name: 'Amazon',
    niches: ['ecommerce'],
    nicheLabel: 'E-Commerce & Retail',
    description:
      'Aggregate verified Amazon buyer ratings, monitor product feedback, and sync seller performance metrics.',
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#FF9900] fill-current" xmlns="http://www.w3.org/2000/svg"><path d="M13.9 14.5c-2.3 1.7-5.7 2.6-8.6 2.6-4.1 0-7.8-1.5-10.6-4-.2-.2 0-.5.2-.3 3 1.8 6.7 2.8 10.4 2.8 2.6 0 5.4-.6 8-1.7.4-.2.8.2.6.6zM22.8 17.6c-.3-.4-1.9-.2-2.9 0-.3.1-.3-.2-.1-.4 1.3-1.1 2.9-.8 3.2-.4.3.4-.1 2.3-1.4 3.4-.2.2-.4.1-.3-.1.5-.7 1.8-2.1 1.5-2.5z"/><path d="M14.7 10.9c0-1.8-1.1-2.9-2.9-2.9-1.5 0-2.8.9-3.1 2.3-.1.4.2.5.5.5.7 0 1.2-.5 1.7-.8.5-.3 1-.4 1.6-.4.9 0 1.3.5 1.3 1.4v.3c-2.8.2-4.5 1.2-4.5 3 0 1.5 1.1 2.4 2.5 2.4 1.3 0 2.2-.6 2.6-1.5h.1v1.2c0 .3.2.5.5.5h.8c.3 0 .5-.2.5-.5v-5.5z"/></svg>`,
  }),
  platform({
    id: 'g2',
    name: 'G2',
    niches: ['b2b_software'],
    nicheLabel: 'B2B & SaaS Software',
    description:
      'Collect verified B2B customer reviews on G2, track grid quadrant ranking, and syndicate buyer badges.',
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#FF492C"/><path d="M12 6c-3.3 0-6 2.7-6 6s2.7 6 6 6c2.5 0 4.6-1.5 5.5-3.7.1-.3-.1-.6-.4-.6h-1.8c-.2 0-.4.1-.5.3-.6 1.2-1.7 2-3 2-1.9 0-3.5-1.4-3.8-3.3h9.4c.3 0 .5-.2.5-.5 0-3.3-2.6-5.9-5.9-5.9zm-3.8 5c.3-1.9 1.9-3.3 3.8-3.3s3.5 1.4 3.8 3.3H8.2z" fill="#FFF"/></svg>`,
  }),
  platform({
    id: 'capterra',
    name: 'Capterra',
    niches: ['b2b_software'],
    nicheLabel: 'B2B & Software',
    description:
      'Sync vendor ratings and buyer testimonials from Gartner Capterra and GetApp software directories.',
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#003B5C"/><path d="M7 16l5-8 5 8h-3l-2-3.5L10 16H7z" fill="#FF6B4A"/></svg>`,
  }),
  platform({
    id: 'bbb',
    name: 'BBB',
    niches: ['local_search', 'home_services'],
    nicheLabel: 'Accredited Business',
    description:
      'Monitor accredited business ratings, customer complaints, and official BBB trust seal verification.',
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#005A9C"/><text x="50%" y="65%" text-anchor="middle" fill="#FFF" font-family="sans-serif" font-weight="bold" font-size="9">BBB</text></svg>`,
  }),
  platform({
    id: 'angi',
    name: 'Angi',
    niches: ['home_services'],
    nicheLabel: 'Home & Trade Services',
    description:
      'Sync certified homeowner and contractor reviews from Angi and HomeAdvisor service networks.',
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="4" fill="#00B074"/><path d="M12 5l6 14h-3.2l-1.3-3.2H10.5L9.2 19H6l6-14zm0 4.5L11.2 13h1.6L12 9.5z" fill="#FFF"/></svg>`,
  }),
  platform({
    id: 'opentable',
    name: 'OpenTable',
    niches: ['hospitality'],
    nicheLabel: 'Hospitality & Dining',
    description:
      'Gather verified post-meal diner ratings and reservation feedback directly from OpenTable.',
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="10" fill="#DA3743"/><circle cx="12" cy="12" r="4.5" fill="#FFF"/><circle cx="17" cy="12" r="2" fill="#FFF"/></svg>`,
  }),
];
