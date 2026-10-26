import 'package:intl/intl.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../products/domain/entities/product.dart';
import '../../../sales/domain/entities/sale.dart';
import '../../../sales/domain/entities/sale_item.dart';
import '../superadmin/superadmin_reports_data.dart';

// Company reports are worked out from the module lists the app loads in
// full (Sales, Expenses, Customers, Products, Employees — every page), so
// summaries and detailed tables always agree. Pure Dart, testable.

/// [start, end) of [p]; nulls = unbounded ("All").
(DateTime?, DateTime?) periodBounds(ReportPeriod p, DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  DateTime back(int days) =>
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day - days);
  return switch (p.range) {
    ReportRange.week => (back(7), tomorrow),
    ReportRange.month => (back(30), tomorrow),
    ReportRange.custom when p.custom != null => (
      DateTime(
        p.custom!.start.year,
        p.custom!.start.month,
        p.custom!.start.day,
      ),
      DateTime(p.custom!.end.year, p.custom!.end.month, p.custom!.end.day + 1),
    ),
    _ => (null, null),
  };
}

bool inPeriod(DateTime t, ReportPeriod p, DateTime now) {
  final (start, end) = periodBounds(p, now);
  return (start == null || !t.isBefore(start)) &&
      (end == null || t.isBefore(end));
}

/// Amount per chart bar for [p]: week → 7 days, month → 5 × 6 days, custom
/// → days (≤14) / weeks (≤120 days) / months, all → months (last 12).
List<TrendBucket> amountBuckets(
  Iterable<(DateTime, double)> points,
  ReportPeriod p,
  DateTime now,
) {
  final list = points.toList();
  var (start, end) = periodBounds(p, now);
  end ??= DateTime(now.year, now.month, now.day + 1);
  start ??= list.isEmpty
      ? DateTime(now.year, now.month)
      : list.map((e) => e.$1).reduce((a, b) => a.isBefore(b) ? a : b);
  final days = end.difference(start).inDays;

  // Months: calendar months, at most the last 12.
  if (p.range == ReportRange.all || days > 120) {
    var m = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    final months = <DateTime>[];
    while (!m.isAfter(last) && !(m == last && end == last)) {
      months.add(m);
      m = DateTime(m.year, m.month + 1);
    }
    final shown = months.length > 12
        ? months.sublist(months.length - 12)
        : months;
    return [
      for (final mo in shown)
        TrendBucket(
          DateFormat('MMM').format(mo),
          list
              .where((e) => e.$1.year == mo.year && e.$1.month == mo.month)
              .fold<double>(0, (a, e) => a + e.$2)
              .round(),
        ),
    ];
  }

  final (slots, size, label) = switch (p.range) {
    ReportRange.week => (7, 1, 'E'),
    ReportRange.month => (5, 6, 'd/M'),
    _ when days <= 14 => (days, 1, 'd'),
    _ => ((days / 7).ceil(), 7, 'd/M'),
  };
  final totals = List<double>.filled(slots, 0);
  for (final (t, amount) in list) {
    final i = t.difference(start).inDays ~/ size;
    if (i >= 0 && i < slots) totals[i] += amount;
  }
  return [
    for (var i = 0; i < slots; i++)
      TrendBucket(() {
        final s = DateFormat(
          label,
        ).format(start!.add(Duration(days: i * size)));
        return label == 'E' ? s.substring(0, 2) : s;
      }(), totals[i].round()),
  ];
}

/// One row of a grouped table (a product, category, customer…).
class Tally {
  final String label;
  final String sub;
  int count = 0;
  int quantity = 0;
  double amount = 0;

  /// Cost of what was sold (product cost price × quantity), for profit.
  double cost = 0;
  DateTime? last;

  /// What the row groups by (e.g. the customer id; '' for walk-ins).
  final String key;
  Tally(this.label, [this.sub = '', this.key = '']);

  void add({
    int count = 1,
    int quantity = 0,
    required double amount,
    double cost = 0,
    DateTime? at,
  }) {
    this.cost += cost;
    this.count += count;
    this.quantity += quantity;
    this.amount += amount;
    if (at != null && (last == null || at.isAfter(last!))) last = at;
  }
}

List<Tally> _sorted(Map<String, Tally> m) =>
    m.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));

/// Units and revenue per product, from the sales' line items.
List<Tally> salesByProduct(Iterable<Sale> sales, List<Product> products) {
  final byId = {for (final p in products) p.id: p};
  final m = <String, Tally>{};
  for (final s in sales) {
    for (final it in s.items) {
      final key = it.productId.isEmpty ? it.productName : it.productId;
      final p = byId[it.productId];
      (m[key] ??= Tally(
        p?.productName ?? it.productName,
        p?.category ?? '',
      )).add(
        quantity: it.quantity,
        amount: it.price * it.quantity,
        cost: (it.costPrice ?? p?.costPrice ?? 0) * it.quantity,
        at: s.billDate,
      );
    }
  }
  return _sorted(m);
}

