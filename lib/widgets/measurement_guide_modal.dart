import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum MeasurementGuideType {
  pescoco,
  cintura,
  quadril,
  abdomen,
  braco,
  coxa,
  panturrilha,
  peso,
}

class MeasurementGuideInfo {
  final String title;
  final String targetFormula;
  final String explanation;
  final List<String> steps;
  final double highlightY; // Posição vertical relativa (0.0 a 1.0)
  final bool isLateral;

  const MeasurementGuideInfo({
    required this.title,
    required this.targetFormula,
    required this.explanation,
    required this.steps,
    required this.highlightY,
    this.isLateral = false,
  });

  static MeasurementGuideInfo get(MeasurementGuideType type) {
    switch (type) {
      case MeasurementGuideType.pescoco:
        return const MeasurementGuideInfo(
          title: 'Circunferência do Pescoço',
          targetFormula: 'Essencial para a fórmula US Navy Body Fat (%)',
          explanation:
              'O pescoço serve como referência basal de circunferência muscular/esquelética. A relação entre a cintura e o pescoço é o principal preditor de gordura na fórmula da Marinha Americana.',
          steps: [
            'Fique de pé com a postura ereta, ombros relaxados e olhar para a linha do horizonte (cabeça neutra).',
            'Posicione a fita métrica logo abaixo da laringe (pomo de adão ou cartilagem tireóide).',
            'Mantenha a fita perpendicular ao eixo do pescoço, evitando inclinar a fita para baixo nas costas.',
            'Ajuste para que a fita toque a pele suavemente, sem apertar nem afundar os tecidos moles.',
            'Dica: Use um espelho para conferir se a fita está nivelada em toda a volta.',
          ],
          highlightY: 0.17,
        );
      case MeasurementGuideType.cintura:
        return const MeasurementGuideInfo(
          title: 'Circunferência da Cintura',
          targetFormula: 'Utilizada no US Navy, RFM, RCQ, RCEst e BRI',
          explanation:
              'A cintura mede a gordura visceral e subcutânea do tronco. É a medida mais correlacionada com saúde metabólica e risco cardiovascular.',
          steps: [
            'Fique de pé com os pés juntos, braços soltos ao lado do corpo e abdômen relaxado.',
            'Localize o ponto mais estreito do tronco (geralmente a meio caminho entre a última costela e a crista ilíaca).',
            'Se não houver ponto estreito evidente, posicione a fita horizontalmente cerca de 2 cm acima da cicatriz umbilical.',
            'Expire normalmente antes de ler a medida (nunca sugue ou estufe a barriga).',
            'A fita deve ficar perfeitamente horizontal e paralela ao chão em toda a circunferência.',
          ],
          highlightY: 0.40,
        );
      case MeasurementGuideType.quadril:
        return const MeasurementGuideInfo(
          title: 'Circunferência do Quadril',
          targetFormula: 'Obrigatório para mulheres no US Navy, RCQ e BAI',
          explanation:
              'No sexo feminino, o acúmulo de gordura ginoide se dá prioritariamente nos glúteos e quadris. Mede a maior extensão horizontal dos glúteos.',
          steps: [
            'Fique de pé com os pés juntos (tocando calcanhares) para não afastar a musculatura glútea.',
            'Posicione a fita métrica na linha de maior circunferência horizontal dos glúteos.',
            'Verifique no espelho se a fita não caiu ou subiu na parte traseira; ela deve permanecer perfeitamente paralela ao piso.',
            'Não contraia os glúteos durante a leitura; mantenha a musculatura relaxada.',
          ],
          highlightY: 0.54,
        );
      case MeasurementGuideType.abdomen:
        return const MeasurementGuideInfo(
          title: 'Circunferência do Abdômen',
          targetFormula: 'Acompanhamento de gordura visceral e inchaço',
          explanation:
              'Enquanto a cintura pega o ponto mais estreito, o abdômen registra a linha exata da cicatriz umbilical, sendo excelente para acompanhar perda de gordura frontal.',
          steps: [
            'Fique em pé, ereto, pés ligeiramente afastados na largura dos ombros.',
            'Passe a fita exatamente sobre o ponto central do umbigo.',
            'Mantenha a respiração tranquila e faça a leitura ao término de uma expiração normal.',
            'Certifique-se de que a fita não esteja dobrada nas costas.',
          ],
          highlightY: 0.45,
        );
      case MeasurementGuideType.braco:
        return const MeasurementGuideInfo(
          title: 'Circunferência do Braço (Bíceps)',
          targetFormula: 'Monitoramento de hipertrofia e massa magra',
          explanation:
              'Acompanha a evolução muscular dos membros superiores. Pode ser medido relaxado ou contraído a 90° com flexão máxima.',
          steps: [
            'Para medida relaxada: braço solto ao lado do corpo, meça no ponto médio entre o acrômio (ombro) e o olécrano (cotovelo).',
            'Para medida contraída: flexione o cotovelo a 90° e contraia o bíceps no seu ponto de maior volume.',
            'Mantenha a fita justa sobre o pico do bíceps sem prender a circulação.',
            'Recomendação: Mantenha sempre o mesmo padrão (relaxado ou contraído) nas avaliações subsequentes.',
          ],
          highlightY: 0.33,
          isLateral: true,
        );
      case MeasurementGuideType.coxa:
        return const MeasurementGuideInfo(
          title: 'Circunferência da Coxa',
          targetFormula: 'Massa muscular de membros inferiores e proporção',
          explanation:
              'Avalia a evolução do quadríceps e posteriores de coxa, além de reservas lipídicas de membros inferiores.',
          steps: [
            'Fique de pé com o peso distribuído igualmente em ambas as pernas.',
            'Meça no ponto médio entre a prega inguinal (junção da coxa com o quadril) e a borda superior da patela (joelho).',
            'Envolva a coxa horizontalmente com a fita, relaxando o quadríceps.',
            'Faça a medição sempre na mesma perna (convenciona-se o lado direito).',
          ],
          highlightY: 0.67,
        );
      case MeasurementGuideType.panturrilha:
        return const MeasurementGuideInfo(
          title: 'Circunferência da Panturrilha',
          targetFormula: 'Marcador de reserva muscular e sarcopenia',
          explanation:
              'Excelente indicador de massa muscular periférica em membros inferiores, altamente sensível a desnutrição ou hipertrofia.',
          steps: [
            'Fique de pé com o peso distribuído uniformemente nos dois pés.',
            'Passe a fita no ponto de maior circunferência da perna (ventre dos gastrocnêmios).',
            'Mantenha a fita métrica no plano horizontal sem apertar a musculatura.',
          ],
          highlightY: 0.83,
        );
      case MeasurementGuideType.peso:
        return const MeasurementGuideInfo(
          title: 'Peso Corporal (Balança)',
          targetFormula: 'Variável base de todos os cálculos e estimativas',
          explanation:
              'O peso isolado flutua diariamente por hidratação, glicogênio e conteúdo digestivo. Por isso, a padronização das condições de pesagem é fundamental.',
          steps: [
            'Pese-se sempre pela manhã, logo ao acordar, em jejum e após urinar.',
            'Utilize roupas leves ou pese-se sem roupas.',
            'Mantenha a balança sempre no mesmo local firme e nivelado (evite tapetes ou pisos irregulares).',
            'Foque na tendência e na média semanal calculada pelo aplicativo, nunca no número de um único dia isolado.',
          ],
          highlightY: 0.95,
        );
    }
  }
}

