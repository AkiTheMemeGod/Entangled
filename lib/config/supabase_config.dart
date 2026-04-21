class SupabaseConfig {
  static const String url = "https://wknpvgdpljkykhtofuiu.supabase.co";
  static const String anonKey =
      "sb_publishable_cQ5aShOCqcyhVumf_U4-sg_Q1XFmjTs";

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
