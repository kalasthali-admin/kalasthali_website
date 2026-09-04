class UserAccount {
  const UserAccount({
    required this.id,
    this.receiverName,
    this.addressLine1,
    this.addressLine2,
    this.statePincode,
  });

  final String id;
  final String? receiverName;
  final String? addressLine1;
  final String? addressLine2;
  final String? statePincode;

  bool get hasDeliveryAddress =>
      _hasValue(receiverName) &&
      _hasValue(addressLine1) &&
      _hasValue(statePincode);

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
    id: json['id'] as String,
    receiverName: json['receiver_name'] as String?,
    addressLine1: json['address_line1'] as String?,
    addressLine2: json['address_line2'] as String?,
    statePincode: json['state_pincode'] as String?,
  );

  static bool _hasValue(String? value) => value?.trim().isNotEmpty == true;
}
