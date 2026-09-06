class OrderSuccessDetails {
  const OrderSuccessDetails({
    required this.orderId,
    required this.paymentId,
    required this.items,
    required this.address,
    required this.contactTarget,
  });

  final String orderId;
  final String paymentId;
  final List<OrderSuccessItem> items;
  final String address;
  final String contactTarget;
}

class OrderSuccessItem {
  const OrderSuccessItem({
    required this.name,
    required this.code,
    required this.quantity,
    required this.amount,
  });

  final String name;
  final String code;
  final int quantity;
  final int amount;
}
