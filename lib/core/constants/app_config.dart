class AppConfig {
  AppConfig._();

  static const String appName = 'Nagarsevak Management';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://qdvciisgxvupvrjygedr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkdmNpaXNneHZ1cHZyanlnZWRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwODkzNjAsImV4cCI6MjA4NDY2NTM2MH0.FEoUycRHAu7NxqfUosHO0_dVwB1DKdXHLGsxChpw8V0';

  // Default Tenant UUID (Krishnaniti tenant)
  static const String defaultTenantId = 'bf4c7152-6006-41b5-9c7d-84c76ea67da4';
}
