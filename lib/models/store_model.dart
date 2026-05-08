import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String? pin;
  final String createdBy;
  final DateTime createdAt;

  const StoreModel({
    required this.id,
    required this.name,
    this.pin,
    required this.createdBy,
    required this.createdAt,
  });

  bool get hasPin => pin != null && pin!.isNotEmpty;

  factory StoreModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name'] as String,
      pin: data['pin'] as String?,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (hasPin) 'pin': pin,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
