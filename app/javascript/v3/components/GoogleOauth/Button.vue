<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const getGoogleAuthUrl = () => {
  // Ideally a request to /auth/google_oauth2 should be made
  // Creating the URL manually because the devise-token-auth with
  // omniauth has a standing issue on redirecting the post request
  // https://github.com/lynndylanhurley/devise_token_auth/issues/1466
  const baseUrl = 'https://accounts.google.com/o/oauth2/auth';
  const clientId = window.chatwootConfig.googleOAuthClientId;
  const redirectUri = window.chatwootConfig.googleOAuthCallbackUrl;
  const responseType = 'code';
  const scope = 'email profile';

  // Build the query string
  const queryString = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: responseType,
    scope,
  }).toString();

  // Construct the full URL
  return `${baseUrl}?${queryString}`;
};
</script>

<template>
  <a
    :href="getGoogleAuthUrl()"
    class="w-full h-11 bg-background border border-border rounded-lg shadow-sm flex items-center justify-center gap-3 hover:bg-muted/50 transition-colors text-[14px] font-medium text-foreground"
  >
    <span class="i-logos-google-icon size-5" />
    <slot>{{ t('LOGIN.OAUTH.GOOGLE_LOGIN') }}</slot>
  </a>
</template>
