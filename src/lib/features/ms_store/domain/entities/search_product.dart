import 'package:flutter/foundation.dart';

@immutable
class const SearchProduct({
  required final String id,
  required final String title,
  required final String description,
  required final String publisherName,
  required final String displayPrice,
  required final String productFamilyName,
  required final String iconUrl,
  required final String posterUrl,
  required final String posterBackgroundColor,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          publisherName == other.publisherName &&
          iconUrl == other.iconUrl &&
          posterUrl == other.posterUrl;

  @override
  int get hashCode => Object.hash(id, title, publisherName, iconUrl, posterUrl);

  @override
  String toString() => 'SearchProduct(id: $id, title: $title)';
}
