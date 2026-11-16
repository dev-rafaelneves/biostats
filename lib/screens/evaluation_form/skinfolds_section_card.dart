import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/measurement_guide_modal.dart';
import 'measure_input_row.dart';
import 'section_header.dart';

class SkinfoldsSectionCard extends StatelessWidget {
  final Sexo? sexo;
  final Avaliacao? prev;
  final bool showDobras;
  final int filledDobrasCount;
  final bool isJp7Ready;
  final bool isJp3Ready;
  final VoidCallback onToggleShowDobras;
  final ValueChanged<String> onFieldChanged;
  final String Function(double?) hintFromPrev;
  final String? Function(String, double?) validateRange;
  final double? Function(TextEditingController) parseField;

  final TextEditingController dobraPeitoralCtrl;
  final TextEditingController dobraAxilarMediaCtrl;
  final TextEditingController dobraTricepsCtrl;
  final TextEditingController dobraSubescapularCtrl;
  final TextEditingController dobraAbdomenCtrl;
  final TextEditingController dobraSuprailiacaCtrl;
  final TextEditingController dobraCoxaCtrl;

  const SkinfoldsSectionCard({
    super.key,
    required this.sexo,
    required this.prev,
    required this.showDobras,
    required this.filledDobrasCount,
    required this.isJp7Ready,
    required this.isJp3Ready,
    required this.onToggleShowDobras,
    required this.onFieldChanged,
    required this.hintFromPrev,
    required this.validateRange,
    required this.parseField,
    required this.dobraPeitoralCtrl,
    required this.dobraAxilarMediaCtrl,
    required this.dobraTricepsCtrl,
    required this.dobraSubescapularCtrl,
    required this.dobraAbdomenCtrl,
    required this.dobraSuprailiacaCtrl,
    required this.dobraCoxaCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.bioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const SectionHeader(
              title: 'DOBRAS CUTÂNEAS (ADIPÔMETRO)',
              bottomPadding: 0,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: (isJp7Ready || isJp3Ready)
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                isJp7Ready
                    ? '✨ JP 7 Ativo'
                    : (isJp3Ready
                        ? '✨ JP 3 Ativo'
                        : '$filledDobrasCount de 7 preenchidas'),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: (isJp7Ready || isJp3Ready)
                      ? AppColors.emerald
                      : colors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Semantics(
                button: true,
                expanded: showDobras,
                label: 'Protocolos Jackson-Pollock de dobras cutâneas',
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleShowDobras();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.straighten_rounded,
                          size: 18,
                          color: AppColors.indigoPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Protocolos Jackson-Pollock',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sexo == Sexo.F
                                    ? 'JP3: Tríceps, Suprailíaca, Coxa • JP7: Todas'
                                    : 'JP3: Peitoral, Abdômen, Coxa • JP7: Todas',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          showDobras
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showDobras) ...[
                const Divider(height: 1),
                MeasureInputRow(
                  label: 'Peitoral',
                  subtitle:
                      sexo == Sexo.M ? 'Essencial no JP3 masculino' : null,
                  controller: dobraPeitoralCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraPeitoral),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraPeitoralCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
                const Divider(indent: 16, height: 1),
                MeasureInputRow(
                  label: 'Axilar Média',
                  subtitle: 'Necessária para o JP7',
                  controller: dobraAxilarMediaCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraAxilarMedia),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraAxilarMediaCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
                const Divider(indent: 16, height: 1),
                MeasureInputRow(
                  label: 'Tríceps',
                  subtitle: sexo == Sexo.F
                      ? 'Essencial no JP3 feminino'
                      : 'Necessária para o JP7',
                  controller: dobraTricepsCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraTriceps),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraTricepsCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
                const Divider(indent: 16, height: 1),
                MeasureInputRow(
                  label: 'Subescapular',
                  subtitle: 'Necessária para o JP7',
                  controller: dobraSubescapularCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraSubescapular),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraSubescapularCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
                const Divider(indent: 16, height: 1),
                MeasureInputRow(
                  label: 'Abdômen',
                  subtitle: sexo == Sexo.M
                      ? 'Essencial no JP3 masculino'
                      : 'Necessária para o JP7',
                  controller: dobraAbdomenCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraAbdomen),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraAbdomenCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
                const Divider(indent: 16, height: 1),
                MeasureInputRow(
                  label: 'Suprailíaca',
                  subtitle: sexo == Sexo.F
                      ? 'Essencial no JP3 feminino'
                      : 'Necessária para o JP7',
                  controller: dobraSuprailiacaCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraSuprailiaca),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraSuprailiacaCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
                const Divider(indent: 16, height: 1),
                MeasureInputRow(
                  label: 'Coxa',
                  subtitle: 'Essencial no JP3 e JP7',
                  controller: dobraCoxaCtrl,
                  unit: 'mm',
                  hintText: hintFromPrev(prev?.medidas.dobraCoxa),
                  warningText: validateRange(
                    'Dobra',
                    parseField(dobraCoxaCtrl),
                  ),
                  onHelpTap: () => MeasurementGuideModal.show(
                    context,
                    MeasurementGuideType.dobraCutanea,
                  ),
                  onChanged: onFieldChanged,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
