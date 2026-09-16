import '../models/affiliation_model.dart';

/// Canonical affiliation order: university → city → interest.
/// Stable within each type (insertion order preserved).
/// Matches TRIBE's data model (max 1 uni, max 1 city, max 6 interests).
List<AffiliationModel> sortAffiliationsByType(List<AffiliationModel> input) {
  const order = {'university': 0, 'city': 1, 'interest': 2};
  final indexed = input.asMap().entries.toList();
  indexed.sort((a, b) {
    final ta = order[a.value.type] ?? 99;
    final tb = order[b.value.type] ?? 99;
    if (ta != tb) return ta.compareTo(tb);
    return a.key.compareTo(b.key); // stable within type
  });
  return indexed.map((e) => e.value).toList();
}
