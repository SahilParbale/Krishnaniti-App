class AppConfig {
  AppConfig._();

  static const String appName = 'Nagarsevak Management';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://qdvciisgxvupvrjygedr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkdmNpaXNneHZ1cHZyanlnZWRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwODkzNjAsImV4cCI6MjA4NDY2NTM2MH0.FEoUycRHAu7NxqfUosHO0_dVwB1DKdXHLGsxChpw8V0';

  // Default Tenant UUID (from database migration)
  static const String defaultTenantId = 'bf1a3e36-464e-4eff-b21d-dc71f5a5a582';
}
