# Inventory: backend needs

The app's Inventory module has five tabs: Overview, Stock, Movements, Transfers and Reports. It's built on the inventory APIs that already exist (`/inventory`, `/inventory/movements`, `/inventory/adjustments`, `/purchases`). Three things a garment business needs are missing on the backend.

## 1. Size and colour variants (the big one)

Today each product has **one** `size`, **one** `color` and **one** `stock_quantity`. A shirt sold in S, M, L and XL, in two colours, has to be created as 8 separate products. The app currently shows each product as one variant.

**Needed:** variants under a product, each with its own stock:

| `product_variants` column | Meaning |
|---|---|
| `id`, `product_id`, `company_id` | |
| `sku` | Unique within the company, e.g. `SHIRT-BLU-M` |
| `size`, `color` | |
| `stock_quantity`, `low_stock_threshold` | Stock lives here instead of on the product |
| `cost_price`, `retail_price`, `wholesale_price` | Optional; fall back to the product's prices when empty |

- **Where `variant_id` goes:** `sale_items`, `purchase_items` and `stock_movements` take a `variant_id`. `product_id` stays for reporting.
- **`GET /inventory`:** returns one row per variant.
- **`GET /products/:id`:** includes its `variants`.
- **Existing products:** migrate each one to a single variant using its current `size`, `color` and stock.

## 2. Locations and stock transfers

Stock is one number for the whole company. Transfers between a shop, a godown and a branch need stock **per location**.

- **`locations`:** `id`, `company_id`, `name`, `type` (shop/godown/branch), `is_default`.
- **`stock_levels`:** `variant_id` (or `product_id` until variants exist), `location_id`, `quantity`. The product total is the sum across locations.
- **`stock_transfers`:** `id`, `from_location_id`, `to_location_id`, `status` (`pending` → `in_transit` → `received`, or `cancelled`), `note`, `created_by`, and the dates.
- **`stock_transfer_items`:** `transfer_id`, `variant_id`, `quantity`.
- **Stock updates:** stock leaves the source when a transfer is dispatched and arrives when it's received, each written to the ledger with `type = transfer`.
- **Endpoints:**
  - `GET/POST /locations`
  - `GET/POST /inventory/transfers`
  - `PUT /inventory/transfers/:id/status`
  - A `location_id` filter on `/inventory` and `/inventory/movements`
- **Purchases and sales:** they take a `location_id`, which defaults to the company's default location.

## 3. A date on manual stock entries

`POST /inventory/adjustments` stamps each entry with the time it's saved, so a stock-in or damage entry recorded the next day carries the wrong date. The app shows "Date: today" for now.

**Needed:** accept an optional `movement_date` (`YYYY-MM-DD`, not in the future) and use it for the ledger row's date. `/inventory/movements` date filters would then use that date.

## Already working (no change needed)

- **Stock summary, low/out counts and stock value:** from `GET /inventory`.
- **Stock history:** from `GET /inventory/movements` (type, product and date filters).
- **Stock in and out:** purchases and sales move stock automatically. Manual in/out goes through adjustments, with the reference saved in the note.
- **Stock counts:** `set_to` adjustments.