/// Units and revenue per product category.
List<Tally> salesByCategory(Iterable<Sale> sales, List<Product> products) {
  final byId = {for (final p in products) p.id: p};
  final m = <String, Tally>{};
  for (final s in sales) {
    for (final it in s.items) {
      final c = byId[it.productId]?.category ?? '';
      final name = c.isEmpty ? 'Uncategorised' : c;
      (m[name] ??= Tally(
        name,
      )).add(quantity: it.quantity, amount: it.price * it.quantity);
    }
  }
  return _sorted(m);
}

/// Per customer: invoices, total bought, last purchase (walk-ins together).
List<Tally> purchasesByCustomer(
  Iterable<Sale> sales,
  List<Customer> customers,
) {
  final byId = {for (final c in customers) c.id: c};
  final m = <String, Tally>{};
  for (final s in sales) {
    final c = byId[s.customerId];
    final key = s.customerId ?? '';
    (m[key] ??= Tally(
      c?.name ?? (key.isEmpty ? 'Walk-in' : (s.customerName ?? 'Customer')),
      c?.shopName ?? c?.phone ?? '',
      key,
    )).add(
      quantity: s.items.fold(0, (a, it) => a + it.quantity),
      amount: s.totalAmount,
      at: s.billDate,
    );
  }
  return _sorted(m);
}

/// Units and revenue in one product category, split by size.
class CategorySales {
  final String name;
  int quantity = 0;
  double amount = 0;
  final _sizes = <String, Tally>{};

  /// Per size: who bought it, and which products, keyed by customer id
  /// ('' = walk-in) and product id.
  final _buyers = <String, Map<String, Tally>>{};
  final _products = <String, Map<String, Tally>>{};
  CategorySales(this.name);

  /// Sizes, most units sold first.
  List<Tally> get sizes =>
      _sizes.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));

  /// Customers who bought [size], most units first.
  List<Tally> buyersOf(String size) => _byUnits(_buyers[size]);

  /// Products sold in [size], most units first.
  List<Tally> productsOf(String size) => _byUnits(_products[size]);

  static List<Tally> _byUnits(Map<String, Tally>? m) =>
      (m?.values.toList() ?? <Tally>[])
        ..sort((a, b) => b.quantity.compareTo(a.quantity));
}

/// A sold line's size: its variant's size, else the size in the saved
/// label ("M / Blue"), else the product's own size.
String _sizeOf(SaleItem it, Product? p) {
  if (it.variantId != null && p != null) {
    final v = p.variants.where((v) => v.id == it.variantId).firstOrNull;
    if (v != null) {
      final s = v.size?.trim() ?? '';
      return s.isEmpty ? 'No size' : s;
    }
  }
  final fromLabel = it.variantLabel?.split(' / ').first.trim() ?? '';
  if (fromLabel.isNotEmpty) return fromLabel;
  final own = p?.size?.trim() ?? '';
  return own.isEmpty ? 'No size' : own;
}

/// Units and revenue per category and, within it, per size (with who
/// bought each size and which products) — categories with the most units
/// first.
List<CategorySales> salesByCategorySize(
  Iterable<Sale> sales,
  List<Product> products, [
  List<Customer> customers = const [],
]) {
  final byId = {for (final p in products) p.id: p};
  final people = {for (final c in customers) c.id: c};
  final m = <String, CategorySales>{};
  for (final s in sales) {
    final buyerKey = s.customerId ?? '';
    final buyer = people[s.customerId];
    for (final it in s.items) {
      final p = byId[it.productId];
      final c = p?.category ?? '';
      final cat = m[c.isEmpty ? 'Uncategorised' : c] ??= CategorySales(
        c.isEmpty ? 'Uncategorised' : c,
      );
      cat.quantity += it.quantity;
      cat.amount += it.amount;
      final size = _sizeOf(it, p);
      (cat._sizes[size] ??= Tally(
        size,
      )).add(quantity: it.quantity, amount: it.amount, at: s.billDate);
      ((cat._buyers[size] ??= {})[buyerKey] ??= Tally(
        buyer?.name ??
            (buyerKey.isEmpty ? 'Walk-in' : (s.customerName ?? 'Customer')),
        buyer?.shopName ?? '',
        buyerKey,
      )).add(quantity: it.quantity, amount: it.amount, at: s.billDate);
      ((cat._products[size] ??= {})[it.productId] ??= Tally(
        p?.productName ?? it.productName,
      )).add(quantity: it.quantity, amount: it.amount, at: s.billDate);
    }
  }
  return m.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));
}

