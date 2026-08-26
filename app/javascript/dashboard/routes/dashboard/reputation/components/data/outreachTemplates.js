// Prebuilt outreach message templates for the Request Reviews modal (Step 3).
// Demo content — channel-specific starter copy the user can pick and edit.

export const defaultSmsTemplates = [
  {
    id: 'sms_post_visit',
    name: 'Standard Post-Visit Review',
    message:
      'Hi {{FirstName}}, thank you for choosing {{BusinessName}}! Would you mind sharing your experience? ⭐ Leave a quick review here: {{ReviewLink}}',
    autoDelay: '2 hours post-visit',
  },
  {
    id: 'sms_quick_casual',
    name: 'Quick & Casual 1-Tap',
    message:
      'Hey {{FirstName}}! Thanks for stopping by {{BusinessName}} today. We would love to know how we did! Tap here to rate us: {{ReviewLink}}',
    autoDelay: '30 mins after checkout',
  },
  {
    id: 'sms_care_staff',
    name: 'Staff & Care Appreciation',
    message:
      'Hi {{FirstName}}, Dr. Alex & our care team at {{BusinessName}} hope you had a great visit! Could you leave a quick review? {{ReviewLink}}',
    autoDelay: '2 hours post-visit',
  },
  {
    id: 'sms_gentle_followup',
    name: 'Gentle 24h Follow-up Nudge',
    message:
      'Hi {{FirstName}}, just checking in from {{BusinessName}}. If you have 30 seconds, we would greatly appreciate your feedback: {{ReviewLink}}',
    autoDelay: '24 hours after delivery',
  },
  {
    id: 'sms_vip_loyalty',
    name: 'VIP & Loyalty Appreciation',
    message:
      '{{FirstName}}, thank you for being a valued client of {{BusinessName}}! Your 5-star feedback means the world to us: {{ReviewLink}}',
    autoDelay: '2 hours post-visit',
  },
  {
    id: 'sms_order_completion',
    name: 'Order & Service Completion',
    message:
      'Hi {{FirstName}}, your appointment with {{BusinessName}} is complete! How did we do? Share your review here: {{ReviewLink}}',
    autoDelay: 'Immediately post-visit',
  },
];

export const defaultEmailTemplates = [
  {
    id: 'email_standard_5star',
    name: 'Standard 5-Star Feedback',
    subject: 'How was your experience with {{BusinessName}}?',
    body: 'Hi {{FirstName}},\n\nThank you for choosing us!\n\nWould you mind sharing your experience?\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nIt only takes one minute.\n\nThank you ❤️',
    autoDelay: '4 hours post-service (Recommended)',
  },
  {
    id: 'email_vip_loyalty',
    name: 'VIP Client Appreciation',
    subject: '{{FirstName}}, thank you for being a valued client!',
    body: 'Hi {{FirstName}},\n\nThank you for choosing {{BusinessName}}. As one of our top clients, your opinion means everything to us. Would you share your experience?\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nThank you ❤️',
    autoDelay: '2 hours post-visit',
  },
  {
    id: 'email_gentle_reminder',
    name: 'Gentle 24h Follow-up Note',
    subject: 'A quick note from {{BusinessName}}',
    body: 'Hi {{FirstName}},\n\nWe hope you enjoyed your visit with {{BusinessName}}. If you have 30 seconds, we would love to hear your feedback.\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nThank you ❤️',
    autoDelay: '24 hours post-visit',
  },
  {
    id: 'email_service_complete',
    name: 'Appointment & Service Completed',
    subject: 'Your appointment is complete! How did we do?',
    body: 'Your recent appointment with {{BusinessName}} is complete. We would love to know how your visit went with {{EmployeeName}}!\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nThank you ❤️',
    autoDelay: 'Immediately post-visit',
  },
];

export const defaultWhatsAppTemplates = [
  {
    id: 'wa_friendly_checkin',
    name: 'Friendly Post-Visit Check-in',
    headerText: 'Hi {{FirstName}} 👋',
    bodyText:
      'Thank you for visiting {{BusinessName}} today! We would love to hear your feedback. Tap below to share a quick 5-star review:\n\n{{ReviewLink}}',
    button1: '⭐ Leave a 5★ Review',
    button2: '💬 Talk with Support',
    autoDelay: 'Immediately post-visit',
  },
  {
    id: 'wa_quick_google',
    name: 'Quick 1-Tap Google Review',
    headerText: 'Hey {{FirstName}} ⭐',
    bodyText:
      'Thanks for stopping by {{BusinessName}} today. Rate your experience in 1 tap on Google:\n\n{{ReviewLink}}',
    button1: '⭐ Rate Us 5 Stars',
    button2: 'Need Help?',
    autoDelay: '30 mins after checkout',
  },
  {
    id: 'wa_care_staff',
    name: 'Staff Mention & Care Followup',
    headerText: 'Hi {{FirstName}} from {{BusinessName}}',
    bodyText:
      '{{EmployeeName}} and the entire team hope you had a great experience today! Would you mind sharing a quick review?\n\n{{ReviewLink}}',
    button1: '⭐ Review {{EmployeeName}}',
    button2: '💬 Ask a Question',
    autoDelay: '2 hours post-visit',
  },
  {
    id: 'wa_vip_client',
    name: 'VIP Customer Care Prompt',
    headerText: 'Hello {{FirstName}} 💎',
    bodyText:
      'Thank you for being a valued VIP client of {{BusinessName}}. Your feedback helps us maintain the highest standard of service.\n\n{{ReviewLink}}',
    button1: '⭐ Share VIP Feedback',
    button2: '📞 Contact Concierge',
    autoDelay: '2 hours post-visit',
  },
];
