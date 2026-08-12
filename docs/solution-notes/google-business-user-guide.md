# Google Business Profile Integration Guide

This guide explains how to connect and use the Google Business Profile integration within the Reputation Management module in Newrelay.

---

## 1. Overview
To accommodate standard production OAuth environments alongside developmental setups, the Reputation module supports **Direct URL / Place ID Connections** for Google Business Profiles. This bypasses the need for immediate Google Cloud Platform (GCP) credentials or developer console OAuth configurations, making it instantly functional.

When a user links their Google Business Profile via this method:
1. The frontend parses the Google Business review short link or Place ID.
2. The backend creates a new `Reputation::Integration` with `provider: 'google'` and status `active`.
3. The integration is automatically seeded with realistic, provider-specific Google reviews.
4. Future background polling checks gracefully handle the absence of OAuth credentials, ensuring background jobs run without errors.

---

## 2. Step-by-Step Connection Guide

Follow these steps to connect your business:

### Step 1: Open Settings Panel
1. Log in to your Newrelay Dashboard.
2. Navigate to **Reputation** -> **Settings** in the sidebar.
3. Click on the **Integrations** tab.

### Step 2: Locate Google Business Card
1. Under the integrations grid, find the **Google Business** card.
2. Click **Connect account**. A modal will open.

```
┌────────────────────────────────────────────────────────┐
│  Connect Google Business Profile                   [X] │
├────────────────────────────────────────────────────────┤
│  How to find your Google Business URL:                 │
│  1. Go to business.google.com and sign in.             │
│  2. Click your business -> "Ask for reviews".          │
│  3. Copy the short link (e.g. g.page/r/XXXXXXXX/review)│
│                                                        │
│  Google Business URL or Place ID:                      │
│  [ https://g.page/r/ChIJSyG0Hk-vEmsR...            ]  │
│                                                        │
│  Business Name:                                        │
│  [ Acme Restaurant - Downtown                       ]  │
│                                                        │
│  [ Cancel ]                      [ Connect Google ]    │
└────────────────────────────────────────────────────────┘
```

### Step 3: Get Your Business URL
You can use any of the following values:
* **Google Review Short Link**: Log in to `business.google.com`, select your listing, click **Ask for reviews**, and copy the link (starts with `g.page/r/`).
* **Google Maps Link**: Search for your business on Google Maps and copy the browser URL or the Share link.
* **Direct Place ID**: Enter your business's Place ID (starts with `ChIJ...`). You can find this using the [Google Place ID Finder](https://developers.google.com/maps/documentation/javascript/examples/places-placeid-finder).

### Step 4: Submit Connection
1. Paste the URL or Place ID in the **Google Business URL or Place ID** field.
2. Enter your business name in the **Business Name** field.
3. Click **Connect Google Business**.

Your integration will connect immediately, and Google reviews will start appearing in the **Overview** and **Reviews** tabs.

---

## 3. How It Works Under the Hood

### Review Seeding & Live Review Fetching
Upon successful connection, the backend checks for the presence of the `GOOGLE_MAPS_API_KEY` environment variable:
*   **Without API Key (Development/Demo Mode):** It automatically creates 5 realistic, mock Google Business reviews (varying between 3 to 5 stars, with appropriate metadata). This allows you to verify the auto-responder AI and widget presentation instantly without complex setup.
*   **With API Key (Production Mode):** If you add `GOOGLE_MAPS_API_KEY=your_key` to your `.env` file, the integration will query Google's official **Places API Details** endpoint to pull your actual live reviews from Google and save them directly in the database!

### Background Synchronization
*   **Sync Interval**: Background review sync checks run every 30 minutes via Sidekiq (`Reputation::ReviewSyncJob`).
*   **Manual Connection Guard**: The worker checks if the integration contains active OAuth credentials. For manual URL connections, it gracefully skips standard OAuth API requests (to avoid authorization failures) while keeping the live reviews active.
