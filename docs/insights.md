# Insights

All numbers come from `sql/03_analysis.sql`, run on 2026-11-13 against the `delivered_orders` view
(96,470 delivered orders). Definitions are in the README.

## Finding 1: Late delivery goes with much lower review scores

Query: `sql/03_analysis.sql`, Q1.

| lateness_bucket     | n_orders | n_reviewed | avg_score | pct_low_review |
|---------------------|---------:|-----------:|----------:|---------------:|
| 0) on time or early |   89,936 |     89,443 |      4.29 |            9.2 |
| 1) 1-3 days late    |    1,870 |      1,852 |      3.29 |           32.2 |
| 2) 4-7 days late    |    1,802 |      1,748 |      2.11 |           67.6 |
| 3) 8+ days late     |    2,862 |      2,781 |      1.70 |           79.2 |

- The average score drops at every step: from 4.29 for on-time orders to 1.70 for orders 8+ days late.
- Even 1-3 days late costs a full star (4.29 to 3.29), and the share of low reviews (average score 2 or less) rises from 9.2% to 32.2%.
- Late orders (6,534) are 6.8% of delivered orders.

**Limitation:** this shows that late delivery and low scores go together, not that lateness causes them. Only customers who chose to review are in the score columns.

## Finding 2: Lateness is spread fairly evenly across product categories

Query: `sql/03_analysis.sql`, Q2 (top 10 by late rate, categories with 100+ delivered orders).

| category                | n_orders | pct_late | avg_score |
|-------------------------|---------:|---------:|----------:|
| audio                   |      348 |     11.8 |      3.84 |
| fashion_underwear_beach |      117 |      9.4 |      4.01 |
| home_confort            |      392 |      9.4 |      3.89 |
| books_technical         |      256 |      8.2 |      4.43 |
| office_furniture        |    1,254 |      8.1 |      3.64 |
| baby                    |    2,809 |      8.0 |      4.10 |
| christmas_supplies      |      125 |      8.0 |      4.11 |
| electronics             |    2,517 |      7.6 |      4.12 |
| health_beauty           |    8,647 |      7.5 |      4.23 |
| musical_instruments     |      611 |      7.5 |      4.23 |

- The worst category (audio, 11.8%) is only about 5 points above the overall late rate of 6.8%, and the 10th is 7.5%. No category stands out strongly.
- The top of the list is made of small categories (audio has 348 orders), so the ranking may not be stable.
- office_furniture is late at a typical rate (8.1%) but has the lowest score in the list (3.64), so something other than lateness is likely hurting it (not tested here).

**Limitation:** an order with items in two categories counts in both. Category alone does not explain lateness; this query does not test other causes such as seller or distance.

## Finding 3: Lateness is concentrated by customer state

Query: `sql/03_analysis.sql`, Q3 (states with 100+ delivered orders, sorted by late rate).

| customer_state | n_orders | n_late | pct_late | avg_score |
|----------------|---------:|-------:|---------:|----------:|
| AL             |      397 |     85 |     21.4 |      3.85 |
| MA             |      717 |    125 |     17.4 |      3.83 |
| SE             |      335 |     51 |     15.2 |      3.91 |
| PI             |      476 |     66 |     13.9 |      3.99 |
| CE             |    1,279 |    176 |     13.8 |      3.94 |
| BA             |    3,256 |    396 |     12.2 |      3.93 |
| RJ             |   12,350 |  1,495 |     12.1 |      3.97 |
| PA             |      946 |    106 |     11.2 |      3.91 |
| ES             |    1,995 |    214 |     10.7 |      4.08 |
| PB             |      517 |     54 |     10.4 |      4.08 |
| TO             |      274 |     27 |      9.9 |      4.15 |
| MS             |      701 |     68 |      9.7 |      4.16 |
| PE             |    1,593 |    153 |      9.6 |      4.08 |
| RN             |      474 |     44 |      9.3 |      4.15 |
| SC             |    3,546 |    291 |      8.2 |      4.13 |
| GO             |    1,957 |    128 |      6.5 |      4.10 |
| RS             |    5,344 |    325 |      6.1 |      4.19 |
| MT             |      886 |     53 |      6.0 |      4.15 |
| DF             |    2,080 |    118 |      5.7 |      4.13 |
| MG             |   11,354 |    519 |      4.6 |      4.19 |
| SP             |   40,494 |  1,820 |      4.5 |      4.25 |
| PR             |    4,923 |    199 |      4.0 |      4.24 |
| RO             |      243 |      7 |      2.9 |      4.17 |
| AM             |      145 |      4 |      2.8 |      4.24 |

(AC, AP and RR have fewer than 100 delivered orders and are not shown.)

- The spread between states is much wider than between categories: AL is late 21.4% of the time, SP 4.5%, almost 5 times less.
- Most of the states with the highest late rates are in the Northeast (AL, MA, SE, PI, CE, BA).
- Rate and volume tell different stories. SP has one of the lowest late rates but the most late orders (1,820), because it has the most orders. RJ combines a high rate (12.1%) with high volume (1,495 late orders). SP and RJ together hold 3,315 of the 6,534 late orders (51%).
- States with higher late rates tend to have lower average scores, which matches Finding 1.

**Limitation:** distance from sellers is a likely explanation but was not tested (the sellers table was not loaded). State is the customer's state, not the seller's.
