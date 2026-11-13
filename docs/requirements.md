# Requirements: Delivery Performance Dashboard

> **Practice project.** This dashboard is hypothetical. There is no real client; the requirements
> are written from the findings in `docs/insights.md` to show how analysis turns into requirements.

## Goal

Help an operations team see late deliveries early and know where to act, because late delivery
goes with much lower review scores (Finding 1).

## Users

- **Operations manager**: watches overall delivery performance and decides where to focus.
- **Logistics analyst**: investigates specific regions and categories.
- **Customer service lead**: wants to contact customers before a late order turns into a bad review.

## Definitions

Same as the README: delivered order, days_late, late order (`days_late > 0`), lateness buckets
(on time or early, 1-3, 4-7, 8+ days late), minimum volume of 100 delivered orders.

## User stories

Priority: **Must** = needed for a first release; **Should** = valuable, can follow.

### US-1 Late-delivery rate by month (Must)

*As an operations manager, I want to see the late-delivery rate for each month, so that I can spot worsening performance early.*

- **AC-1.1** *Given* delivered orders exist for a month, *When* I open the dashboard, *Then* it shows that month's late-delivery rate (late orders / delivered orders) and the number of delivered orders.
- **AC-1.2** *Given* an order is not delivered, or is 'delivered' with no delivery date, *When* the rate is calculated, *Then* that order is not counted.

### US-2 Late deliveries by customer state, rate and count (Must)

*As an operations manager, I want to see each state's late-delivery rate and number of late orders side by side, so that I can choose where fixing delivery helps the most customers.*

- **AC-2.1** *Given* the state view is open, *When* I look at any state, *Then* I see both its late-delivery rate (%) and its number of late orders.
- **AC-2.2** *Given* a state has fewer than 100 delivered orders in the selected period, *When* the list is shown, *Then* the state is marked "low volume" and is not ranked.
- **AC-2.3** *Given* the list is shown, *When* I sort by rate or by count, *Then* the order changes accordingly.

### US-3 Open orders at risk of being late (Must)

*As a customer service lead, I want a list of orders that are not yet delivered and are near or past their estimated delivery date, so that I can contact the customer before they leave a bad review.*

- **AC-3.1** *Given* an order is not delivered and its estimated delivery date is within the next 2 days or already past, *When* I open the at-risk list, *Then* the order appears with its estimated date and customer state.
- **AC-3.2** *Given* an order is delivered or canceled, *When* I open the at-risk list, *Then* it does not appear.

### US-4 Review score by lateness bucket (Should)

*As an operations manager, I want to see the average review score for each lateness bucket, so that I can track how much lateness costs us in customer satisfaction.*

- **AC-4.1** *Given* reviewed delivered orders exist, *When* I open the satisfaction view, *Then* it shows the average score and the share of low reviews (score 2 or less) for each of the four buckets.
- **AC-4.2** *Given* an order has more than one review, *When* scores are calculated, *Then* the order counts once, using the average of its reviews.

### US-5 Late-delivery rate by product category (Should)

*As a logistics analyst, I want to see the late-delivery rate by product category, so that I can check whether any category needs different handling.*

- **AC-5.1** *Given* the category view is open, *When* I look at a category, *Then* I see its English name (or the original name if there is no translation), its number of delivered orders and its late-delivery rate.
- **AC-5.2** *Given* products have no category, *When* the view is shown, *Then* they are grouped as "unknown".
- **AC-5.3** *Given* a category has fewer than 100 delivered orders, *When* the list is shown, *Then* it is marked "low volume" and is not ranked.

## Acceptance tests

Tests use the 2016-2018 Olist data so the expected results are known from `sql/03_analysis.sql`.

| Test | Checks | Steps | Expected result |
|------|--------|-------|-----------------|
| AT-1 | AC-1.1, AC-1.2 | Add up late orders and delivered orders across all months | 6,534 late of 96,470 delivered (same as `delivered_orders`); the 8 'delivered' orders with no date are not included |
| AT-2 | AC-2.1 | Open the state view, find SP and AL | SP: 4.5%, 1,820 late. AL: 21.4%, 85 late |
| AT-3 | AC-2.2 | Look for AC, AP, RR | Marked low volume (80, 67 and 41 orders), not ranked |
| AT-4 | AC-2.3 | Sort by rate, then by count | By rate AL is first; by count SP is first |
| AT-5 | AC-3.1, AC-3.2 | Set "today" to a test date; create one shipped order due tomorrow, one due next week, one delivered, one canceled | Only the order due tomorrow appears |
| AT-6 | AC-4.1 | Open the satisfaction view | On time 4.29 / 9.2% low; 8+ days late 1.70 / 79.2% low |
| AT-7 | AC-4.2 | Count orders in the satisfaction view | Each order once (96,470 total), not 99k review rows |
| AT-8 | AC-5.1, AC-5.2 | Find `pc_gamer` and products with no category | `pc_gamer` shown by its original name; no-category products under "unknown" |
| AT-9 | AC-5.3 | Open the category view | Only categories with 100+ orders are ranked; audio is first at 11.8% |

## Traceability

| Finding (insights.md) | User story | Acceptance tests |
|-----------------------|------------|------------------|
| F1: late delivery goes with lower scores; even 1-3 days late costs a full star | US-1 (watch the rate), US-3 (act before it is late), US-4 (track the cost) | AT-1, AT-5, AT-6, AT-7 |
| F2: lateness is spread fairly evenly across categories | US-5 (Should, not Must, because the finding is weak) | AT-8, AT-9 |
| F3: big differences between states; rate and count tell different stories | US-2 | AT-2, AT-3, AT-4 |
| Data-quality check 1 (8 delivered orders with no date) | US-1 AC-1.2 | AT-1 |
| Data-quality check 2 (547 orders with several reviews) | US-4 AC-4.2 | AT-7 |
| Data-quality check 5 (missing categories and translations) | US-5 AC-5.1, AC-5.2 | AT-8 |

## Assumptions

- The estimated delivery date in the data is the date shown to the customer at purchase.
- Being late by one day or more counts as late (no grace period).
- The dashboard is refreshed at least daily (needed for US-3 to be useful).
- Customer state is a reasonable stand-in for delivery region.

## Open questions for a real client

1. Six orders are 'canceled' but have a delivery date. Were they delivered and then refunded, or is this a data error? Should they count as delivered?
2. Is late by one day really "late" for the business, or is there a grace period?
3. What late-delivery rate is the target? (Needed to colour the dashboard red or green.)
4. For US-3, how many days before the estimated date should an order count as at risk? (2 days is a placeholder.)
5. Can seller location be added? Distance is a likely cause of the state differences but was not tested.
6. Who will use the dashboard, how often, and on what device?
