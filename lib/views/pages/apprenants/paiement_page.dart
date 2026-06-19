// lib/views/pages/paiement/paiement_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE DE PAIEMENT UNIFIÉE - CINETPAY UNIQUEMENT
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:yeki/services/facture_service.dart';

enum PaiementType {
  rechargeWallet,
  accesDepartement,
  olympiade,
  abonnementMensuel,
  abonnementAnnuel,
}

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
  final int? montantPresentiel;
  final bool isCursus;
  final bool isHybride;
  final bool isFormation;

  const PaiementPage({
    super.key,
    required this.type,
    this.departementId,
    this.olympiadeId,
    required this.titre,
    required this.montant,
    this.montantPresentiel,
    this.isCursus = false,
    this.isHybride = false,
    this.isFormation = false,
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
  bool _genererFacture = true;
  bool _isAnnuel = false;

  int get _montantTotal => widget.montant + (widget.montantPresentiel ?? 0);
  
  int get _montantAnnuel {
    if (widget.isCursus) {
      return (_montantTotal * 0.85 * 12).round();
    }
    if (widget.isHybride) {
      return (_montantTotal * 0.85 * 12).round();
    }
    return (widget.montant * 0.85 * 12).round();
  }

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

  Future<void> _initierPaiement({bool annuel = false}) async {
    if (_selectedMethod != CinetPayMethod.carte) {
      if (_phoneController.text.trim().length < 9) {
        ErrorHandler.showError(context, 'Veuillez entrer un numéro de téléphone valide (9 chiffres)');
        return;
      }
    } else {
      if (_cardNumberController.text.trim().length < 16) {
        ErrorHandler.showError(context, 'Veuillez entrer un numéro de carte valide');
        return;
      }
      if (_cardExpiryController.text.trim().length < 5) {
        ErrorHandler.showError(context, 'Veuillez entrer une date d\'expiration valide (MM/AA)');
        return;
      }
      if (_cardCvvController.text.trim().length < 3) {
        ErrorHandler.showError(context, 'Veuillez entrer un CVV valide');
        return;
      }
    }

    setState(() => _isLoading = true);

    final token = await _getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, 'Session expirée, veuillez vous reconnecter');
      return;
    }

    final montantAPayer = annuel ? _montantAnnuel : _montantTotal;

    try {
      final body = {
        'type_paiement': _getTypePaiementString(),
        'montant': montantAPayer,
        'payment_method': _getPaymentMethodString(),
        'phone': _selectedMethod != CinetPayMethod.carte ? _phoneController.text.trim() : null,
        'is_annuel': annuel,
      };

      if (widget.departementId != null) {
        body['departement_id'] = widget.departementId;
      }
      if (widget.olympiadeId != null) {
        body['olympiade_id'] = widget.olympiadeId;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.paiementCinetpayInitier),
        headers: ApiHeaders.auth(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['payment_url'];
        final reference = data['reference'];

        if (paymentUrl != null && mounted) {
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CinetPayWebView(
                paymentUrl: paymentUrl,
                reference: reference,
                titre: widget.titre,
                montant: montantAPayer,
                type: widget.type,
                departementId: widget.departementId,
              ),
            ),
          );

          if (success == true && mounted) {
            if (_genererFacture && widget.type == PaiementType.accesDepartement) {
              await _genererFacturePDF(reference, montantAPayer, annuel);
            }
            if (mounted) {
              Navigator.pop(context, true);
              ErrorHandler.showSuccess(context, '✅ Paiement réussi !');
            }
          }
        }
      } else {
        final error = jsonDecode(response.body);
        ErrorHandler.showError(context, error['detail'] ?? 'Erreur lors de l\'initialisation du paiement');
      }
    } catch (e) {
      ErrorHandler.showError(context, 'Erreur réseau: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _genererFacturePDF(String reference, int montant, bool annuel) async {
    try {
      final token = await _getToken();
      final userResponse = await http.get(
        Uri.parse(ApiConstants.profilMe),
        headers: ApiHeaders.auth(token),
      );

      String nom = 'Apprenant Yéki';
      String email = '';
      if (userResponse.statusCode == 200) {
        final data = jsonDecode(userResponse.body);
        nom = '${data['first_name']} ${data['last_name']}'.trim();
        if (nom.isEmpty) nom = data['username'] ?? 'Apprenant';
        email = data['email'] ?? '';
      }

      final factureFile = await FactureService.genererFacture(
        reference: reference,
        clientNom: nom,
        clientEmail: email,
        description: widget.titre,
        montantLigne: widget.montant,
        montantPresentiel: widget.montantPresentiel ?? 0,
        montantTotal: montant,
        date: DateTime.now(),
        departementNom: widget.type == PaiementType.accesDepartement ? widget.titre : null, 
        //isAnnuel: annuel,
      );

      await FactureService.imprimerFacture(factureFile);
    } catch (e) {
      debugPrint('Erreur génération facture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFullOptions = widget.isCursus || (widget.isHybride && widget.montantPresentiel != null);
    final showAnnuelOption = widget.isCursus || (widget.isHybride && widget.montantPresentiel != null);

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: YekiColors.primaryDark,
        foregroundColor: YekiColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecapCard(showFullOptions, showAnnuelOption),
            const SizedBox(height: 24),
            const Text(
              'Moyen de paiement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMethodSelector(),
            const SizedBox(height: 24),
            _buildPaymentForm(),
            if (widget.type == PaiementType.accesDepartement && widget.montantPresentiel != null && widget.montantPresentiel! > 0) ...[
              const SizedBox(height: 16),
              _buildFactureOption(),
            ],
            const SizedBox(height: 32),
            _buildPayButton(showFullOptions, showAnnuelOption),
            const SizedBox(height: 16),
            _buildSecurityFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapCard(bool showFullOptions, bool showAnnuelOption) {
    String typeLabel;
    switch (widget.type) {
      case PaiementType.rechargeWallet:
        typeLabel = 'Recharge portefeuille';
        break;
      case PaiementType.accesDepartement:
        typeLabel = widget.isFormation ? 'Accès à la formation' : 'Accès au département';
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
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight),
        boxShadow: YekiShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: YekiColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: YekiRadius.borderRadiusMd,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: YekiColors.primaryDark, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel, style: const TextStyle(fontSize: 12)),
                    Text(widget.titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (showFullOptions && widget.montantPresentiel != null && widget.montantPresentiel! > 0) ...[
            _buildPriceRow('Formation en ligne', widget.montant),
            _buildPriceRow('Frais présentiel', widget.montantPresentiel!),
            const Divider(height: 16),
            _buildPriceRow('Montant mensuel', _montantTotal, isBold: true),
            if (showAnnuelOption) ...[
              const SizedBox(height: 4),
              _buildPriceRow(
                'Abonnement annuel (Économie 15%)', 
                _montantAnnuel,
                isBold: true,
                isPromo: true,
              ),
            ],
          ] else if (widget.montantPresentiel != null && widget.montantPresentiel! > 0) ...[
            _buildPriceRow('Montant', widget.montant, isBold: true),
            const SizedBox(height: 4),
            _buildPriceRow('+ frais présentiel', widget.montantPresentiel!, isSmall: true),
            const SizedBox(height: 8),
            _buildPriceRow('Total', _montantTotal, isBold: true),
          ] else ...[
            _buildPriceRow('Montant', widget.montant, isBold: true),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label, 
    int montant, {
    bool isBold = false,
    bool isPromo = false,
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isPromo ? YekiColors.success : null,
            ),
          ),
          Text(
            '${montant} FCFA',
            style: TextStyle(
              fontSize: isSmall ? 13 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isPromo ? YekiColors.success : (isBold ? YekiColors.primaryDark : null),
            ),
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
            color: YekiColors.primaryDark,
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
          color: selected ? color.withValues(alpha: 0.1) : YekiColors.white,
          borderRadius: YekiRadius.borderRadiusMd,
          border: Border.all(color: selected ? color : YekiColors.borderLight, width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : YekiColors.textLight, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? color : YekiColors.textMedium,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactureOption() {
    return Row(
      children: [
        Checkbox(
          value: _genererFacture,
          onChanged: (v) => setState(() => _genererFacture = v ?? false),
          activeColor: YekiColors.primaryDark,
        ),
        const SizedBox(width: 8),
        const Text('Générer une facture après paiement', style: TextStyle(fontSize: 13)),
      ],
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
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: color),
              const SizedBox(width: 8),
              Text(isMtn ? 'MTN Mobile Money' : 'Orange Money', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
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
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
              border: OutlineInputBorder(borderRadius: YekiRadius.borderRadiusMd),
              focusedBorder: OutlineInputBorder(
                borderRadius: YekiRadius.borderRadiusMd,
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: YekiRadius.borderRadiusSm,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Vous recevrez une notification de confirmation sur votre téléphone.', style: TextStyle(fontSize: 12)),
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
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card_rounded, color: YekiColors.primaryDark),
              SizedBox(width: 8),
              Text('Carte bancaire', style: TextStyle(fontWeight: FontWeight.bold, color: YekiColors.primaryDark, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nom sur la carte',
              border: OutlineInputBorder(borderRadius: YekiRadius.borderRadiusMd),
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
              border: OutlineInputBorder(borderRadius: YekiRadius.borderRadiusMd),
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
                    border: OutlineInputBorder(borderRadius: YekiRadius.borderRadiusMd),
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
                    border: OutlineInputBorder(borderRadius: YekiRadius.borderRadiusMd),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(bool showFullOptions, bool showAnnuelOption) {
    if (showFullOptions && showAnnuelOption && widget.montantPresentiel != null && widget.montantPresentiel! > 0) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: YekiButton(
                  label: 'Mensuel ${_montantTotal} FCFA',
                  onPressed: _isLoading ? null : () => _initierPaiement(annuel: false),
                  isLoading: _isLoading && !_isAnnuel,
                  backgroundColor: YekiColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: YekiButton(
                  label: 'Annuel ${_montantAnnuel} FCFA',
                  onPressed: _isLoading ? null : () => _initierPaiement(annuel: true),
                  isLoading: _isLoading && _isAnnuel,
                  backgroundColor: YekiColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Économisez 15% avec l\'abonnement annuel',
            style: TextStyle(fontSize: 11, color: YekiColors.success),
          ),
        ],
      );
    }
    
    if (showAnnuelOption && widget.montantPresentiel != null && widget.montantPresentiel! > 0) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: YekiButton(
                  label: 'Mensuel $_montantTotal FCFA',
                  onPressed: _isLoading ? null : () => _initierPaiement(annuel: false),
                  isLoading: _isLoading && !_isAnnuel,
                  backgroundColor: YekiColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: YekiButton(
                  label: 'Annuel ${_montantAnnuel} FCFA',
                  onPressed: _isLoading ? null : () => _initierPaiement(annuel: true),
                  isLoading: _isLoading && _isAnnuel,
                  backgroundColor: YekiColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Économisez 15% avec l\'abonnement annuel',
            style: TextStyle(fontSize: 11, color: YekiColors.success),
          ),
        ],
      );
    }

    return YekiButton(
      label: 'Payer ${_montantTotal} FCFA',
      icon: Icons.lock_rounded,
      onPressed: _isLoading ? null : _initierPaiement,
      isLoading: _isLoading,
    );
  }

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.security_rounded, size: 14, color: YekiColors.textLight),
        const SizedBox(width: 6),
        Text('Paiement 100% sécurisé via CinetPay', style: TextStyle(fontSize: 12, color: YekiColors.textLight)),
      ],
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

// WebView CinetPay intégrée
class CinetPayWebView extends StatefulWidget {
  final String paymentUrl;
  final String reference;
  final String titre;
  final int montant;
  final PaiementType type;
  final int? departementId;

  const CinetPayWebView({
    super.key,
    required this.paymentUrl,
    required this.reference,
    required this.titre,
    required this.montant,
    required this.type,
    this.departementId,
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
            ErrorHandler.showError(context, 'Erreur de chargement: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentCompletion(String url) {
    if (url.contains('payment-result') || url.contains('success') || url.contains('cinetpay.com/success')) {
      if (!_paymentCompleted) {
        _paymentCompleted = true;
        _verifierPaiement();
      }
    }
  }

  Future<void> _verifierPaiement() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement - ${widget.titre}'),
        backgroundColor: YekiColors.primaryDark,
        foregroundColor: YekiColors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: YekiLoader()),
        ],
      ),
    );
  }
}