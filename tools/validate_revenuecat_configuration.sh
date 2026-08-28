#!/bin/sh

set -eu

# Debug builds intentionally support RevenueCat's Test Store and builds without
# a key. A distributable build must use a real Apple public SDK key.
if [ "${CONFIGURATION:-}" != "Release" ]; then
    exit 0
fi

key=$(printf '%s' "${REVENUECAT_API_KEY:-}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
case "$key" in
    appl_*) suffix=${key#appl_} ;;
    *)
        echo "error: Release builds require an App-specific RevenueCat Apple public SDK key (appl_…)." >&2
        exit 1
        ;;
esac

if [ "${#suffix}" -lt 16 ]; then
    echo "error: REVENUECAT_API_KEY looks incomplete; refusing to produce a Release build." >&2
    exit 1
fi

case "$suffix" in
    *[!A-Za-z0-9]*)
        echo "error: REVENUECAT_API_KEY contains unexpected characters." >&2
        exit 1
        ;;
esac

entitlement=$(printf '%s' "${REVENUECAT_ENTITLEMENT_ID:-}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
if [ -z "$entitlement" ] || [ "$entitlement" = '$(REVENUECAT_ENTITLEMENT_ID)' ]; then
    echo "error: REVENUECAT_ENTITLEMENT_ID must be configured for Release builds." >&2
    exit 1
fi

proxy=${REVENUECAT_PROXY_URL:-}
case "$proxy" in
    ""|https://*) ;;
    *)
        echo "error: REVENUECAT_PROXY_URL must be empty or use HTTPS." >&2
        exit 1
        ;;
esac
