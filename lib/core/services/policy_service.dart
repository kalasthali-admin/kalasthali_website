import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/site_policy.dart';

class PolicyService {
  PolicyService._();

  static final instance = PolicyService._();
  final _client = Supabase.instance.client;

  Future<SitePolicy> getPolicy(String slug) async {
    try {
      final rows =
          await _client.from('site_policies').select().eq('slug', slug).limit(1)
              as List;
      if (rows.isNotEmpty) {
        return SitePolicy.fromJson(rows.first as Map<String, dynamic>);
      }
    } catch (_) {
      // The public fallback keeps legal pages available before first setup.
    }
    return policyForSlug(slug);
  }
}
