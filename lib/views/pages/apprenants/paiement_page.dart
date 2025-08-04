import 'package:flutter/material.dart';
import 'generate_pdf_page.dart';

class PaiementPage extends StatefulWidget {
  final String concours;
  final double montant;

  const PaiementPage({super.key, required this.concours, required this.montant});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  String _moyenPaiement = 'mobile';
  final _formKey = GlobalKey<FormState>();

  final _numeroController = TextEditingController();
  final _nomCarteController = TextEditingController();
  final _numeroCarteController = TextEditingController();
  final _dateCarteController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FA),
      appBar: AppBar(
        title: const Text("Paiement"),
        centerTitle: true,
        backgroundColor: const Color(0xFF008080),
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 🟩 Bloc concours
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Concours sélectionné",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 4),
                          Text(widget.concours,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF03224C))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: Colors.orange, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                "${widget.montant.toStringAsFixed(0)} FCFA",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔘 Méthode de paiement
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Méthode de paiement",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildRadio("mobile", Icons.phone_android, "Mobile Money"),
                        const SizedBox(width: 24),
                        _buildRadio("bancaire", Icons.credit_card, "Carte Bancaire"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 📱 Champs conditionnels
                    if (_moyenPaiement == 'mobile') ...[
                      _buildInputField(
                        controller: _numeroController,
                        label: "Numéro Mobile Money",
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                        validatorMsg: "Entrez le numéro mobile",
                      ),
                    ] else ...[
                      _buildInputField(
                        controller: _nomCarteController,
                        label: "Nom sur la carte",
                        icon: Icons.person_outline,
                        validatorMsg: "Entrez le nom sur la carte",
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        controller: _numeroCarteController,
                        label: "Numéro de carte",
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        validatorMsg: "Entrez un numéro valide",
                        maxLength: 16,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _dateCarteController,
                              label: "Expiration (MM/AA)",
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              controller: _cvvController,
                              label: "CVV",
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Spacer(),
                    const SizedBox(height: 20),

                    // 🔒 Bouton Paiement
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_outline, color: Colors.white),
                        label: const Text("Payer maintenant"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF008080),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.2,
                            ),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Paiement en cours...")),
                            );

                            await Future.delayed(const Duration(seconds: 2));

                            await generateInvoicePdf(
                              concours: widget.concours,
                              montant: widget.montant,
                              numeroClient: _numeroController.text.isNotEmpty
                                  ? _numeroController.text
                                  : '0000000000',
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(String value, IconData icon, String label) {
    return Row(
      children: [
        Radio(
          value: value,
          groupValue: _moyenPaiement,
          onChanged: (val) => setState(() => _moyenPaiement = val!),
          activeColor: const Color(0xFF008080),
        ),
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? validatorMsg,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validatorMsg != null
          ? (value) => value == null || value.isEmpty ? validatorMsg : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
