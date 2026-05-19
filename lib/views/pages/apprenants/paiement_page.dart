// lib/views/pages/paiement/paiement_page.dart
// ════════════════════════════════════════════════════════════════
// PAGE DE PAIEMENT UNIFIÉE - CINETPAY UNIQUEMENT
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

// Palette harmonisée
const Color _primary = Color(0xFF135F74);
//const Color _gold = Color(0xFFC5A059);
const Color _bg = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);

/// Types de paiement supportés
enum PaiementType {
  rechargeWallet,
  accesDepartement,
  olympiade,
  abonnementMensuel,
  abonnementAnnuel,
}

/// Moyens de paiement CinetPay
enum CinetPayMethod {
  mtn,
  orange,
  carte,
}

class PaiementPage extends StatefulWidget {
  final PaiementType type;
  final int? departementId;
  final int? olympiadeId;
  final String titre;
  final int montant;

  const PaiementPage({
    super.key,
    required this.type,
    this.departementId,
    this.olympiadeId,
    required this.titre,
    required this.montant,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  CinetPayMethod _selectedMethod = CinetPayMethod.mtn;
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String _getTypePaiementString() {
    switch (widget.type) {
      case PaiementType.rechargeWallet:
        return 'wallet_recharge';
      case PaiementType.accesDepartement:
        return 'acces_departement';
      case PaiementType.olympiade:
        return 'olympiade';
      case PaiementType.abonnementMensuel:
        return 'abonnement_mensuel';
      case PaiementType.abonnementAnnuel:
        return 'abonnement_annuel';
    }
  }

  String _getPaymentMethodString() {
    switch (_selectedMethod) {
      case CinetPayMethod.mtn:
        return 'mtn_momo';
      case CinetPayMethod.orange:
        return 'orange_money';
      case CinetPayMethod.carte:
        return 'card';
    }
  }

  Future<void> _initierPaiement() async {
    // Validation
    if (_selectedMethod != CinetPayMethod.carte) {
      if (_phoneController.text.trim().length < 9) {
        _showSnackBar('Veuillez entrer un numéro de téléphone valide (9 chiffres)', isError: true);
        return;
      }
    } else {
      if (_cardNumberController.text.trim().length < 16) {
        _showSnackBar('Veuillez entrer un numéro de carte valide', isError: true);
        return;
      }
      if (_cardExpiryController.text.trim().length < 5) {
        _showSnackBar('Veuillez entrer une date d\'expiration valide (MM/AA)', isError: true);
        return;
      }
      if (_cardCvvController.text.trim().length < 3) {
        _showSnackBar('Veuillez entrer un CVV valide', isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    final token = await _getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      _showSnackBar('Session expirée, veuillez vous reconnecter', isError: true);
      return;
    }

    try {
      final body = {
        'type_paiement': _getTypePaiementString(),
        'montant': widget.montant,
        'payment_method': _getPaymentMethodString(),
        'phone': _selectedMethod != CinetPayMethod.carte ? _phoneController.text.trim() : null,
      };

      if (widget.departementId != null) {
        body['departement_id'] = widget.departementId;
      }
      if (widget.olympiadeId != null) {
        body['olympiade_id'] = widget.olympiadeId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/paiements/cinetpay/initier/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['payment_url'];
        final reference = data['reference'];

        if (paymentUrl != null && mounted) {
          // Ouvrir la WebView CinetPay
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CinetPayWebView(
                paymentUrl: paymentUrl,
                reference: reference,
                titre: widget.titre,
                montant: widget.montant,
              ),
            ),
          );

          if (success == true && mounted) {
            // Paiement réussi
            Navigator.pop(context, true);
            _showSnackBar('✅ Paiement réussi !', isError: false);
          }
        }
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(error['detail'] ?? 'Erreur lors de l\'initialisation du paiement', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur réseau: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Récapitulatif
            _buildRecapCard(),
            const SizedBox(height: 24),

            // Choix du moyen de paiement
            const Text(
              'Moyen de paiement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
            ),
            const SizedBox(height: 12),
            _buildMethodSelector(),
            const SizedBox(height: 24),

            // Formulaire selon méthode
            _buildPaymentForm(),
            const SizedBox(height: 32),

            // Bouton de paiement
            _buildPayButton(),
            const SizedBox(height: 16),

            // Sécurité
            _buildSecurityFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapCard() {
    String typeLabel;
    switch (widget.type) {
      case PaiementType.rechargeWallet:
        typeLabel = 'Recharge portefeuille';
        break;
      case PaiementType.accesDepartement:
        typeLabel = 'Accès à la formation';
        break;
      case PaiementType.olympiade:
        typeLabel = 'Inscription olympiade';
        break;
      case PaiementType.abonnementMensuel:
        typeLabel = 'Abonnement mensuel';
        break;
      case PaiementType.abonnementAnnuel:
        typeLabel = 'Abonnement annuel';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: _primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: const TextStyle(fontSize: 12, color: _textLight),
                    ),
                    Text(
                      widget.titre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant total', style: TextStyle(fontSize: 14, color: _textMedium)),
              Text(
                '${widget.montant} FCFA',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _methodTile(
            icon: Icons.phone_android_rounded,
            label: 'MTN\nMobile Money',
            color: const Color(0xFFFFCC00),
            selected: _selectedMethod == CinetPayMethod.mtn,
            onTap: () => setState(() => _selectedMethod = CinetPayMethod.mtn),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _methodTile(
            icon: Icons.phone_android_rounded,
            label: 'Orange\nMoney',
            color: const Color(0xFFFF6600),
            selected: _selectedMethod == CinetPayMethod.orange,
            onTap: () => setState(() => _selectedMethod = CinetPayMethod.orange),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _methodTile(
            icon: Icons.credit_card_rounded,
            label: 'Carte\nBancaire',
            color: _primary,
            selected: _selectedMethod == CinetPayMethod.carte,
            onTap: () => setState(() => _selectedMethod = CinetPayMethod.carte),
          ),
        ),
      ],
    );
  }

  Widget _methodTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE0E4E8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : _textLight, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? color : _textMedium,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedMethod == CinetPayMethod.carte) {
      return _buildCardForm();
    }
    return _buildMobileForm();
  }

  Widget _buildMobileForm() {
    final isMtn = _selectedMethod == CinetPayMethod.mtn;
    final color = isMtn ? const Color(0xFFFFCC00) : const Color(0xFFFF6600);
    final label = isMtn ? 'Numéro MTN' : 'Numéro Orange';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                isMtn ? 'MTN Mobile Money' : 'Orange Money',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              labelText: '$label (ex: 6XXXXXXXX)',
              prefixText: '+237 ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: _textMedium),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous recevrez une notification de confirmation sur votre téléphone.',
                    style: TextStyle(fontSize: 12, color: _textMedium),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card_rounded, color: _primary),
              SizedBox(width: 8),
              Text(
                'Carte bancaire',
                style: TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nom sur la carte',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Numéro de carte',
              hintText: 'XXXX XXXX XXXX XXXX',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cardExpiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'MM/AA',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cardCvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _initierPaiement,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: _white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Payer ${widget.montant} FCFA',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.security_rounded, size: 14, color: _textLight),
        const SizedBox(width: 6),
        Text(
          'Paiement 100% sécurisé via CinetPay',
          style: TextStyle(fontSize: 12, color: _textLight),
        ),
      ],
    );
  }
}

// WebView CinetPay intégrée
class CinetPayWebView extends StatefulWidget {
  final String paymentUrl;
  final String reference;
  final String titre;
  final int montant;

  const CinetPayWebView({
    super.key,
    required this.paymentUrl,
    required this.reference,
    required this.titre,
    required this.montant,
  });

  @override
  State<CinetPayWebView> createState() => _CinetPayWebViewState();
}

class _CinetPayWebViewState extends State<CinetPayWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
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
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur de chargement: ${error.description}'),
                backgroundColor: _red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentCompletion(String url) {
    // CinetPay redirige vers notify_url ou return_url
    if (url.contains('payment-result') || 
        url.contains('success') || 
        url.contains('cinetpay.com/success')) {
      if (!_paymentCompleted) {
        _paymentCompleted = true;
        _verifierPaiement();
      }
    }
  }

  Future<void> _verifierPaiement() async {
    // Attendre que le webhook soit traité
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paiement effectué avec succès !'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement - ${widget.titre}'),
        backgroundColor: _primary,
        foregroundColor: _white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
        ],
      ),
    );
  }
}

// Formatters pour carte bancaire
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    String str = digits;
    if (digits.length >= 2) {
      str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}