class MeasurementGuideModal extends StatelessWidget {
  final MeasurementGuideType type;

  const MeasurementGuideModal({super.key, required this.type});

  static Future<void> show(BuildContext context, MeasurementGuideType type) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MeasurementGuideModal(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = MeasurementGuideInfo.get(type);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de arraste
          Center(
            child: Container(
              width: 36,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título e Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.indigoPrimary
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.targetFormula,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.indigoLight
                              : AppColors.indigoPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF64748B),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ilustração com CustomPaint
          Center(
            child: Container(
              height: 170,
              width: 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: CustomPaint(
                painter: AnatomicalSilhouettePainter(
                  highlightY: info.highlightY,
                  isLateral: info.isLateral,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Explicação científica
          Text(
            info.explanation,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : const Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 14),

          // Instruções passo a passo
          Text(
            'COMO MEDIR PASSO A PASSO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? AppColors.indigoLight : AppColors.indigoPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: info.steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.indigoPrimary
                            .withValues(alpha: isDark ? 0.25 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.indigoLight
                              : AppColors.indigoPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.steps[idx],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // Botão Entendi
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Entendi, continuar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desenho vetorial da silhueta anatômica com destaque dinâmico
class AnatomicalSilhouettePainter extends CustomPainter {
  final double highlightY;
  final bool isLateral;
  final bool isDark;

  AnatomicalSilhouettePainter({
    required this.highlightY,
    required this.isLateral,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Cabeça
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.08), width: w * 0.22, height: h * 0.12),
      bodyPaint,
    );

    // 2. Pescoço
    final neckPath = Path();
    neckPath.moveTo(cx - w * 0.07, h * 0.13);
    neckPath.lineTo(cx + w * 0.07, h * 0.13);
    neckPath.lineTo(cx + w * 0.09, h * 0.18);
    neckPath.lineTo(cx - w * 0.09, h * 0.18);
    neckPath.close();
    canvas.drawPath(neckPath, bodyPaint);

    // 3. Tronco e Ombros
    final torsoPath = Path();
    torsoPath.moveTo(cx - w * 0.30, h * 0.22); // Ombro esq
    torsoPath.lineTo(cx + w * 0.30, h * 0.22); // Ombro dir
    torsoPath.lineTo(cx + w * 0.24, h * 0.32); // Tórax dir
    torsoPath.lineTo(cx + w * 0.17, h * 0.40); // Cintura dir
    torsoPath.lineTo(cx + w * 0.24, h * 0.54); // Quadril dir
    torsoPath.lineTo(cx + w * 0.04, h * 0.58); // Entrepernas dir
    torsoPath.lineTo(cx - w * 0.04, h * 0.58); // Entrepernas esq
    torsoPath.lineTo(cx - w * 0.24, h * 0.54); // Quadril esq
    torsoPath.lineTo(cx - w * 0.17, h * 0.40); // Cintura esq
    torsoPath.lineTo(cx - w * 0.24, h * 0.32); // Tórax esq
    torsoPath.close();
    canvas.drawPath(torsoPath, bodyPaint);

    // 4. Braços
    final leftArm = Path();
    leftArm.moveTo(cx - w * 0.30, h * 0.22);
    leftArm.lineTo(cx - w * 0.38, h * 0.36);
    leftArm.lineTo(cx - w * 0.33, h * 0.48);
    leftArm.lineTo(cx - w * 0.27, h * 0.48);
    leftArm.lineTo(cx - w * 0.30, h * 0.36);
    leftArm.lineTo(cx - w * 0.25, h * 0.24);
    leftArm.close();
    canvas.drawPath(leftArm, bodyPaint);

    final rightArm = Path();
    rightArm.moveTo(cx + w * 0.30, h * 0.22);
    rightArm.lineTo(cx + w * 0.38, h * 0.36);
    rightArm.lineTo(cx + w * 0.33, h * 0.48);
    rightArm.lineTo(cx + w * 0.27, h * 0.48);
    rightArm.lineTo(cx + w * 0.30, h * 0.36);
    rightArm.lineTo(cx + w * 0.25, h * 0.24);
    rightArm.close();
    canvas.drawPath(rightArm, bodyPaint);

    // 5. Pernas (Coxas e Panturrilhas)
    // Perna esquerda
    final leftLeg = Path();
    leftLeg.moveTo(cx - w * 0.23, h * 0.54);
    leftLeg.lineTo(cx - w * 0.05, h * 0.58);
    leftLeg.lineTo(cx - w * 0.06, h * 0.70); // Joelho int
    leftLeg.lineTo(cx - w * 0.08, h * 0.83); // Panturrilha int
    leftLeg.lineTo(cx - w * 0.10, h * 0.94); // Tornozelo int
    leftLeg.lineTo(cx - w * 0.18, h * 0.94); // Tornozelo ext
    leftLeg.lineTo(cx - w * 0.20, h * 0.83); // Panturrilha ext
    leftLeg.lineTo(cx - w * 0.17, h * 0.70); // Joelho ext
    leftLeg.close();
    canvas.drawPath(leftLeg, bodyPaint);

    // Perna direita
    final rightLeg = Path();
    rightLeg.moveTo(cx + w * 0.23, h * 0.54);
    rightLeg.lineTo(cx + w * 0.05, h * 0.58);
    rightLeg.lineTo(cx + w * 0.06, h * 0.70); // Joelho int
    rightLeg.lineTo(cx + w * 0.08, h * 0.83); // Panturrilha int
    rightLeg.lineTo(cx + w * 0.10, h * 0.94); // Tornozelo int
    rightLeg.lineTo(cx + w * 0.18, h * 0.94); // Tornozelo ext
    rightLeg.lineTo(cx + w * 0.20, h * 0.83); // Panturrilha ext
    rightLeg.lineTo(cx + w * 0.17, h * 0.70); // Joelho ext
    rightLeg.close();
    canvas.drawPath(rightLeg, bodyPaint);

    // Destaque da medida no ponto anatômico exato (highlightY)
    final targetY = h * highlightY;

    if (highlightY >= 0.92) {
      // Destaque do Peso (Plataforma da Balança sob os pés)
      final scaleRect = Rect.fromCenter(
        center: Offset(cx, h * 0.96),
        width: w * 0.65,
        height: h * 0.05,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaleRect, const Radius.circular(4)),
        linePaint,
      );
      canvas.drawCircle(Offset(cx, h * 0.96), 4.5, dotPaint);
    } else if (isLateral) {
      // Destaque do Braço / Membro lateral
      final targetArmX = cx + w * 0.33;
      canvas.drawCircle(Offset(targetArmX, targetY), 12, glowPaint);
      canvas.drawCircle(Offset(targetArmX, targetY), 5, dotPaint);
      // Linha indicadora
      canvas.drawLine(
        Offset(targetArmX - 14, targetY),
        Offset(targetArmX + 14, targetY),
        linePaint,
      );
    } else {
      // Linha de fita métrica horizontal passando pelo corpo
      final double bandWidth = w * (highlightY < 0.25 ? 0.35 : 0.65);
      final double startX = cx - (bandWidth / 2);
      final double endX = cx + (bandWidth / 2);

      // Glow suave
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, targetY), width: bandWidth + 8, height: 10),
          const Radius.circular(5),
        ),
        glowPaint,
      );

      // Linha principal com setas/pontos nas pontas
      canvas.drawLine(Offset(startX, targetY), Offset(endX, targetY), linePaint);
      canvas.drawCircle(Offset(startX, targetY), 3.5, dotPaint);
      canvas.drawCircle(Offset(endX, targetY), 3.5, dotPaint);
      canvas.drawCircle(Offset(cx, targetY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnatomicalSilhouettePainter oldDelegate) {
    return oldDelegate.highlightY != highlightY ||
        oldDelegate.isLateral != isLateral ||
        oldDelegate.isDark != isDark;
  }
}
