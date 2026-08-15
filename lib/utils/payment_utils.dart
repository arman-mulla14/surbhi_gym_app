import '../models/member.dart';
import '../models/payment.dart';

enum PaymentStatus { paid, unpaid, partiallyPaid, overdue, dueSoon, dueToday }

class PaymentUtils {
  static double getTotalPaid(List<Payment> payments) {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  static DateTime calculateNextDueDate(Member member, List<Payment> payments) {
    double totalPaid = getTotalPaid(payments);
    
    // Avoid division by zero
    double fee = member.feeAmount > 0 ? member.feeAmount : 1000.0;
    
    // Number of full cycles paid for
    int cyclesPaid = (totalPaid / fee).floor();
    
    // Next due date = joiningDate + (cyclesPaid * membershipDuration) days
    return member.joiningDate.add(Duration(days: cyclesPaid * member.membershipDuration));
  }

  static PaymentStatus calculateStatus(Member member, List<Payment> payments) {
    double totalPaid = getTotalPaid(payments);
    
    if (totalPaid == 0) {
      return PaymentStatus.unpaid;
    }
    
    DateTime nextDueDate = calculateNextDueDate(member, payments);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    
    if (dueDate.isBefore(today)) {
      return PaymentStatus.overdue;
    } else if (dueDate.isAtSameMomentAs(today)) {
      return PaymentStatus.dueToday;
    } else if (dueDate.difference(today).inDays <= 7) {
      return PaymentStatus.dueSoon;
    } else {
      // Check if partially paid for the current cycle
      double fee = member.feeAmount > 0 ? member.feeAmount : 1000.0;
      if (totalPaid % fee != 0) {
        return PaymentStatus.partiallyPaid;
      }
      return PaymentStatus.paid;
    }
  }

  static String getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.unpaid:
        return 'UNPAID';
      case PaymentStatus.partiallyPaid:
        return 'PARTIALLY PAID';
      case PaymentStatus.overdue:
        return 'OVERDUE';
      case PaymentStatus.dueSoon:
        return 'DUE SOON';
      case PaymentStatus.dueToday:
        return 'DUE TODAY';
    }
  }
}
