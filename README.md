# Slot Platform Activation & Revenue Analysis

PostgreSQL analysis of an online slot platform: how revenue decomposes
from wagers to operator margin, and where acquired players drop out.

**Headline finding:** 14.3% of registered players never placed a single spin.

## 1. Business questions

- How much does the operator earn, and from which part of the wagering volume?
- Why do some acquired players never activate?
- Which acquisition channels and countries convert into paying activity?
- Is revenue stable over the observed period, or concentrated?

## 2. Data

Source: Kaggle - Online Slot Games, Players Sessions and Spins
(monikamitrovic). Synthetic data, see Limitations.

| Table    | Rows      | Grain                         |
|----------|-----------|-------------------------------|
| players  | 8,000     | one row per registered player |
| sessions | 46,690    | one row per play session      |
| spins    | 4,646,999 | one row per individual spin   |

Observation period: 2025-10-01 to 2026-01-29, 121 days with activity
(no missing days).

## 3. Method

- Local PostgreSQL, tables created with explicit DDL, CSV loaded via psql `\copy`.
- Indexes created after load, then `ANALYZE`.
- Data validation before any metric: column semantics were tested against
  domain expectations rather than trusted by name.
- Money columns typed `numeric`, not `float`, because every business metric
  here is a sum over 4.6M rows.
- Reproduce: run `sql/01_schema.sql`, then `sql/02_load.sh`, then
  `sql/03_analysis.sql`.

## 4. Findings

### Revenue decomposition

- Wagered: 8,110,087.47
- Paid out to players: 7,535,788.52
- GGR (gross gaming revenue): 574,298.95
- RTP 92.92%, operator hold 7.08%
- GGR normalised: ~143.5k per month over 4 months

Wagered volume is not revenue. Revenue is the difference between what
players stake and what they win back - 7 cents of every staked euro.
Two independent formulas (difference of sums, and volume x hold) produce
the same figure, which is how the metric was cross-checked.

### Activation gap

6,857 of 8,000 players (85.7%) ever placed a spin. 1,143 players (14.3%)
never did, despite being acquired.

Two alternative explanations were tested and rejected:

1. Right-censoring - not enough time to activate. Rejected: the latest
   sign-up among non-activated players was 2025-10-30, while observation
   runs to 2026-01-29, so each had at least 90 days.
2. Empty sessions present in `sessions` but absent from `spins`. Rejected:
   none of the 1,143 appear in `sessions` at all, so the tables are
   consistent and no session is spin-less.

Interpretation: the gap is an onboarding or traffic-quality issue, not a
measurement artifact. 14.3% of acquisition spend produced accounts that
never touched the product.

### Why averages are reported as medians here

Sessions per player average 5.84, but the distribution is right-skewed by
a small group of heavy players. Engagement metrics are therefore presented
as medians, while economic metrics use two denominators explicitly:
ARPU 71.8 (all acquired players) vs ARPPU 83.8 (active only). ARPU is the
relevant one for campaign evaluation, because CAC is paid per registration.

## 5. Limitations

- Data is synthetic. Absolute money values are not transferable to a real
  P&L; methodology and query patterns are.
- RTP 92.9% sits below the typical 94-96% range of live casino providers.
- Observations end 2026-01-29, so no conclusion about long-term retention
  or lifetime value beyond ~4 months is possible.

## 6. Next steps

- Weekly cohort retention by signup date.
- GGR and activation by acquisition channel, country, slot volatility.
- Feature-buy behaviour as an engagement and risk signal.
- BI layer on top of the validated SQL.
