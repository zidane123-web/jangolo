import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that fetches a user's full name from Firestore based on their ID.
final userFullNameProvider =
    FutureProvider.family<String?, String>((ref, userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(userId)
        .get();
    final data = doc.data();
    if (data == null) return null;
    final first = data['firstName'] as String? ?? '';
    final last = data['lastName'] as String? ?? '';
    final fullName = '$first $last'.trim();
    return fullName.isEmpty ? null : fullName;
  } catch (_) {
    return null;
  }
});