/// One product's sales: units and revenue per size, and how many of each
/// size every customer bought.
class ProductSales {
  final String name, category;
  int quantity = 0;
  double amount = 0;
  DateTime? last;

  /// The product's own size order (S, M, L…); sizes no longer on it follow.
  final List<String> _order;
  final _sizes = <String, Tally>{};
  final _buyers = <String, Tally>{};
  final _buyerSizes = <String, Map<String, int>>{};
  ProductSales(this.name, this.category, this._order);

  /// Sizes in the product's order, then any others by units.
  List<Tally> get sizes {
    int rank(String s) {
      final i = _order.indexOf(s);
      return i == -1 ? _order.length : i;
    }

    return _sizes.values.toList()..sort((a, b) {
      final r = rank(a.label).compareTo(rank(b.label));
      return r != 0 ? r : b.quantity.compareTo(a.quantity);
    });
  }

  /// Customers, most units first (key = customer id, '' = walk-in).
  List<Tally> get buyers =>
      _buyers.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));

  /// Units of [size] bought by the customer with [buyerKey].
  int unitsOf(String buyerKey, String size) =>
      _buyerSizes[buyerKey]?[size] ?? 0;
}

/// Per product: units and revenue by size and by customer × size — most
/// revenue first.
List<ProductSales> salesByProductSize(
  Iterable<Sale> sales,
  List<Product> products, [
  List<Customer> customers = const [],
]) {
  final byId = {for (final p in products) p.id: p};
  final people = {for (final c in customers) c.id: c};
  final m = <String, ProductSales>{};
  for (final s in sales) {
    final buyerKey = s.customerId ?? '';
    final buyer = people[s.customerId];
    for (final it in s.items) {
      final p = byId[it.productId];
      final key = it.productId.isEmpty ? it.productName : it.productId;
      final ps = m[key] ??= ProductSales(
        p?.productName ?? it.productName,
        p?.category ?? '',
        <String>{
          for (final v in p?.variants ?? const <ProductVariant>[])
            if ((v.size?.trim() ?? '').isNotEmpty) v.size!.trim(),
        }.toList(),
      );
      final size = _sizeOf(it, p);
      ps.quantity += it.quantity;
      ps.amount += it.amount;
      if (ps.last == null || s.billDate.isAfter(ps.last!)) ps.last = s.billDate;
      (ps._sizes[size] ??= Tally(
        size,
      )).add(quantity: it.quantity, amount: it.amount, at: s.billDate);
      (ps._buyers[buyerKey] ??= Tally(
        buyer?.name ??
            (buyerKey.isEmpty ? 'Walk-in' : (s.customerName ?? 'Customer')),
        buyer?.shopName ?? '',
        buyerKey,
      )).add(quantity: it.quantity, amount: it.amount, at: s.billDate);
      final bs = ps._buyerSizes[buyerKey] ??= {};
      bs[size] = (bs[size] ?? 0) + it.quantity;
    }
  }
  return m.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
}

/// Spend and entries per expense category.
List<Tally> expensesByCategory(Iterable<Expense> expenses) {
  final m = <String, Tally>{};
  for (final e in expenses) {
    final name = e.category.isEmpty ? 'Other' : e.category;
    (m[name] ??= Tally(name)).add(amount: e.amount, at: e.expenseDate);
  }
  return _sorted(m);
}

/// Profit & loss for a set of sales and expenses. Cost of goods sold uses
/// each sale line's saved cost (the product's cost when it was sold), else
/// the product's current cost; lines with neither count as zero cost and
/// are counted in [uncostedLines].
class ProfitLoss {
  final double grossSales, tax, cogs, expenses;

  /// [grossSales] split by bill type (each incl. any GST on it).
  final double gstBillSales, secondaryBillSales;
  final int uncostedLines;
  const ProfitLoss({
    required this.grossSales,
    required this.tax,
    required this.cogs,
    required this.expenses,
    required this.uncostedLines,
    this.gstBillSales = 0,
    this.secondaryBillSales = 0,
  });

  /// Sales without the tax collected (tax isn't income).
  double get netSales => grossSales - tax;
  double get grossProfit => netSales - cogs;
  double get netProfit => grossProfit - expenses;

  /// % of net sales; null with no sales.
  double? margin(double v) => netSales == 0 ? null : v / netSales * 100;

