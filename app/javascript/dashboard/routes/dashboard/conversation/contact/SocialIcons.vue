<script>
export default {
  props: {
    socialProfiles: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      socialMediaLinks: [
        {
          key: 'facebook',
          icon: 'i-ri-facebook-circle-fill',
          link: 'https://facebook.com/',
        },
        {
          key: 'twitter',
          icon: 'i-ri-twitter-x-line',
          link: 'https://twitter.com/',
        },
        {
          key: 'linkedin',
          icon: 'i-ri-linkedin-box-fill',
          link: 'https://linkedin.com/',
        },
        {
          key: 'github',
          icon: 'i-ri-github-fill',
          link: 'https://github.com/',
        },
        {
          key: 'instagram',
          icon: 'i-ri-instagram-line',
          link: 'https://instagram.com/',
        },
        { key: 'telegram', icon: 'i-ri-telegram-fill', link: 'https://t.me/' },
        {
          key: 'tiktok',
          icon: 'i-ri-tiktok-fill',
          link: 'https://tiktok.com/@',
        },
      ],
    };
  },
  computed: {
    availableProfiles() {
      return this.socialMediaLinks.filter(
        mediaLink => !!this.socialProfiles[mediaLink.key]
      );
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="availableProfiles.length"
    class="flex flex-wrap items-center gap-3"
  >
    <a
      v-for="profile in availableProfiles"
      :key="profile.key"
      :href="`${profile.link}${socialProfiles[profile.key]}`"
      target="_blank"
      rel="noopener noreferrer nofollow"
      class="flex items-center justify-center p-1.5 rounded-md hover:bg-muted/50 transition-colors"
      :title="profile.key"
    >
      <span
        class="size-[18px] text-muted-foreground hover:text-foreground transition-colors"
        :class="[profile.icon]"
      />
    </a>
  </div>
</template>
