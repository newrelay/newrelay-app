import { INBOX_TYPES } from 'dashboard/helper/inbox';

// Mock/demo channel branding used across the (pre-backend) Autoresponder UI port.
// Delete once real inbox/channel data is wired in.
export const CHANNEL_LOGO_URLS = {
  Instagram:
    'https://upload.wikimedia.org/wikipedia/commons/e/e7/Instagram_logo_2016.svg',
  Facebook:
    'https://upload.wikimedia.org/wikipedia/commons/b/be/Facebook_Messenger_logo_2020.svg',
  WhatsApp: 'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
};

export const CHANNEL_NAMES = Object.keys(CHANNEL_LOGO_URLS);

// Real channel_type -> display name/description, used once wired to actual inbox data.
export const AUTORESPONDER_CHANNELS = [
  {
    type: INBOX_TYPES.INSTAGRAM,
    name: 'Instagram',
    descKey: 'INSTAGRAM_DESC',
  },
  { type: INBOX_TYPES.FB, name: 'Facebook', descKey: 'FACEBOOK_DESC' },
  {
    type: INBOX_TYPES.WHATSAPP,
    name: 'WhatsApp Business',
    descKey: 'WHATSAPP_DESC',
  },
];

export const CHANNEL_NAME_BY_TYPE = AUTORESPONDER_CHANNELS.reduce(
  (acc, { type, name }) => ({ ...acc, [type]: name }),
  {}
);
