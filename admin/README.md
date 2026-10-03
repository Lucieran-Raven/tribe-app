# TRIBE Super Admin

The admin console is a separate static site under `admin/`. It uses Firebase Authentication and callable Firebase Functions; it never gets service-account credentials.

## Setup

1. Copy `config.js.example` to `config.js` and fill in the Firebase Web App config for `tribe-app-v1`.
2. Deploy Firebase Functions from `functions/`.
3. Configure the Functions secret `ONESIGNAL_REST_API_KEY`.
4. Set the bootstrap environment/config value `SUPER_ADMIN_UID` to the Firebase Auth UID of the owner's account.
5. While signed in as that account, call `setSuperAdmin` once. The function grants the `superAdmin` custom claim.
6. Deploy the `admin/` directory to a separate Firebase Hosting site or another static host.
7. Do not commit `admin/config.js`.

The admin console supports post deletion/takedown, reply deletion, user ban/unban, announcements, and moderation data refresh. All privileged mutations are checked server-side with the Firebase custom claim.
