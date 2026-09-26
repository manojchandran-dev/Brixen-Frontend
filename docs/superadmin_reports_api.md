# Superadmin Reports API

The superadmin app has six report tabs: Company, Users, Notifications, Support, Chatbot and Activity. Right now the app builds them by downloading whole lists: 100 companies, 200 employees, and all notifications, tickets and chats. It then counts everything on the phone. That gets slow as the data grows and gives wrong numbers once there are more rows than those limits.

**Request:** one endpoint per tab, with every number counted on the server.

## Common rules

**Endpoint:** `GET /api/v1/reports/superadmin/{tab}`, where `tab` is `company`, `users`, `notifications`, `support`, `chatbot` or `activity`.

**Access:** superadmin only. Any other role gets `403`.

**Query parameters**

| Param | Values | Notes |
|---|---|---|
| `range` | `week`, `month`, `custom`, `all` | Default is `month`. |
| `from`, `to` | `YYYY-MM-DD` | Required when `range=custom`. Both days are included. |
| `tz` | IANA name, e.g. `Asia/Kolkata` | The day boundaries follow this time zone. |

**Date range for each `range` value** (the period ends today):

| `range` | Period |
|---|---|
| `week` | The last 7 days, today included |
| `month` | The last 30 days, today included |
| `custom` | From `from` to `to` |
| `all` | No date limit |

**Response format:** fields are snake_case, and the payload sits inside `{ "data": ... }`, the same as `/dashboard/superadmin`. Dates are ISO 8601.

**Trend buckets:** every tab returns `trend` as a list of chart bars. Each bar looks like this:

```json
{ "label": "Mon", "start": "2026-09-21", "end": "2026-09-21", "count": 3 }
```

The server picks the bar size from the range:

| `range` | Bars | Label format |
|---|---|---|
| `week` | 7 days | `Mo`, `Tu`, … |
| `month` | 5 weeks, 7 days each, the last one ending today | `d/M` of each week's first day |
| `custom`, up to 14 days | One bar per day | Day number (`Mo` style when 8 days or fewer) |
| `custom`, 15 to 120 days | Weeks | `d/M` |
| `custom`, more than 120 days | Months | `Sep` |
| `all` | Months from the first record, at most 24 | `Sep` |

- List the bars oldest first.
- Include bars that have a count of 0.

**List limits:** each list returns only as many items as the app shows (8, 6 or 10, given per tab below), newest first.

**Totals:** a tab can mix two kinds of numbers:
- **All-time totals** ignore the range. Examples are "Total companies" and the Active and Inactive counts.
- **Period numbers** only count records inside the range.

Each field below says which kind it is.

---

## 1. Company: `/reports/superadmin/company`

```json
{
  "summary": {
    "total": 42,          // all time
    "new": 5,             // companies created in range
    "active": 38,         // all time, is_active = true
    "inactive": 4         // all time
  },
  "trend": [ ... ],       // companies created per bucket
  "status": {             // all time
    "active": 38,
    "inactive": 4,
    "setup_pending": 3    // onboarding_status is not "completed"
  },
  "recent": [             // created in range, newest first, max 8
    { "id": "…", "name": "Acme", "owner_name": "Ravi", "is_active": true, "created_at": "…" }
  ]
}
```

## 2. Users and employees: `/reports/superadmin/users`

```json
{
  "summary": {
    "total": 1200,        // all time, every company
    "new": 45,            // employees created in range
    "active": 1100,       // status = active
    "inactive": 100       // status = inactive or on leave
  },
  "trend": [ ... ],       // employees created per bucket
  "by_company": [         // all time, top 6 by count
    { "company_id": "…", "company_name": "Acme", "count": 320 }
  ],
  "active_users": 0       // OPTIONAL: users who logged in during the range
}
```

`active_users` needs login tracking. Once it's in the response, the app will show it in place of the note it displays now.

## 3. Notifications: `/reports/superadmin/notifications`

Everything on this tab is counted over notifications **sent in the range**.

```json
{
  "summary": {
    "sent": 20,           // number of push campaigns
    "delivered": 5400,    // sum of delivered
    "failed": 60,         // sum of failed
    "read": 3100          // sum of opened
  },
  "trend": [ ... ],       // campaigns sent per bucket
  "read_vs_unread": {     // over delivered notifications
    "read": 3100,
    "unread": 2300
  },
  "recent": [             // max 6
    { "id": "…", "title": "Holiday notice", "recipients": 300, "delivered": 290, "opened": 180, "failed": 10, "sent_at": "…" }
  ]
}
```

## 4. Support tickets: `/reports/superadmin/support`

```json
{
  "summary": {
    "raised": 30,         // tickets created in range
    "open": 12,           // of those: status open or in_progress
    "pending": 4,         // of those: status pending
    "resolved": 14        // of those: status resolved or closed
  },
  "trend": [ ... ],       // tickets RESOLVED per bucket (by resolved_at)
  "by_priority": {        // tickets created in range
    "critical": 2, "high": 6, "medium": 15, "low": 7
  },
  "by_status": {          // tickets created in range
    "open": 8, "in_progress": 4, "pending": 4, "resolved": 10, "closed": 4
  }
}
```

**Needed:** a `resolved_at` timestamp on tickets. Right now the app uses `updated_at`, so a later edit moves the ticket to the wrong date.

## 5. Chatbot and support chat: `/reports/superadmin/chatbot`

```json
{
  "summary": {
    "total": 80,          // all conversations, all time
    "active": 25,         // last message inside the range
    "replied": 18,        // active, and support sent the last message
    "awaiting": 7         // active, and the company sent the last message
  },
  "trend": [ ... ],       // conversations per bucket, by last-message date
  "awaiting_list": [      // max 6, newest first
    { "conversation_id": "…", "company_name": "Acme", "preview": "Need help with…", "sent_at": "…" }
  ],
  "ai_handled": 0,        // OPTIONAL: answered by the bot only
  "escalated": 0          // OPTIONAL: handed from the bot to a human
}
```

`ai_handled` and `escalated` depend on the chatbot recording who answered each conversation. Send them once that exists.

## 6. Activity and audit: `/reports/superadmin/activity`

This tab should come from a single audit log table instead of being put together from four lists.

```json
{
  "summary": {
    "total": 120,               // events in range
    "companies_created": 5,
    "employees_added": 45,
    "tickets_raised": 30
  },
  "trend": [ ... ],             // all events per bucket
  "recent": [                   // max 10, newest first
    {
      "type": "company_created",   // company_created | employee_added | ticket_raised |
                                   // notification_sent | admin_login | company_suspended
      "title": "Company created",
      "detail": "Acme",
      "actor": "superadmin@brixen.com",   // optional
      "at": "…"
    }
  ]
}
```

`admin_login` and `company_suspended` can only be reported once they're written to the audit log.

---

## Once this is live, the app will

- Call the matching endpoint whenever the user changes tab or date filter.
- Remove the list downloads and the counting on the phone.
- Remove the notes about missing data wherever the optional fields are present.
