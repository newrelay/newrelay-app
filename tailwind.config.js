const { slateDark } = require('@radix-ui/colors');
import { colors } from './theme/colors';
import { icons } from './theme/icons';
const defaultTheme = require('tailwindcss/defaultTheme');
const tailwindColors = require('tailwindcss/colors');
const {
  iconsPlugin,
  getIconCollections,
} = require('@egoist/tailwindcss-icons');

const withAlpha = variable => `rgb(var(${variable}) / <alpha-value>)`;

const defaultSansFonts = [
  '-apple-system',
  'system-ui',
  'BlinkMacSystemFont',
  '"Segoe UI"',
  'Roboto',
  '"Helvetica Neue"',
  'Tahoma',
  'Arial',
  'sans-serif !important',
];

const tailwindConfig = {
  darkMode: 'class',
  content: [
    './enterprise/app/views/**/*.erb',
    './app/javascript/widget/**/*.vue',
    './app/javascript/v3/**/*.vue',
    './app/javascript/dashboard/**/*.vue',
    './app/javascript/portal/**/*.vue',
    './app/javascript/shared/**/*.vue',
    './app/javascript/survey/**/*.vue',
    './app/javascript/dashboard/components-next/**/*.vue',
    './app/javascript/dashboard/helper/**/*.js',
    './app/javascript/dashboard/composables/**/*.js',
    './app/javascript/dashboard/components-next/**/*.js',
    './app/javascript/dashboard/routes/dashboard/**/**/*.js',
    './app/views/**/*.erb',
  ],
  theme: {
    extend: {
      // Matches Tailwind v4 / shadcn `shadow-xs` (same value as TW3 `shadow-sm`)
      boxShadow: {
        xs: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
        xl: 'calc(var(--radius) + 4px)',
      },
      fontFamily: {
        sans: ['Geist', ...defaultSansFonts],
        inter: ['Inter', ...defaultSansFonts],
        interDisplay: ['InterDisplay', ...defaultSansFonts],
        // new-ui default `--font-sans`
        geist: [
          'Geist',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'sans-serif',
        ],
      },

      fontWeight: {
        420: '420',
        440: '440',
        460: '460',
        520: '520',
        620: '620',
      },
      typography: {
        bubble: {
          css: {
            // Inherit from bubble (primary-foreground on agent, card-foreground on user)
            color: 'inherit',
            lineHeight: '1.6',
            fontSize: '14px',
            '*': {
              '&:first-child': {
                marginTop: '0',
              },
            },
            overflowWrap: 'anywhere',

            strong: {
              color: 'inherit',
              fontWeight: '700',
            },

            b: {
              color: 'inherit',
              fontWeight: '700',
            },

            h1: {
              color: 'inherit',
              fontWeight: '700',
              fontSize: '1.25rem',
              '&:first-child': {
                marginTop: '0',
              },
            },
            h2: {
              color: 'inherit',
              fontWeight: '700',
              fontSize: '1rem',
              '&:first-child': {
                marginTop: '0',
              },
            },
            h3: {
              color: 'inherit',
              fontWeight: '700',
              fontSize: '1rem',
              '&:first-child': {
                marginTop: '0',
              },
            },
            hr: {
              marginTop: '1.5em',
              marginBottom: '1.5em',
            },
            a: {
              color: 'inherit',
              textDecoration: 'underline',
            },
            ul: {
              paddingInlineStart: '0',
              listStylePosition: 'inside',
            },
            ol: {
              paddingInlineStart: '0',
              listStylePosition: 'inside',
            },
            'ul > li': {
              marginBlockEnd: '0.5em',
              listStyleType: 'disc',
              paddingInlineStart: '1.5em',
              textIndent: '-1.5em',
            },
            'ol > li': {
              marginBlockEnd: '0.5em',
              listStyleType: 'decimal',
              paddingInlineStart: '1.5em',
              textIndent: '-1.5em',
            },
            'li > p:first-child': {
              display: 'inline',
            },
            'li > *': {
              textIndent: '0',
            },
            blockquote: {
              color: 'inherit',
              opacity: '0.8',
              borderLeft: `4px solid rgb(var(--black-alpha-1))`,
              paddingLeft: '1em',
              '[dir="rtl"] &': {
                borderLeft: 'none',
                paddingLeft: '0',
                borderRight: `4px solid rgb(var(--black-alpha-1))`,
                paddingRight: '1em',
              },
              '[dir="ltr"] &': {
                borderRight: 'none',
                paddingRight: '0',
              },
            },
            code: {
              backgroundColor: 'rgb(var(--alpha-3))',
              color: 'inherit',
              opacity: '0.9',
              padding: '0.2em 0.4em',
              borderRadius: '4px',
              fontSize: '0.95em',
              '&::before': {
                content: `none`,
              },
              '&::after': {
                content: `none`,
              },
            },
            pre: {
              backgroundColor: 'rgb(var(--alpha-3))',
              padding: '1em',
              borderRadius: '6px',
              overflowX: 'auto',
            },
            table: {
              width: '100%',
              borderCollapse: 'collapse',
            },
            th: {
              padding: '0.75em',
              color: 'inherit',
              border: `none`,
              textAlign: 'start',
              fontWeight: '600',
            },
            tr: {
              border: `none`,
            },
            td: {
              padding: '0.75em',
              border: `none`,
            },
            img: {
              maxWidth: '100%',
              height: 'auto',
              marginTop: 'unset',
              marginBottom: 'unset',
            },
          },
        },
      },
    },
    screens: {
      xs: '480px',
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px',
      '3xl': '1900px',
    },
    fontSize: {
      ...defaultTheme.fontSize,
      xxs: '0.625rem',
    },
    colors: {
      transparent: 'transparent',
      white: '#fff',
      'modal-backdrop-light': 'rgba(0, 0, 0, 0.4)',
      'modal-backdrop-dark': 'rgba(0, 0, 0, 0.6)',
      current: 'currentColor',
      ...colors,
      amber: tailwindColors.amber,
      emerald: tailwindColors.emerald,
      body: slateDark.slate7,
      // new-ui / shadcn tokens (see _relay-theme.scss)
      'auth-canvas': withAlpha('--auth-canvas'),
      'auth-marketing-from': withAlpha('--auth-marketing-from'),
      'auth-marketing-via': withAlpha('--auth-marketing-via'),
      'auth-marketing-to': withAlpha('--auth-marketing-to'),
      'auth-mock-panel': withAlpha('--auth-mock-panel'),
      'auth-mock-row': withAlpha('--auth-mock-row'),
      'auth-mock-border': withAlpha('--auth-mock-border'),
      'auth-mock-skeleton': withAlpha('--auth-mock-skeleton'),
      'auth-mock-chart': withAlpha('--auth-mock-chart'),
      'auth-mock-avatar-blue': withAlpha('--auth-mock-avatar-blue'),
      'auth-mock-avatar-purple': withAlpha('--auth-mock-avatar-purple'),
      background: withAlpha('--background'),
      foreground: withAlpha('--foreground'),
      card: {
        DEFAULT: withAlpha('--card'),
        foreground: withAlpha('--card-foreground'),
      },
      popover: {
        DEFAULT: withAlpha('--popover'),
        foreground: withAlpha('--popover-foreground'),
      },
      primary: {
        DEFAULT: withAlpha('--primary'),
        foreground: withAlpha('--primary-foreground'),
      },
      secondary: {
        DEFAULT: withAlpha('--secondary'),
        foreground: withAlpha('--secondary-foreground'),
      },
      muted: {
        DEFAULT: withAlpha('--muted'),
        foreground: withAlpha('--muted-foreground'),
      },
      accent: {
        DEFAULT: withAlpha('--accent'),
        foreground: withAlpha('--accent-foreground'),
      },
      destructive: {
        DEFAULT: withAlpha('--destructive'),
        foreground: withAlpha('--destructive-foreground'),
      },
      border: 'var(--border)',
      input: 'var(--input)',
      ring: withAlpha('--ring'),
      chart: {
        1: withAlpha('--chart-1'),
        2: withAlpha('--chart-2'),
        3: withAlpha('--chart-3'),
        4: withAlpha('--chart-4'),
        5: withAlpha('--chart-5'),
      },
      sidebar: {
        DEFAULT: withAlpha('--sidebar'),
        foreground: withAlpha('--sidebar-foreground'),
        primary: withAlpha('--sidebar-primary'),
        'primary-foreground': withAlpha('--sidebar-primary-foreground'),
        accent: withAlpha('--sidebar-accent'),
        'accent-foreground': withAlpha('--sidebar-accent-foreground'),
        border: 'var(--sidebar-border)',
        ring: withAlpha('--sidebar-ring'),
      },
      success: withAlpha('--success'),
      warning: withAlpha('--warning'),
      priority: {
        1: withAlpha('--priority-1'),
        2: withAlpha('--priority-2'),
        3: withAlpha('--priority-3'),
        4: withAlpha('--priority-4'),
      },
    },

    keyframes: {
      ...defaultTheme.keyframes,
      wiggle: {
        '0%': { transform: 'translateX(0)' },
        '15%': { transform: 'translateX(0.375rem)' },
        '30%': { transform: 'translateX(-0.375rem)' },
        '45%': { transform: 'translateX(0.375rem)' },
        '60%': { transform: 'translateX(-0.375rem)' },
        '75%': { transform: 'translateX(0.375rem)' },
        '90%': { transform: 'translateX(-0.375rem)' },
        '100%': { transform: 'translateX(0)' },
      },
      'fade-in-up': {
        '0%': { opacity: 0, transform: 'translateY(0.5rem)' },
        '100%': { opacity: 1, transform: 'translateY(0)' },
      },
      'loader-pulse': {
        '0%': { opacity: 0.4 },
        '50%': { opacity: 1 },
        '100%': { opacity: 0.4 },
      },
      'card-select': {
        '0%, 100%': {
          transform: 'translateX(0)',
        },
        '50%': {
          transform: 'translateX(1px)',
        },
      },
      shake: {
        '0%, 100%': { transform: 'translateX(0)' },
        '25%': { transform: 'translateX(0.234375rem)' },
        '50%': { transform: 'translateX(-0.234375rem)' },
        '75%': { transform: 'translateX(0.234375rem)' },
      },
    },
    animation: {
      ...defaultTheme.animation,
      wiggle: 'wiggle 0.5s ease-in-out',
      'fade-in-up': 'fade-in-up 0.3s ease-out',
      'loader-pulse': 'loader-pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      'card-select': 'card-select 0.25s ease-in-out',
      shake: 'shake 0.3s ease-in-out 0s 2',
    },
  },
  plugins: [
    // eslint-disable-next-line
    require('@tailwindcss/typography'),
    iconsPlugin({
      collections: {
        woot: { icons },
        ...getIconCollections([
          'lucide',
          'logos',
          'ri',
          'ph',
          'material-symbols',
          'teenyicons',
          'fluent',
        ]),
      },
    }),
  ],
};

module.exports = tailwindConfig;
