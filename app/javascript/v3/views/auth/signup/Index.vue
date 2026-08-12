<script setup>
import { useI18n } from 'vue-i18n';
import AuthShell from '../../../components/auth/AuthShell.vue';
import MarketingPanel from '../../../components/auth/MarketingPanel.vue';
import SignupForm from './components/Signup/Form.vue';

const { t } = useI18n();
</script>

<template>
  <AuthShell>
    <div
      class="w-full max-w-[1000px] bg-card rounded-[2rem] shadow-xl border border-border/50 flex flex-col md:flex-row overflow-hidden relative z-10 min-h-[600px]"
    >
      <MarketingPanel />

      <!-- Signup form panel -->
      <div
        class="w-full md:w-[55%] bg-card p-10 flex flex-col relative overflow-y-auto"
      >
        <div
          class="flex-1 flex flex-col justify-center max-w-[400px] w-full mx-auto"
        >
          <div class="text-center mb-8 mt-12 md:mt-0">
            <h2 class="text-[26px] font-bold text-foreground mb-2">
              {{ t('REGISTER.TRY_WOOT') }}
            </h2>
            <p class="text-[14px] text-muted-foreground">
              {{ t('REGISTER.SUBTITLE') }}
            </p>
          </div>
          <SignupForm />
          <p class="text-center text-[14px] text-muted-foreground mt-8">
            {{ t('REGISTER.HAVE_AN_ACCOUNT') }}
            <router-link
              to="/app/login"
              class="text-primary font-medium hover:underline"
            >
              {{ t('LOGIN.SUBMIT') }}
            </router-link>
          </p>
        </div>
      </div>
    </div>
  </AuthShell>
</template>
