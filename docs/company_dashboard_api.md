# Company Dashboard: backend needs

The company admin dashboard shows:
- The totals from `GET /dashboard/summary`: employees, customers, products.
- Today's sales, expenses, net amount and activity, worked out in the app from the Sales, Expenses, Customers and Employees lists it already loads. Today's records always fall within those lists' first page, so these figures are complete.

**One thing is missing: stock levels for the Inventory alert.** Products have no stock quantity, so **Low stock** and **Out of stock** show "—" today.

## Needed on products

| Field | Type | Meaning |
|---|---|---|
| `stock_quantity` | int | Units currently in stock |
| `low_stock_threshold` | int, default 5 | At or below this counts as "low stock" |

Stock should go down when a sale is created (by each line item's quantity) and up when a purchase is recorded.

## Needed on `GET /dashboard/summary` (company users)

```json
{ "low_stock_products": 4, "out_of_stock_products": 1 }
```

- **Low stock:** `0 < stock_quantity <= low_stock_threshold`.
- **Out of stock:** `stock_quantity = 0`.

Once these come back, the dashboard's Inventory alert shows the two counts, and tapping one opens Products filtered to those items.

## Optional

If the backend would rather own the numbers, add `today_sales`, `today_invoices` and `today_expenses` to the same summary response. The app will use them instead of its own totals.
