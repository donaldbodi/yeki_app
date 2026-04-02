// ════════════════════════════════════════════════════════════════
// PATCH : enseignant_admin_dashboard_page.dart
//
// Remplace la méthode _creerDepartement() (ligne ~803)
// par la version enrichie ci-dessous.
//
// CHANGEMENTS :
//  1. Champs dynamiques selon type_parcours (prepa / formation / cursus)
//  2. Champs prépa : nom_concours, organisme, date_limite, date_examen,
//     arrete_ministeriel, niveaux_cibles, places_disponibles, frais_dossier
//  3. Champs formation : est_formation_metier / classique, duree_formation,
//     mode_formation, certificat_delivre, ville, domaine, est_certifiante
//  4. Envoi multipart/form-data pour supporter l'image
//  5. Backend: POST /api/departements/creer/
// ════════════════════════════════════════════════════════════════

// ── Remplace ENTIÈREMENT la méthode _creerDepartement() ─────────

/*
  void _creerDepartement() {
    // Champs communs
    final nomCtrl   = TextEditingController();
    final descCtrl  = TextEditingController();
    final prixCtrl  = TextEditingController(text: '0');
    final couleurCtrl = TextEditingController(text: '#2884A0');
    File? imageFile;

    // Champs prépa concours
    final nomConcoursCtrl      = TextEditingController();
    final organismeCtrl        = TextEditingController();
    final dateLimiteCtrl       = TextEditingController();
    final dateExamenCtrl       = TextEditingController();
    final arreteCtrl           = TextEditingController();
    final niveauxCtrl          = TextEditingController();
    final placesCtrl           = TextEditingController();
    final fraisDossierCtrl     = TextEditingController(text: '0');
    final debouchesCtrl        = TextEditingController();
    final lienOfficielCtrl     = TextEditingController();

    // Champs formation
    final dureeCtrl        = TextEditingController();
    final certificatCtrl   = TextEditingController();
    final prerequisCtrl    = TextEditingController();
    final objectifsCtrl    = TextEditingController();
    final domaineCtrl      = TextEditingController();
    final villeCtrl        = TextEditingController();
    String modeFormation   = 'hybride';
    bool   estFormMetier   = false;
    bool   estFormClassiq  = false;
    bool   estCertifiante  = false;

    bool isLoading = false;

    // Déterminer la section à afficher selon le type de parcours
    final isPrepa      = _typeParcours == 'prepa';
    final isFormation  = _typeParcours == 'formation';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                Text(
                  isPrepa ? 'Créer un concours'
                      : isFormation ? 'Créer une formation'
                      : 'Créer un département',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark),
                ),
                Text('Parcours : $_nomParcours',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),

                // ── Champs communs ────────────────────────────────
                _field(nomCtrl, 'Nom *', Icons.label_rounded,
                    isPrepa ? 'Ex: Concours ENS Yaoundé'
                        : isFormation ? 'Ex: Formation Développement Mobile'
                        : 'Ex: Département Sciences'),
                const SizedBox(height: 10),
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Décrivez brièvement…', maxLines: 3),
                const SizedBox(height: 10),
                _field(prixCtrl, 'Prix (FCFA)', Icons.attach_money_rounded,
                    '0 = gratuit'),
                const SizedBox(height: 10),

                // ── Image ─────────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 70);
                    if (picked != null) setS(() => imageFile = File(picked.path));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.image_rounded, color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        imageFile != null
                            ? imageFile!.path.split('/').last
                            : 'Choisir une image de couverture (optionnel)',
                        style: TextStyle(
                            color: imageFile != null ? _dark : Colors.grey,
                            fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                      if (imageFile != null)
                        GestureDetector(
                          onTap: () => setS(() => imageFile = null),
                          child: Icon(Icons.close_rounded, size: 16,
                              color: Colors.grey.shade400),
                        ),
                    ]),
                  ),
                ),

                // ══ SECTION PRÉPA CONCOURS ════════════════════════
                if (isPrepa) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Informations du concours',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6))),
                  const SizedBox(height: 12),
                  _field(nomConcoursCtrl, 'Nom officiel du concours',
                      Icons.emoji_events_rounded, 'Ex: ENS, Polytechnique…'),
                  const SizedBox(height: 10),
                  _field(organismeCtrl, 'Organisme organisateur',
                      Icons.apartment_rounded, 'Ex: MINESUP, ENS…'),
                  const SizedBox(height: 10),
                  _field(arreteCtrl, 'Arrêté ministériel',
                      Icons.gavel_rounded, 'Réf. de l\'arrêté (optionnel)'),
                  const SizedBox(height: 10),
                  _field(niveauxCtrl, 'Niveaux ciblés',
                      Icons.school_rounded, 'Ex: Terminale, Licence 3…'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _field(placesCtrl, 'Places dispo.',
                        Icons.people_rounded, '0 = illimité',
                        inputType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(fraisDossierCtrl, 'Frais dossier (F)',
                        Icons.receipt_rounded, '0',
                        inputType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 10),
                  // Date limite inscription
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d != null) setS(() => dateLimiteCtrl.text =
                          '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
                    },
                    child: AbsorbPointer(
                      child: _field(dateLimiteCtrl, 'Date limite inscription',
                          Icons.how_to_reg_rounded, 'Choisir…'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Date examen
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 60)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d != null) setS(() => dateExamenCtrl.text =
                          '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
                    },
                    child: AbsorbPointer(
                      child: _field(dateExamenCtrl, 'Date de l\'examen',
                          Icons.event_rounded, 'Choisir…'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field(lienOfficielCtrl, 'Lien officiel (URL)',
                      Icons.link_rounded, 'https://…'),
                  const SizedBox(height: 10),
                  _field(debouchesCtrl, 'Débouchés après réussite',
                      Icons.trending_up_rounded,
                      'Ecole, carrière… (une ligne par débouché)',
                      maxLines: 3),
                ],

                // ══ SECTION FORMATION ═════════════════════════════
                if (isFormation) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Informations de la formation',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                          color: Color(0xFF008088))),
                  const SizedBox(height: 12),

                  // Type formation (métier / classique)
                  const Text('Type de formation',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() {
                          estFormMetier  = true;
                          estFormClassiq = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: estFormMetier
                                ? const Color(0xFFF97316).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estFormMetier
                                  ? const Color(0xFFF97316)
                                  : Colors.grey.shade200,
                              width: estFormMetier ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(Icons.work_rounded,
                                color: estFormMetier
                                    ? const Color(0xFFF97316)
                                    : Colors.grey, size: 22),
                            const SizedBox(height: 4),
                            Text('Métier',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: estFormMetier
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: estFormMetier
                                        ? const Color(0xFFF97316)
                                        : Colors.grey)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() {
                          estFormClassiq = true;
                          estFormMetier  = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: estFormClassiq
                                ? const Color(0xFF008088).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estFormClassiq
                                  ? const Color(0xFF008088)
                                  : Colors.grey.shade200,
                              width: estFormClassiq ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(Icons.account_balance_rounded,
                                color: estFormClassiq
                                    ? const Color(0xFF008088)
                                    : Colors.grey, size: 22),
                            const SizedBox(height: 4),
                            Text('Classique',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: estFormClassiq
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: estFormClassiq
                                        ? const Color(0xFF008088)
                                        : Colors.grey)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  _field(dureeCtrl, 'Durée',
                      Icons.schedule_rounded, 'Ex: 6 mois, 200 heures…'),
                  const SizedBox(height: 10),
                  _field(domaineCtrl, 'Domaine',
                      Icons.category_rounded, 'Ex: Informatique, Finance…'),
                  const SizedBox(height: 10),
                  _field(villeCtrl, 'Ville',
                      Icons.location_on_rounded, 'Ex: Yaoundé, Douala…'),
                  const SizedBox(height: 10),

                  // Mode formation
                  const Text('Mode de formation',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['hybride', 'presentiel', 'distance'].map((m) {
                      final labels = {
                        'hybride': 'Hybride',
                        'presentiel': 'Présentiel',
                        'distance': 'À distance',
                      };
                      final sel = modeFormation == m;
                      return ChoiceChip(
                        label: Text(labels[m]!),
                        selected: sel,
                        selectedColor: const Color(0xFF008088).withOpacity(0.15),
                        labelStyle: TextStyle(
                            color: sel ? const Color(0xFF008088) : Colors.grey.shade600,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                        onSelected: (_) => setS(() => modeFormation = m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  _field(certificatCtrl, 'Certificat délivré',
                      Icons.card_membership_rounded, 'Ex: Certificat Python…'),
                  const SizedBox(height: 10),
                  _field(objectifsCtrl, 'Objectifs pédagogiques',
                      Icons.flag_rounded, 'Un objectif par ligne…', maxLines: 3),
                  const SizedBox(height: 10),
                  _field(prerequisCtrl, 'Prérequis',
                      Icons.checklist_rounded, 'Ex: Niveau Bac…', maxLines: 2),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: estCertifiante,
                    onChanged: (v) => setS(() => estCertifiante = v),
                    title: const Text('Formation certifiante',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Délivre un certificat reconnu à la fin',
                        style: TextStyle(fontSize: 11)),
                    activeColor: _gold,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],

                const SizedBox(height: 24),

                // ── Bouton Créer ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (nomCtrl.text.trim().isEmpty) {
                              _showMsg('Le nom est obligatoire', error: true);
                              return;
                            }
                            // Vérifications formation
                            if (isFormation && !estFormMetier && !estFormClassiq) {
                              _showMsg(
                                'Choisissez Formation Métier ou Classique',
                                error: true,
                              );
                              return;
                            }
                            setS(() => isLoading = true);
                            final token = await _getToken();
                            if (token == null) {
                              setS(() => isLoading = false);
                              return;
                            }
                            try {
                              final request = http.MultipartRequest(
                                'POST',
                                Uri.parse('$_baseUrl/departements/creer/'),
                              );
                              request.headers['Authorization'] = 'Token $token';

                              // Champs communs
                              request.fields['nom']         = nomCtrl.text.trim();
                              request.fields['parcours_id'] = '$_idParcours';
                              request.fields['description'] = descCtrl.text.trim();
                              request.fields['prix']        = prixCtrl.text.trim().isEmpty ? '0' : prixCtrl.text.trim();
                              request.fields['couleur']     = couleurCtrl.text.trim().isEmpty ? '#2884A0' : couleurCtrl.text.trim();

                              // Image
                              if (imageFile != null) {
                                request.files.add(await http.MultipartFile.fromPath(
                                    'image', imageFile!.path));
                              }

                              // Champs prépa
                              if (isPrepa) {
                                request.fields['est_prepa_concours']      = 'true';
                                request.fields['nom_concours']            = nomConcoursCtrl.text.trim();
                                request.fields['organisme_concours']      = organismeCtrl.text.trim();
                                request.fields['arrete_ministeriel']      = arreteCtrl.text.trim();
                                request.fields['niveaux_cibles']          = niveauxCtrl.text.trim();
                                request.fields['lien_officiel']           = lienOfficielCtrl.text.trim();
                                request.fields['debouches']               = debouchesCtrl.text.trim();
                                if (dateLimiteCtrl.text.isNotEmpty)
                                  request.fields['date_limite_inscription'] = dateLimiteCtrl.text.trim();
                                if (dateExamenCtrl.text.isNotEmpty)
                                  request.fields['date_examen'] = dateExamenCtrl.text.trim();
                                if (placesCtrl.text.isNotEmpty && placesCtrl.text != '0')
                                  request.fields['places_disponibles'] = placesCtrl.text.trim();
                                request.fields['frais_dossier'] = fraisDossierCtrl.text.trim().isEmpty ? '0' : fraisDossierCtrl.text.trim();
                              }

                              // Champs formation
                              if (isFormation) {
                                request.fields['est_formation_metier']    = estFormMetier.toString();
                                request.fields['est_formation_classique'] = estFormClassiq.toString();
                                request.fields['duree_formation']         = dureeCtrl.text.trim();
                                request.fields['mode_formation']          = modeFormation;
                                request.fields['certificat_delivre']      = certificatCtrl.text.trim();
                                request.fields['prerequis']               = prerequisCtrl.text.trim();
                                request.fields['objectifs']               = objectifsCtrl.text.trim();
                                request.fields['domaine']                 = domaineCtrl.text.trim();
                                request.fields['ville']                   = villeCtrl.text.trim();
                                request.fields['est_certifiante']         = estCertifiante.toString();
                              }

                              final streamed = await request.send();
                              final res = await http.Response.fromStream(streamed);
                              setS(() => isLoading = false);

                              if (res.statusCode == 201) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                _showMsg(
                                  isPrepa
                                      ? '✅ Concours créé !'
                                      : isFormation
                                          ? '✅ Formation créée !'
                                          : '✅ Département créé !',
                                  success: true,
                                );
                                _charger();
                              } else {
                                final err = jsonDecode(res.body);
                                _showMsg(err['detail'] ?? 'Erreur ${res.statusCode}',
                                    error: true);
                              }
                            } catch (_) {
                              setS(() => isLoading = false);
                              _showMsg('Erreur réseau', error: true);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            isPrepa
                                ? 'Créer le concours'
                                : isFormation
                                    ? 'Créer la formation'
                                    : 'Créer le département',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
*/
