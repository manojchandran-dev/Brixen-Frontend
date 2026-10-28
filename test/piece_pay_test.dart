import 'package:brixen/features/payroll/domain/piece_pay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('piece pay in combos counts the pieces in each', () {
    final p = PiecePay.fromJson({
      'id': 'PPAY1',
      'employee_id': 3,
      'employee': {'id': 3, 'employee_code': 'EMP3', 'name': 'Anand'},
      'work_type_id': 'WT1',
      'work_type_name': 'Hand',
      'product_id': 'P1',
      'product_name': 'Billa shorts',
      'pay_date': '2026-10-29',
      'unit': 'COMBO',
      'quantity': 10,
      'combo_size': 12,
      'pieces': 120,
      'rate': 0.5,
      'amount': 60,
      'status': 'DRAFT',
    });
    expect(p.isCombo, isTrue);
    expect(p.isConfirmed, isFalse);
    expect(p.quantityLabel, '10 combos of Billa shorts (12 each) = 120 pieces');
    expect(p.amount, 60);

    final loose = PiecePay.fromJson({
      'id': 'PPAY2',
      'employee': {'id': 3, 'name': 'Anand'},
      'unit': 'PIECE',
      'quantity': 250,
      'pieces': 250,
      'rate': 0.4,
      'amount': 100,
      'status': 'CONFIRMED',
    });
    expect(loose.quantityLabel, '250 pieces');
    expect(loose.isConfirmed, isTrue);
  });
}
