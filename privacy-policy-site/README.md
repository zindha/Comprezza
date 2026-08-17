# Comprezza Privacy Policy Site

Static privacy-policy page for the Comprezza Android app, hosted on
[Cloudflare Pages](https://pages.cloudflare.com).

## Files

- `index.html` — the policy page (single file, no build step).

## Deploy

```bash
CLOUDFLARE_API_TOKEN=<token> CLOUDFLARE_ACCOUNT_ID=<account-id> \
  ./scripts/deploy_privacy_policy.sh
```

The first run creates the `comprezza-privacy-policy` Pages project and
deploys to `https://comprezza-privacy-policy.pages.dev`. Later runs update the
same project.

To use a custom domain, add it in the Cloudflare dashboard under
**Workers & Pages → comprezza-privacy-policy → Custom domains**, then enter the
final HTTPS URL in:

- Google Play Console (store listing → Privacy policy)
- `PLAYSTORE_LISTING.md` (Privacy policy URL)
- The app's legal destination
- The `[REPLACE_WITH_PUBLIC_HTTPS_PRIVACY_POLICY_URL]` placeholder in
  `PRIVACY_POLICY.md`

## Keep in sync

The page content mirrors `PRIVACY_POLICY.md` at the repo root. If the policy
changes, update both files and redeploy.
