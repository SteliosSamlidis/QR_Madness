class EntryPhoto {
  final String url;
  final String description;
  final bool done;

  const EntryPhoto({
    required this.url,
    required this.description,
    this.done = false,
  });

  factory EntryPhoto.fromMap(Map<String, dynamic> map) => EntryPhoto(
        url: map['url'] as String,
        description: map['description'] as String? ?? '',
        done: map['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'url': url,
        'description': description,
        'done': done,
      };

  EntryPhoto copyWith({String? url, String? description, bool? done}) =>
      EntryPhoto(
        url: url ?? this.url,
        description: description ?? this.description,
        done: done ?? this.done,
      );
}
