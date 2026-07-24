// lib/views/pages/paiement/cinetpay_webview_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/constants/api_constants.dart';

class CinetPayWebViewPage extends StatefulWidget {
  final num amount;
  final String? phone;

  const CinetPayWebViewPage({
    super.key,
    required this.amount,
    this.phone,
  });

  @override
  State<CinetPayWebViewPage> createState() => _CinetPayWebViewPageState();
}

class _CinetPayWebViewPageState extends State<CinetPayWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _paymentUrl;
  String? _reference;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initierPaiement();
  }

  Future<void> _initierPaiement() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/paiements/cinetpay/initier/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': widget.amount.toInt(),
          'phone': widget.phone ?? '',
          'payment_method': 'mtn_momo',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _paymentUrl = data['payment_url'];
          _reference = data['reference'];
        });
        _initWebView();
      } else {
        _showError('Erreur lors de l\'initialisation du paiement');
      }
    } catch (e) {
      _showError('Erreur réseau');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkPaymentCompletion(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkPaymentCompletion(url);
          },
          onWebResourceError: (error) {
            _showError('Erreur de chargement');
          },
        ),
      );

    if (_paymentUrl != null) {
      _controller.loadRequest(Uri.parse(_paymentUrl!));
    }
  }

  void _checkPaymentCompletion(String url) {
    if (url.contains('payment-result') || url.contains('success')) {
      if (!_paymentCompleted) {
        _paymentCompleted = true;
        _verifierPaiement();
      }
    }
  }

  Future<void> _verifierPaiement() async {
    final token = await _getToken();
    if (token == null || _reference == null) return;

    // Attendre quelques secondes pour que le webhook soit traité
    await Future.delayed(const Duration(seconds: 3));

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/wallet/solde/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Recharge réussie !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: const Color(0xFF2884A0),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_paymentUrl != null)
            WebViewWidget(controller: _controller)
          else
            const Center(child: CircularProgressIndicator()),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2884A0)),
              ),
            ),
        ],
      ),
    );
  }
}