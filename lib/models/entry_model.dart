import 'package:cloud_firestore/cloud_firestore.dart';

import 'entry_photo.dart';

export 'entry_photo.dart';

enum EntryStatus { pending, completed }

class EntryModel {
  final String id;
  final String storeId;
  final String name;
  final String surname;
  final String prescriptionNumber;
  final List<EntryPhoto> photos;
  final EntryStatus status;
  final String createdBy;
  final String? createdByEmail;
  final DateTime createdAt;

  const EntryModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.surname,
    required this.prescriptionNumber,
    required this.photos,
    required this.status,
    required this.createdBy,
    this.createdByEmail,
    required this.createdAt,
  });

  // Convenience getter for thumbnail and legacy checks.
  String? get firstImageUrl => photos.isNotEmpty ? photos.first.url : null;

  factory EntryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Support both old single-imageUrl format and new photos array.
    final List<EntryPhoto> photos;
    final photosData = data['photos'] as List<dynamic>?;
    if (photosData != null) {
      photos = photosData
          .map((p) => EntryPhoto.fromMap(p as Map<String, dynamic>))
          .toList();
    } else {
      final legacyUrl = data['imageUrl'] as String?;
      photos = legacyUrl != null && legacyUrl.isNotEmpty
          ? [EntryPhoto(url: legacyUrl, description: '')]
          : [];
    }

    return EntryModel(
      id: doc.id,
      storeId: data['storeId'] as String? ?? '',
      name: data['name'] as String,
      surname: data['surname'] as String,
      prescriptionNumber: data['prescriptionNumber'] as String,
      photos: photos,
      status: EntryStatus.values.byName(data['status'] as String),
      createdBy: data['createdBy'] as String,
      createdByEmail: data['createdByEmail'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'name': name,
        'surname': surname,
        'prescriptionNumber': prescriptionNumber,
        'photos': photos.map((p) => p.toMap()).toList(),
        'status': status.name,
        'createdBy': createdBy,
        'createdByEmail': createdByEmail,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  EntryModel copyWith({
    String? storeId,
    String? name,
    String? surname,
    String? prescriptionNumber,
    List<EntryPhoto>? photos,
    EntryStatus? status,
    String? createdBy,
    String? createdByEmail,
    DateTime? createdAt,
  }) {
    return EntryModel(
      id: id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      prescriptionNumber: prescriptionNumber ?? this.prescriptionNumber,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
