#!/usr/bin/env bash
# Deploy the Comprezza privacy policy to Cloudflare Pages.
#
# Prerequisites:
#   - CLOUDFLARE_API_TOKEN set (Pages:Edit permission)
#   - CLOUDFLARE_ACCOUNT_ID set (find it in the Cloudflare dashboard URL or Workers & Pages)
#
# Usage:
#   CLOUDFLARE_API_TOKEN=... CLOUDFLARE_ACCOUNT_ID=... ./scripts/deploy_privacy_policy.sh
#
# The first deploy creates the project; later runs update it. The site is
# served at https://comprezza-privacy-policy.pages.dev by default.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "ERROR: CLOUDFLARE_API_TOKEN is not set." >&2
  exit 1
fi
if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
  echo "ERROR: CLOUDFLARE_ACCOUNT_ID is not set." >&2
  exit 1
fi

export CLOUDFLARE_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID

npx --yes wrangler pages deploy privacy-policy-site \
  --project-name comprezza-privacy-policy \
  --branch main \
  "$@"
