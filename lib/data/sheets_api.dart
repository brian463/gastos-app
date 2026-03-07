import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;

// Solo en Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SheetsApi {
  final String baseUrl; // URL /exec
  final String token;   // API_TOKEN
  final String user;    // "brian" o email

  // Ajusta si quieres
  final Duration timeout;

  SheetsApi({
    required this.baseUrl,
    required this.token,
    required this.user,
    this.timeout = const Duration(seconds: 20),
  });

  // ---------------- Public API ----------------

  Future<Map<String, dynamic>> addExpense({
    required String date,
    required String category,
    required double amount,
    String note = "",
  }) async {
    return post("addExpense", {
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
    return post("addIncome", {
      "date": date,
      "amount": amount,
      "note": note,
    });
  }

  Future<Map<String, dynamic>> getMonthData({
    required int year,
    required int month,
  }) async {
    return post("getMonthData", {"year": year, "month": month});
  }

  Future<Map<String, dynamic>> getMonthSummary({
    required int year,
    required int month,
  }) async {
    return post("getMonthSummary", {"year": year, "month": month});
  }

  Future<Map<String, dynamic>> getAllData() async {
    return post("getAllData", {});
  }

  Future<Map<String, dynamic>> setBudget({
    required int year,
    required int month,
    required String mode,
    required double percent,
    required double fixedAmount,
  }) async {
    return post("setBudget", {
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
    return post("setSettings", {
      "alertsEnabled": alertsEnabled,
      "alertsThreshold": alertsThreshold,
      "themeMode": themeMode,
    });
  }

  // ---------------- Core request ----------------

  Future<Map<String, dynamic>> post(String action, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{
      "token": token,
      "action": action,
      "user": user,
      ...data,
    };

    if (kIsWeb) {
      return _postWebForm(payload).timeout(timeout);
    } else {
      return _postJson(payload).timeout(timeout);
    }
  }

  // ---------------- Web: form-urlencoded ----------------

  Future<Map<String, dynamic>> _postWebForm(Map<String, dynamic> payload) {
    final completer = Completer<Map<String, dynamic>>();

    try {
      final req = html.HttpRequest();

      req.open('POST', baseUrl, async: true);
      req.setRequestHeader(
        'Content-Type',
        'application/x-www-form-urlencoded; charset=UTF-8',
      );

      req.onLoad.listen((_) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('WEB STATUS: ${req.status}');
          // ignore: avoid_print
          print('WEB RESPONSE: ${req.responseText}');
        }

        final txt = req.responseText ?? '{}';
        try {
          final decoded = jsonDecode(txt);
          final map = Map<String, dynamic>.from(decoded);

          // si el server devolvió ok:false, igual lo devolvemos
          completer.complete(map);
        } catch (_) {
          completer.complete({
            "ok": false,
            "error": "JSON_DECODE_ERROR",
            "raw": txt,
          });
        }
      });

      req.onError.listen((_) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('WEB ERROR (HttpRequest)');
        }
        completer.complete({
          "ok": false,
          "error": "HTTP_REQUEST_ERROR",
        });
      });

      req.send(_toFormUrlEncoded(payload));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('WEB EXCEPTION: $e');
      }
      completer.complete({"ok": false, "error": e.toString()});
    }

    return completer.future;
  }

  String _toFormUrlEncoded(Map<String, dynamic> m) {
    return m.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
  }

  // ---------------- Non-web: JSON http ----------------

  Future<Map<String, dynamic>> _postJson(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('STATUS: ${res.statusCode}');
      // ignore: avoid_print
      print('BODY: ${res.body}');
    }

    try {
      final decoded = jsonDecode(res.body);
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return {
        "ok": false,
        "error": "JSON_DECODE_ERROR",
        "raw": res.body,
        "status": res.statusCode,
      };
    }
  }
}