# Olist Delivery Delays and Customer Satisfaction

A practice business-analysis project: how much does late delivery hurt customer satisfaction on an
online marketplace, and what should an operations team monitor to catch the problem early?

The project goes from raw data to SQL analysis to **dashboard requirements** (user stories with
acceptance criteria, traced back to the findings).

## Key findings

1. **Late delivery goes with much lower review scores.** On-time orders average 4.29 stars; orders
   1-3 days late average 3.29; orders 8+ days late average 1.70. The share of low reviews (2 stars or
   less) rises from 9.2% to 79.2%.
2. **Product category explains little.** Late-delivery rates range only from 7.5% to 11.8% across the
   top 10 categories, against 6.8% overall.
3. **Customer state matters a lot.** Late rates range from 2.8% (AM) to 21.4% (AL), with the Northeast
   worst. Rate and count tell different stories: SP has a low rate (4.5%) but the most late orders
   (1,820) because of its volume.

Details, full tables and limitations: [`docs/insights.md`](docs/insights.md).
Requirements: [`docs/requirements.md`](docs/requirements.md).

## Data

- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle.
  About 100,000 anonymised orders from 2016 to 2018.
- **Licence:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) (confirmed on the Kaggle page, 2026-11-13). Data © Olist. Used here for non-commercial learning.
- **The raw data is not in this repository.** Download it from Kaggle.
- **Tables used:** orders, order_items, order_reviews, products, customers,
  product_category_name_translation. Not used: geolocation, payments, sellers.

## Definitions

| Term | Definition |
|------|------------|
| Delivered order | `order_status = 'delivered'` and the customer delivery date is not empty |
| days_late | delivery date minus estimated delivery date, in days |
| Late order | `days_late > 0` |
| Lateness bucket | on time or early (<= 0), 1-3, 4-7, 8+ days late |
| Review score | 1-5. Orders with several reviews (547) use the average of their reviews |
| Low review | an order's review score of 2 or less |
| Minimum volume | 100 delivered orders before a category or state is ranked |

## Data-quality checks

From [`sql/02_checks.sql`](sql/02_checks.sql):

- 8 orders are 'delivered' but have no delivery date. They are excluded, leaving 96,470 delivered orders.
- 6 orders are 'canceled' but have a delivery date. They are not analysed; this is an open question.
- 547 orders have more than one review. Reviews are averaged per order before joining, so no order is counted twice.
- No duplicate keys. No order is delivered before it was purchased.
- 610 products have no category ("unknown"); 2 categories have no English name (the Portuguese name is used).

## Repository layout

```
sql/01_schema.sql     create tables, load CSVs, indexes, views (orders_clean, delivered_orders)
sql/02_checks.sql     data-quality checks, with results
sql/03_analysis.sql   Q1-Q3 analysis queries
docs/insights.md      three findings with numbers and limitations
docs/requirements.md  user stories, acceptance criteria, tests, traceability
```

## How to reproduce

1. Install MySQL 8 or later.
2. Download the dataset from Kaggle and put the CSV files in a `data/` folder in the repository root.
3. Allow local file loading: `SET GLOBAL local_infile = 1;`
4. From the repository root, run:
   ```
   mysql --local-infile=1 -u root -p < sql/01_schema.sql
   mysql -u root -p < sql/02_checks.sql
   mysql -u root -p < sql/03_analysis.sql
   ```
   `01_schema.sql` drops and re-creates the `olist` database.

Tools: MySQL 9.7 and MySQL Workbench.

## Limitations

- **Correlation, not causation.** Late delivery and low scores go together; this project does not prove lateness causes them.
- **Self-selected reviews.** Only customers who chose to review are in the score figures.
- **Old, foreign data.** Brazil, 2016-2018. Results should not be assumed to hold elsewhere or today.
- **Causes not tested.** Seller location and distance were not analysed.
- **Hypothetical dashboard.** The requirements are a practice exercise; there is no real client.

## Not done

- Charts (planned as optional, skipped for time).
- Analysis by seller or by distance.

## Credits

Data: Olist, via Kaggle (licence above). Analysis by the repository author.