  factory ProfitLoss.of(
    Iterable<Sale> allSales,
    Iterable<Expense> expenses,
    List<Product> products,
  ) {
    final sales = allSales.where((s) => s.countsInSales);
    final cost = {for (final p in products) p.id: p.costPrice};
    var cogs = 0.0, uncosted = 0;
    for (final s in sales) {
      for (final it in s.items) {
        final c = it.costPrice ?? cost[it.productId] ?? 0;
        if (c <= 0) uncosted++;
        cogs += c * it.quantity;
      }
    }
    return ProfitLoss(
      grossSales: sales.fold(0, (a, s) => a + s.totalAmount),
      tax: sales.fold(0, (a, s) => a + s.taxAmount),
      cogs: cogs,
      expenses: expenses.fold(0, (a, e) => a + e.amount),
      uncostedLines: uncosted,
      gstBillSales: sales
          .where((s) => s.isGst)
          .fold(0, (a, s) => a + s.totalAmount),
      secondaryBillSales: sales
          .where((s) => !s.isGst)
          .fold(0, (a, s) => a + s.totalAmount),
    );
  }
}

/// One row of the P&L-by-period table.
typedef ProfitRow = ({String label, int sales, int cogs, int expenses});

/// Net sales, cost of goods and expenses per chart bucket of [p] (same
/// buckets as the charts), so each row's profit is sales − cogs − expenses.
List<ProfitRow> profitByPeriod(
  Iterable<Sale> allSales,
  Iterable<Expense> expenses,
  List<Product> products,
  ReportPeriod p,
  DateTime now,
) {
  final sales = allSales.where((s) => s.countsInSales);
  final cost = {for (final pr in products) pr.id: pr.costPrice};
  final s = [for (final x in sales) (x.billDate, x.totalAmount - x.taxAmount)];
  final c = [
    for (final x in sales)
      (
        x.billDate,
        x.items.fold<double>(
          0,
          (a, it) =>
              a + (it.costPrice ?? cost[it.productId] ?? 0) * it.quantity,
        ),
      ),
  ];
  final e = [for (final x in expenses) (x.expenseDate, x.amount)];
  // Zero points on every date keep the three series on the same buckets.
  final zeros = [
    for (final x in [...s, ...e]) (x.$1, 0.0),
  ];
  final sb = amountBuckets([...s, ...zeros], p, now);
  final cb = amountBuckets([...c, ...zeros], p, now);
  final eb = amountBuckets([...e, ...zeros], p, now);
  return [
    for (var i = 0; i < sb.length; i++)
      (
        label: sb[i].label,
        sales: sb[i].count,
        cogs: cb[i].count,
        expenses: eb[i].count,
      ),
  ];
}

/// One chart bucket split by bill type: GST bills vs secondary bills.
typedef BillTypeRow = ({String label, int gst, int secondary});

/// Invoice value per chart bucket of [p] for GST and secondary bills (same
/// buckets as the other charts, so the two series line up).
List<BillTypeRow> salesByBillType(
  Iterable<Sale> sales,
  ReportPeriod p,
  DateTime now,
) {
  final g = [
    for (final s in sales)
      if (s.isGst) (s.billDate, s.totalAmount),
  ];
  final sec = [
    for (final s in sales)
      if (!s.isGst) (s.billDate, s.totalAmount),
  ];
  // Zero points on every date keep both series on the same buckets.
  final zeros = [for (final s in sales) (s.billDate, 0.0)];
  final gb = amountBuckets([...g, ...zeros], p, now);
  final sb = amountBuckets([...sec, ...zeros], p, now);
  return [
    for (var i = 0; i < gb.length; i++)
      (label: gb[i].label, gst: gb[i].count, secondary: sb[i].count),
  ];
}

/// GST collected at one rate: the taxable value it was charged on, the tax
/// and how many bills.
typedef GstRateRow = ({double rate, double taxable, double tax, int bills});

/// GST bills grouped by their GST %, highest tax first. Bills with 0% are
/// left out (no GST was collected on them).
List<GstRateRow> gstByRate(Iterable<Sale> sales) {
  final m = <double, ({double taxable, double tax, int bills})>{};
  for (final s in sales) {
    if (!s.isGst || s.taxAmount <= 0) continue;
    final rate =
        s.taxPercentage ??
        (s.subtotal > 0 ? s.taxAmount / s.subtotal * 100 : 0);
    final key = (rate * 100).round() / 100;
    final cur = m[key] ?? (taxable: 0.0, tax: 0.0, bills: 0);
    m[key] = (
      taxable: cur.taxable + s.subtotal,
      tax: cur.tax + s.taxAmount,
      bills: cur.bills + 1,
    );
  }
  return [
    for (final e in m.entries)
      (
        rate: e.key,
        taxable: e.value.taxable,
        tax: e.value.tax,
        bills: e.value.bills,
      ),
  ]..sort((a, b) => b.tax.compareTo(a.tax));
}
