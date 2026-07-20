-- Read-only audit: identify historically duplicated consumable-credit grants.
--
-- Root cause (fixed in 20260720_0007 + credit_service/revenuecat_service):
-- one Google Play purchase produced TWO credit_purchases rows — one from the
-- webhook keyed by the Google Play order id ("GPA.####-####-####-#####"), and
-- one from /v1/credits/sync keyed by the RevenueCat V2 purchase resource id
-- ("otpGps...") — because the two paths used different identifiers.
--
-- This script ONLY reads. It never subtracts credits or deletes rows. Any
-- remediation of balances must be a separate, reviewed operation.
--
-- Signature of a duplicate pair (same underlying store purchase granted twice):
--   * same user_id
--   * same credits_granted
--   * created within a couple of minutes of each other
--   * different transaction_id, typically one "GPA.%" and one "otpGps%"
--     (or two otherwise-unrelated identifier formats)

-- 1) Candidate duplicate PAIRS, newest first. Each row is a suspected
--    double-grant: keep the earlier grant, treat the later as the duplicate.
SELECT
    a.user_id,
    a.transaction_id      AS kept_transaction_id,
    a.product_id          AS kept_product_id,
    a.source              AS kept_source,
    a.created_at          AS kept_at,
    b.transaction_id      AS duplicate_transaction_id,
    b.product_id          AS duplicate_product_id,
    b.source              AS duplicate_source,
    b.created_at          AS duplicate_at,
    b.credits_granted     AS duplicate_credits,
    (b.created_at - a.created_at) AS gap,
    CASE
        WHEN a.transaction_id LIKE 'GPA.%' AND b.transaction_id LIKE 'otpGps%'
          OR a.transaction_id LIKE 'otpGps%' AND b.transaction_id LIKE 'GPA.%'
        THEN 'store_order_id_vs_revenuecat_id'
        ELSE 'same_amount_close_timestamps'
    END AS match_reason
FROM credit_purchases AS a
JOIN credit_purchases AS b
  ON a.user_id = b.user_id
 AND a.credits_granted = b.credits_granted
 AND a.transaction_id <> b.transaction_id
 AND b.created_at > a.created_at
 AND b.created_at - a.created_at <= INTERVAL '2 minutes'
-- Exclude legitimately distinct purchases that happen to share amount/time by
-- requiring the two rows to NOT already share the RevenueCat purchase id.
 AND (
        a.revenuecat_purchase_id IS DISTINCT FROM b.revenuecat_purchase_id
        OR a.revenuecat_purchase_id IS NULL
     )
ORDER BY b.created_at DESC;

-- 2) Per-user rollup: how many excess credits each user likely received.
--    (Estimated over-grant = sum of the later/duplicate grants.)
SELECT
    dup.user_id,
    COUNT(*)                     AS suspected_duplicate_grants,
    SUM(dup.duplicate_credits)   AS estimated_excess_credits
FROM (
    SELECT
        b.user_id,
        b.transaction_id,
        b.credits_granted AS duplicate_credits
    FROM credit_purchases AS a
    JOIN credit_purchases AS b
      ON a.user_id = b.user_id
     AND a.credits_granted = b.credits_granted
     AND a.transaction_id <> b.transaction_id
     AND b.created_at > a.created_at
     AND b.created_at - a.created_at <= INTERVAL '2 minutes'
) AS dup
GROUP BY dup.user_id
ORDER BY estimated_excess_credits DESC;

-- 3) Optional correlation with the webhook ledger: RevenueCat events for the
--    same app user around the same time (context only; not used for remediation).
--    SELECT e.event_id, e.event_type, e.product_id, e.transaction_id, e.processed_at
--    FROM revenuecat_events e
--    JOIN users u ON u.app_user_id = e.app_user_id
--    WHERE u.id = :user_id
--    ORDER BY e.processed_at DESC
--    LIMIT 20;
