const String kSheetsUrl =
    "https://script.google.com/macros/s/AKfycbyHAD0bSYgGExx2h8QZpLfybjO2b65UkzmJyFZ0JtX--LX4KBJt4UtrNbw0JWogsUwuog/exec";

const String kSheetsToken =
    "brian_2026!Gastos#Web@P3ru_x7Qm9Z1vK2sR5tN825";

const String kSheetsUser = "brian";

bool sheetsConfigOk() => kSheetsUrl.isNotEmpty && kSheetsToken.isNotEmpty;