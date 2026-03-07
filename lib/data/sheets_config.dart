// lib/data/sheets_config.dart

// Se pasan al compilar con: --dart-define=SHEETS_URL=... --dart-define=SHEETS_TOKEN=... --dart-define=SHEETS_USER=...
const String kSheetsUrl = String.fromEnvironment('SHEETS_URL', defaultValue: '');
const String kSheetsToken = String.fromEnvironment('SHEETS_TOKEN', defaultValue: '');
const String kSheetsUser = String.fromEnvironment('SHEETS_USER', defaultValue: 'brian');

bool sheetsConfigOk() => kSheetsUrl.isNotEmpty && kSheetsToken.isNotEmpty;