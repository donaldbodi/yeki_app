// lib/views/pages/wallet/recharge_wallet_page.dart

import 'package:flutter/material.dart';
import 'cinetpay_webview_page.dart';

class RechargeWalletPage extends StatefulWidget {
  const RechargeWalletPage({super.key});

  @override
  State<RechargeWalletPage> createState() => _RechargeWalletPageState();
}

class _RechargeWalletPageState extends State<RechargeWalletPage> {
  final List<RechargeOption> _options = [
    RechargeOption(amount: 1000, bonus: 0),
    RechargeOption(amount: 2000, bonus: 50),
    RechargeOption(amount: 5000, bonus: 150),
    RechargeOption(amount: 10000, bonus: 400),
    RechargeOption(amount: 20000, bonus: 1000),
    RechargeOption(amount: 50000, bonus: 3000),
  ];

  RechargeOption? _selectedOption;
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  num get _finalAmount {
    if (_selectedOption != null) {
      return _selectedOption!.amount + _selectedOption!.bonus;
    }
    final custom = int.tryParse(_customAmountController.text);
    if (custom != null && custom > 0) {
      return custom.toDouble();
    }
    return 0;
  }

  Future<void> _proceedToPayment() async {
    if (_finalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un montant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinetPayWebViewPage(
          amount: _finalAmount,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        ),
      ),
    );

    setState(() => _isLoading = false);

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Recharger mon portefeuille'),
        backgroundColor: const Color(0xFF2884A0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Montants prédéfinis
            const Text(
              'Montants recommandés',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                final isSelected = _selectedOption == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = option;
                      _customAmountController.clear();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2884A0) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2884A0) : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          // ✅ CORRIGÉ : withValues(alpha: 0.04)
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${option.amount} FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF1A1C1E),
                          ),
                        ),
                        if (option.bonus > 0)
                          Text(
                            '+${option.bonus} FCFA offerts',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Montant personnalisé
            const Text(
              'Montant personnalisé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                setState(() => _selectedOption = null);
              },
              decoration: InputDecoration(
                hintText: 'Ex: 2500',
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF2884A0)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2884A0)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Téléphone (optionnel pour Mobile Money)
            const Text(
              'Numéro de téléphone (optionnel)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recommandé pour les paiements Mobile Money',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ex: 691234567',
                prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF2884A0)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2884A0)),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Récapitulatif
            if (_finalAmount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ✅ CORRIGÉ : withValues(alpha: 0.08)
                  color: const Color(0xFF2884A0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant à payer',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      '${_finalAmount.toInt()} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF2884A0),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _finalAmount <= 0 ? null : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2884A0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Payer avec CinetPay',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Informations de sécurité
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Paiement 100% sécurisé',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.verified_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Transactions cryptées',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RechargeOption {
  final int amount;
  final int bonus;

  RechargeOption({required this.amount, required this.bonus});
}