# DakshAI

DakshAI is a modern, open-source, and self-hosted customer support platform designed to help businesses deliver exceptional customer support experiences. Built for scale and flexibility, DakshAI gives you full control over your customer data while providing powerful tools to manage conversations across channels.

---

## 🚀 Key Features

### 💬 Omnichannel Support Desk
Centralize all customer conversations into one powerful inbox, no matter where your customers reach out from:
- **Live Chat**: A customizable widget for your website.
- **Email**: Connect your support inboxes.
- **Messaging Channels**: Connect Facebook Messenger, Instagram, WhatsApp, Telegram, and SMS.

### ✨ AI-Powered Support (Captain)
Supercharge your support with our built-in AI agent. Captain helps automate responses, handle common queries, and reduce agent workload—ensuring customers get instant, accurate answers while your team focuses on complex conversations.

### 📚 Help Center Portal
Publish help articles, FAQs, and guides through the built-in Help Center Portal. Enable customers to find answers on their own, reducing repetitive queries.

### 🗂️ Collaboration & Productivity
- **Private Notes**: Discuss issues internally with team members using `@mentions`.
- **Labels & Tags**: Categorize and organize conversations easily.
- **Canned Responses**: Save and reuse templates to reply faster to frequently asked questions.
- **Auto-Assignment**: Route conversations dynamically based on agent availability and workload.
- **Teams & Automations**: Scale support workflows with round-robin assignments and conditional triggers.

### 🔌 Integrations
- **Slack**: Sync, notify, and reply to conversations directly inside your Slack channels.
- **Dialogflow**: Integrate custom AI chatbots easily.
- **Dashboard Apps**: Embed your own custom internal tools inside the support agent UI.
- **Shopify**: View customer orders, history, and status right inside the chat window.

---

## 🛠️ Getting Started & Deployment

For a detailed deployment playbook, refer to our deployment guide:
👉 **[DEPLOYMENT.md](file:///Users/deependrasankhala/Documents/chandresh/chatwoot/DEPLOYMENT.md)**

We recommend deploying **DakshAI** using **Docker Compose** on a Linux Virtual Machine (such as Ubuntu on AWS, DigitalOcean, or Linode) for a simple and reliable self-hosted configuration.

---

## 💻 Developer & Maintenance Guide

If you are developing new features or maintaining this codebase, please follow the developer workflow guidelines:
👉 **[MAINTENANCE.md](file:///Users/deependrasankhala/Documents/chandresh/chatwoot/MAINTENANCE.md)**

### Key Workflow Highlights:
- **Feature Branches**: Develop features on separate branches off `release/dev`.
- **Coding Standards**: Follow standard Ruby/Rails conventions, ESLint/VueComposition API guidelines, and write Tailwind CSS utility classes exclusively.
- **Database Migrations**: Add indexes and write concurrent migrations for scale.

---

## 📄 License
Released under the MIT License.
