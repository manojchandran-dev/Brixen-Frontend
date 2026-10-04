# Company Reports: backend needs

The company admin **Reports** page in the app has six tabs: Sales, Expenses, Profit & Loss, Customers, Products & Inventory, and Employees. Every tab has a date filter (Week, Month, Custom, All), summary tiles, a chart or donut, and detailed lists with search and sort.

**How it works today:** the app loads each module's full list (every page, 100 at a time) and works out all report numbers on the phone. No report-specific API is used. `GET /reports/summary` is no longer used by the company Reports page.

This works, and the numbers always match the detailed lists. Five things are missing on the backend, listed below in priority order.

---

## 1. Stock quantities (required: Products & Inventory tab)

Products have no stock field, so **Stock summary, Low stock and Out of stock** can't be shown. The Dashboard needs the same data (see `docs/company_dashboard_api.md`).

**Needed on products:**

| Field | Type | Meaning |
|---|---|---|
| `stock_quantity` | int | Units in stock now |
| `low_stock_threshold` | int, default 5 | At or below this counts as "low stock" |

- **Updating stock:** it goes **down** by each line item's quantity when a sale is created, and **up** when a purchase is recorded.
- **Deleted sales:** deleting or restoring a sale should reverse its stock change.

## 2. Cost price on each sale item (required: exact Profit & Loss)

The P&L tab works out **cost of goods sold** as quantity sold × the product's **current** `cost_price`. If a product's cost price changes, past profit changes too, and items whose product has no cost price count as zero cost.

**Needed:** store the cost at the time of sale on every sale item:

| Field on `sale_items` | Type | Meaning |
|---|---|---|
| `cost_price` | number | The product's `cost_price` when the sale was created |

Return it in the sale's `sale_items` list. The app will use it when it's there, and fall back to the product's current cost price otherwise.

## 3. Amount paid on sales (recommended: unpaid amounts)

A sale only has `payment_status` (`paid`, `pending`, `partial`). The Sales report's **Unpaid** tile counts a pending or partial invoice's full total, because the amount already paid isn't stored.

**Needed on sales:**

| Field | Type | Meaning |
|---|---|---|
| `amount_paid` | number | Received so far. The balance is `total_amount − amount_paid`. |

## 4. Employee activity (when attendance comes back)

The Employee report shows headcount, status, department and new joiners. **Employee activity** (attendance, leave, working days) can't be shown, because the attendance module is switched off. When it's enabled, the report needs a per-employee summary for a date range:

```
GET /api/v1/attendance/summary?from=YYYY-MM-DD&to=YYYY-MM-DD
→ { "data": [ { "employee_id": "…", "present": 20, "absent": 2, "leave": 1, "late": 3 } ] }
```

## 5. Server-side report endpoints (recommended as companies grow)

Loading every record to the phone is fine for small and medium companies, but gets slow with thousands of sales. For scale, company report endpoints like the superadmin ones would be the fix:

`GET /api/v1/reports/company/{tab}?range=week|month|custom|all&from=&to=`

- **Tabs:** `sales`, `expenses`, `profit-loss`, `customers`, `products`, `employees`.
- **Response:** same `{ "data": ... }` format as `/reports/superadmin/{tab}`.
- **Period rules:** the same as the superadmin reports spec (`docs/superadmin_reports_api.md`).

What each tab needs (all for the selected period, unless marked all-time):

| Tab | Summary | Lists and charts |
|---|---|---|
| sales | total, invoices, average invoice, unpaid (count and amount) | `trend` (amount per bucket), `by_category`, `by_product` (qty, revenue), `invoices` (paged) |
| expenses | total, entries, average, top category | `trend`, `by_category` (amount, count), `expenses` (paged) |
| profit-loss | gross sales, tax, net sales, cost of goods, gross profit, expenses, net profit | `by_period` (net sales, cogs, expenses per bucket), `by_product` (revenue, cost) |
| customers | total (all-time), new, buying customers, average spend | `purchases` (per customer: invoices, total, last purchase), `new_customers` |
| products | total, active, inactive (all-time), units sold, low stock, out of stock | `by_category` (all-time), `product_sales` (qty, revenue, last sold) |
| employees | total, active, inactive (all-time), joined | `by_status`, `by_department`, `employees` (paged) |

## Export (optional)

The app doesn't export reports today (no PDF or Excel). If you want it, the easiest route is on the server: `GET /reports/company/{tab}/export?format=pdf|xlsx&range=…`, which returns a file the app can open or share.
