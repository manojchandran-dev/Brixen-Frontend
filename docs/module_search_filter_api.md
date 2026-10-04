# Module search and filters: backend request

The company module pages (Employees, Sales, Customers, Expenses, Products, and the Masters lists) now have a search box and a filter button. The app currently applies both **on the phone**, over the first page it loads (up to 200 records). A company with more records than that gets incomplete results, so filtering needs to move to the server.

**Request:** the existing list endpoints should accept the filters below as query parameters and return the matching page, with the total count.

## Common rules

- The endpoints stay the same: `GET /api/v1/employees`, `/sales`, `/customers`, `/expenses`, `/products`, and the master endpoints.
- They already accept `page`, `limit` and `search`. Please confirm that `search` covers the fields listed per module below.
- Filters combine with each other and with `search` using **AND**. A missing parameter means "any".
- Values match case-insensitively (for example `status=active` also matches `Active`).
- Please return `meta: { page, limit, total, pages }`, so the app can show "Total employees: 342" and load more pages.
- **Date filters:** `from` and `to` in `YYYY-MM-DD`, with both days included.

## Per module

### Employees: `GET /employees`

| Param | Values | Field |
|---|---|---|
| `search` | text | name, employee code, department |
| `status` | e.g. `active`, `inactive`, `on_leave` | `status` |
| `department` | text | `department` |
| `employment_type` | text | `employment_type` |

### Sales: `GET /sales`

| Param | Values | Field |
|---|---|---|
| `search` | text | customer name, invoice type, status |
| `payment_status` | `paid`, `pending`, `partial` | `payment_status` |
| `payment_type` | e.g. `cash`, `upi`, `card` | `payment_type` |
| `invoice_type` | text | `invoice_type` |
| `from` / `to` | date | `bill_date` |

### Customers: `GET /customers`

| Param | Values | Field |
|---|---|---|
| `search` | text | name, phone, email |
| `has_gst` | `true` / `false` | `gst_number` is set or empty |
| `from` / `to` | date | `created_at` (the app's "Added in the last 7/30 days") |

### Expenses: `GET /expenses`

| Param | Values | Field |
|---|---|---|
| `search` | text | title, category name |
| `category_id` | id | `category_id` |
| `payment_method` | text | `payment_method` |
| `from` / `to` | date | `expense_date` |

### Products: `GET /products`

| Param | Values | Field |
|---|---|---|
| `search` | text | name, product code, category name |
| `category_id` | id | `category_id` |
| `status` | `active`, `inactive` | `status` |
| `gender` | e.g. `men`, `women`, `kids`, `unisex` | `gender` |

### Masters: expense categories, units, product categories

| Param | Values | Field |
|---|---|---|
| `search` | text | name |
| `status` | `ACTIVE`, `INACTIVE` | `status` |

## Filter options (nice to have)

The app currently builds the choices for each filter from the records it has loaded, for example the departments that appear among those employees. On the server, one small endpoint per module would give the full list:

```
GET /api/v1/employees/filters
→ { "data": { "status": ["active","inactive","on_leave"],
              "department": ["Sales","Stitching","Accounts"],
              "employment_type": ["full_time","part_time"] } }
```

It returns the distinct values that exist for this company. The same shape works for `/sales/filters`, `/expenses/filters` and `/products/filters`.

## Once this is live, the app will

- Send the chosen filters and the search text with the list request, and stop filtering on the phone.
- Show the total from `meta.total` and load more pages as the user scrolls.
- Use the `/filters` endpoint, if added, for the filter choices.
