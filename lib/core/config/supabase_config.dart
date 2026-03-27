import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client accessor.
/// Usage: `import 'package:voxmed/core/config/supabase_config.dart';`
/// Then use `supabase.from('table')...` or `supabase.auth...`
final supabase = Supabase.instance.client;
