// AUTO-GENERATED from the live NewRelay template sidebar. Drives AppSidebar + CommandPalette.
export type NavSubLeaf = { title: string; href: string; icon?: string; group?: string; badge?: number | string; children?: NavSubLeaf[] }
export type NavLeaf = { title: string; href: string; icon?: string; children?: NavSubLeaf[]; badge?: number | string }
export type NavItem = {
  title: string
  icon: string
  href?: string
  children?: NavLeaf[]
}
export type NavSection = { label?: string; items: NavItem[] }

export const navigation: NavSection[] = [
  {
    items: [
      {
        title: "Workspace",
        icon: "home",
        children: [
          { title: "Dashboard", href: "/" },
          { title: "Tasks", href: "/tasks" },
          { title: "Calendar", href: "/calendar" },
        ]
      },
      {
        title: "Customer Engagement",
        icon: "message-circle",
        children: [
          { title: "Inbox", href: "/inbox", badge: 12 },
          {
            title: "Conversations",
            href: "/conversations",
            children: [
              { title: "All conversation", href: "/conversations" },
              { title: "Mentions", href: "/conversations?filter=mentions" },
              { title: "Participating", href: "/conversations?filter=participating" },
              { title: "Unattended", href: "/conversations?filter=unattended" },
              {
                title: "Teams",
                href: "/conversations?filter=teams",
                children: [
                  { title: "Sales", href: "/conversations?team=sales" },
                  { title: "Support", href: "/conversations?team=support" },
                  { title: "Marketing", href: "/conversations?team=marketing" },
                ]
              },
              {
                title: "Channels",
                href: "/conversations?filter=channels",
                children: [
                  { title: "WhatsApp", href: "/conversations?channel=whatsapp" },
                  { title: "Email", href: "/conversations?channel=email" },
                  { title: "Slack", href: "/conversations?channel=slack" },
                ]
              },
              {
                title: "Labels",
                href: "/conversations?filter=labels",
                children: [
                  { title: "Enterprise", href: "/conversations?label=enterprise" },
                  { title: "Lead", href: "/conversations?label=lead" },
                  { title: "VIP", href: "/conversations?label=vip" },
                  { title: "In Progress", href: "/conversations?label=in-progress" },
                ]
              },
            ]
          },
        ]
      },
      {
        title: "CRM & Sales",
        icon: "users",
        children: [
          { title: "Contacts", href: "/contacts" },
          { title: "Companies", href: "/companies" },
          { title: "Deals", href: "/deals" },
          { title: "Pipelines", href: "/pipelines" },
          { title: "Opportunities", href: "/opportunities" },
        ]
      },
      {
        title: "Marketing",
        icon: "megaphone",
        children: [
          {
            title: "Campaigns",
            href: "/campaigns",
            children: [
              { title: "Live Chat", href: "/campaigns/live-chat" },
              { title: "SMS", href: "/campaigns/sms" },
              { title: "WhatsApp", href: "/campaigns/whatsapp" },
            ]
          },
          { title: "Funnels", href: "/funnels" },
          { title: "Landing Pages", href: "/landing-pages" },
          { title: "Forms", href: "/forms" },
          { title: "Surveys", href: "/surveys" },
        ]
      },
      {
        title: "Relay AI",
        icon: "bot",
        children: [
          { title: "FAQs", href: "/ai/faqs" },
          { title: "Documents", href: "/ai/documents" },
          { title: "Scenarios", href: "/ai/scenarios" },
          { title: "Playground", href: "/ai/playground" },
          { title: "Inboxes", href: "/ai/inboxes" },
          { title: "Tools", href: "/ai/tools" },
          { title: "Settings", href: "/ai/settings" },
        ]
      },
      {
        title: "Reputation",
        icon: "star",
        children: [
          { title: "Overview", href: "/reputation/overview" },
          { title: "Reviews", href: "/reviews" },
          { title: "Configuration", href: "/reputation/outreach" },
          { title: "Integrations", href: "/reputation/integrations" },
          { title: "Video Testimonials", href: "/video-reviews" },
          { title: "Listings", href: "/listings" },
        ]
      },
      {
        title: "Analytics",
        icon: "chart-bar",
        children: [
          { title: "Reports", href: "/reports" },
          { title: "Dashboards", href: "/analytics/dashboards" },
          { title: "Revenue Analytics", href: "/analytics/revenue" },
          { title: "Campaign Analytics", href: "/analytics/campaigns" },
        ]
      }
    ]
  },
  {
    label: "Administration",
    items: [
      {
        title: "Designing demo",
        icon: "layout-dashboard",
        children: [
          { title: "Onboarding", href: "/onboarding" },
          { title: "Onboarding 2", href: "/onboarding-2" },
        ]
      },
      {
        title: "Knowledge Base",
        icon: "help-circle",
        children: [
          { title: "Articles", href: "/support/articles" },
          { title: "Categories", href: "/support/categories" },
          { title: "Locales", href: "/support/locales" },
          { title: "Settings", href: "/support/settings" },
        ]
      },
      {
        title: "User State",
        icon: "user-state",
        children: [
          { title: "Empty state", href: "/user-states/empty-state" },
          { title: "Loading state", href: "/user-states/loading-state" },
          { title: "Error state", href: "/user-states/error-state" },
          { title: "No internet", href: "/user-states/no-internet" },
          { title: "Slow network", href: "/user-states/slow-network" },
          { title: "No search results", href: "/user-states/no-search-results" },
          { title: "Permission denied", href: "/user-states/permission-denied" },
          { title: "Session expired", href: "/user-states/session-expired" },
          { title: "Form validation", href: "/user-states/form-validation" },
          { title: "Success state", href: "/user-states/success-state" },
        ]
      }
    ]
  }
]
