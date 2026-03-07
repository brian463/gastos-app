import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Solo en Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SheetsApi {
  final String baseUrl; // URL /exec (Apps Script Web App)
  final String token;   // API_TOKEN
  final String user;    // "brian" o tu email
   
  SheetsApi({
    required this.baseUrl,
    required this.token,
    required this.user,
  });

  /// En Web usamos x-www-form-urlencoded para evitar preflight CORS.
  /// En otras plataformas usamos http JSON normal.
  Future<Map<String, dynamic>> getMonthSummary({required int year, required int month}) async {
  return await post("getMonthSummary", {"year": year, "month": month});
  }
  Future<Map<String, dynamic>> post(String action, Map<String, dynamic> data) async {
    final payload = {
      "token": token,
      "action": action,
      "user": user,
      ...data,
    };

    if (kIsWeb) {
      return _postWebForm(payload);
    } else {
      return _postJson(payload);
    }
  }

  // ---------------- Web (Flutter Web) ----------------
  Future<Map<String, dynamic>> _postWebForm(Map<String, dynamic> payload) async {
    final completer = Completer<Map<String, dynamic>>();

    try {
      final req = html.HttpRequest();

      // Form-URL-Encoded (simple request -> menos CORS problemas)
      req.open('POST', baseUrl, async: true);
      req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

      req.onLoad.listen((_) {
        // ignore: avoid_print
        print('WEB STATUS: ${req.status}');
        // ignore: avoid_print
        print('WEB RESPONSE: ${req.responseText}');

        try {
          final txt = req.responseText ?? '{}';
          final decoded = jsonDecode(txt);
          completer.complete(Map<String, dynamic>.from(decoded));
        } catch (e) {
          completer.complete({
            "ok": false,
            "error": "JSON_DECODE_ERROR",
            "raw": req.responseText ?? "",
          });
        }
      });

      req.onError.listen((_) {
        // ignore: avoid_print
        print('WEB ERROR (HttpRequest)');
        completer.complete({
          "ok": false,
          "error": "HTTP_REQUEST_ERROR",
        });
      });

      // Encode form body
      final body = _toFormUrlEncoded(payload);
      req.send(body);
    } catch (e) {
      // ignore: avoid_print
      print('WEB EXCEPTION: $e');
      completer.complete({"ok": false, "error": e.toString()});
    }

    return completer.future;
  }

  String _toFormUrlEncoded(Map<String, dynamic> m) {
    return m.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
  }

  // ---------------- Non-Web ----------------
  Future<Map<String, dynamic>> _postJson(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    // ignore: avoid_print
    print('STATUS: ${res.statusCode}');
    // ignore: avoid_print
    print('BODY: ${res.body}');

    final decoded = jsonDecode(res.body);
    return Map<String, dynamic>.from(decoded);
  }

  // ---------------- Public API methods ----------------

  Future<Map<String, dynamic>> addExpense({
    required String date,
    required String category,
    required double amount,
    String note = "",
  }) async {
    return await post("addExpense", {
      "date": date,
      "category": category,
      "amount": amount,
      "note": note,
    });
  }

  Future<Map<String, dynamic>> addIncome({
    required String date,
    required double amount,
    String note = "",
  }) async {
    return await post("addIncome", {
      "date": date,
      "amount": amount,
      "note": note,
    });
  }

  Future<Map<String, dynamic>> getMonthData({
    required int year,
    required int month,
  }) async {
    return await post("getMonthData", {
      "year": year,
      "month": month,
    });
  }

  Future<Map<String, dynamic>> setBudget({
    required int year,
    required int month,
    required String mode,
    required double percent,
    required double fixedAmount,
  }) async {
    return await post("setBudget", {
      "year": year,
      "month": month,
      "mode": mode,
      "percent": percent,
      "fixedAmount": fixedAmount,
    });
  }

  Future<Map<String, dynamic>> setSettings({
    required bool alertsEnabled,
    required double alertsThreshold,
    required String themeMode,
  }) async {
    return await post("setSettings", {
      "alertsEnabled": alertsEnabled,
      "alertsThreshold": alertsThreshold,
      "themeMode": themeMode,
    });
  }
}