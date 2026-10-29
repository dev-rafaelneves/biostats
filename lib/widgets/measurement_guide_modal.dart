import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
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
  dobraCutanea,
}

class MeasurementGuideInfo {
  final String title;
  final String targetFormula;
  final String explanation;
  final List<String> steps;
  final double highlightY; // Posição vertical relativa (0.0 a 1.0)
  final bool isLateral;
  final String landmark;

  const MeasurementGuideInfo({
    required this.title,
    required this.targetFormula,
    required this.explanation,
    required this.steps,
    required this.highlightY,
    this.isLateral = false,
    required this.landmark,
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
          highlightY: 0.16,
          landmark: 'Abaixo da laringe',
        );
      case MeasurementGuideType.cintura:
        return const MeasurementGuideInfo(
          title: 'Circunferência da Cintura',
          targetFormula: 'Utilizada no US Navy, RFM, RCQ, RCEst e BRI',
          explanation:
              'A cintura mede a gordura visceral e subcutânea do tronco. É a medida mais correlacionada com saúde metabólica e risco cardiovascular.',
          steps: [
            'Fique de pé com os pés juntos, braços soltos ao lado do corpo e abdômen relaxado.',
            'Localize o ponto mais estreito do tronco (a meio caminho entre a última costela e a crista ilíaca).',
            'Se não houver ponto estreito evidente, posicione a fita horizontalmente cerca de 2 cm acima da cicatriz umbilical.',
            'Expire normalmente antes de ler a medida (nunca sugue ou estufe a barriga).',
            'A fita deve ficar perfeitamente horizontal e paralela ao chão em toda a circunferência.',
          ],
          highlightY: 0.38,
          landmark: 'Ponto mais estreito',
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
          highlightY: 0.50,
          landmark: 'Maior extensão glútea',
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
          highlightY: 0.43,
          landmark: 'Cicatriz umbilical',
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
          landmark: 'Ponto médio / Bíceps',
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
          highlightY: 0.64,
          landmark: 'Ponto médio da coxa',
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
          highlightY: 0.77,
          landmark: 'Maior circunferência',
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
          landmark: 'Balança em jejum',
        );
      case MeasurementGuideType.dobraCutanea:
        return const MeasurementGuideInfo(
          title: 'Medição de Dobras Cutâneas (Adipômetro)',
          targetFormula:
              'Protocolos Jackson-Pollock 3 e 7 dobras + Equação de Siri',
          explanation:
              'As dobras cutâneas avaliam diretamente a espessura da gordura subcutânea em milímetros (mm). É um dos métodos clínicos mais precisos para estimar a densidade corporal.',
          steps: [
            'Realize todas as medições sempre no hemicorpo direito do corpo.',
            'Identifique e marque o ponto anatômico de referência com precisão.',
            'Pinçe a dobra firmemente com o polegar e o dedo indicador da mão esquerda, cerca de 1 a 2 cm acima do ponto a ser medido, separando a gordura do músculo.',
            'Aplique as pontas do adipômetro perpendicularmente à dobra na altura marcada.',
            'Aguarde cerca de 1 a 2 segundos para estabilização da pressão e leia a espessura em milímetros (mm).',
            'Repita a medida 2 a 3 vezes em cada ponto para obter um resultado consistente.',
          ],
          highlightY: 0.42,
          landmark: 'Pinçamento (1-2 cm)',
        );
    }
  }
}

class MeasurementGuideModal extends StatelessWidget {
  final MeasurementGuideType type;
  final Sexo sexo;

  const MeasurementGuideModal({
    super.key,
    required this.type,
    this.sexo = Sexo.M,
  });

  static Future<void> show(
    BuildContext context,
    MeasurementGuideType type, {
    Sexo sexo = Sexo.M,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MeasurementGuideModal(type: type, sexo: sexo),
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
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arraste
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

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
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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

            const SizedBox(height: 12),

            // Conteúdo Rolável
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ilustração Anatômica de Nível Profissional
                    Center(
                      child: Container(
                        height: 240,
                        width: 210,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: AnatomicalSilhouettePainter(
                            highlightY: info.highlightY,
                            isLateral: info.isLateral,
                            isDark: isDark,
                            sexo: sexo,
                            landmarkText: info.landmark,
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

                    const SizedBox(height: 16),

                    // Instruções passo a passo
                    Text(
                      'COMO MEDIR PASSO A PASSO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: isDark
                            ? AppColors.indigoLight
                            : AppColors.indigoPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: info.steps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.indigoPrimary
                                    .withValues(alpha: isDark ? 0.25 : 0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.indigoLight
                                      : AppColors.indigoPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

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
      ),
    );
  }
}

/// Desenho vetorial da silhueta anatômica profissional com curvas de Bézier e destaque em 3D
class AnatomicalSilhouettePainter extends CustomPainter {
  final double highlightY;
  final bool isLateral;
  final bool isDark;
  final Sexo sexo;
  final String? landmarkText;

  AnatomicalSilhouettePainter({
    required this.highlightY,
    required this.isLateral,
    required this.isDark,
    this.sexo = Sexo.M,
    this.landmarkText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final isFemale = sexo == Sexo.F;

    // 1. Grade de Referência Biométrica Sutil (estilo laboratório médico)
    final gridPaint = Paint()
      ..color = isDark ? const Color(0x15FFFFFF) : const Color(0x0C000000)
      ..strokeWidth = 0.8;

    for (double x = 10; x < w; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 10; y < h; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Eixo central pontilhado
    final centerAxisPaint = Paint()
      ..color = isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000)
      ..strokeWidth = 1.0;
    for (double y = 8; y < h - 14; y += 8) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 4), centerAxisPaint);
    }

    // 2. Parâmetros Anatômicos Proporcionais
    final shoulderW = isFemale ? w * 0.23 : w * 0.28;
    final chestW = isFemale ? w * 0.20 : w * 0.25;
    final waistW = isFemale ? w * 0.14 : w * 0.17;
    final hipsW = isFemale ? w * 0.23 : w * 0.20;

    // 3. Caminho Anatômico Contínuo e Orgânico do Corpo Humano (Bézier Curves)
    final bodyPath = Path();

    // Início na borda superior da cabeça
    bodyPath.moveTo(cx, h * 0.02);

    // Lado Esquerdo do Crânio e Mandíbula
    bodyPath.cubicTo(
      cx - w * 0.09, h * 0.02,
      cx - w * 0.09, h * 0.10,
      cx - w * 0.05, h * 0.125,
    );

    // Trapézio e Ombro Esquerdo
    bodyPath.quadraticBezierTo(
      cx - w * 0.12, h * 0.155,
      cx - shoulderW, h * 0.18,
    );

    // Deltoide Esquerdo
    bodyPath.quadraticBezierTo(
      cx - shoulderW - w * 0.04, h * 0.205,
      cx - shoulderW - w * 0.035, h * 0.245,
    );

    // Braço Esquerdo (Bíceps e Cotovelo)
    bodyPath.quadraticBezierTo(
      cx - shoulderW - w * 0.045, h * 0.31,
      cx - shoulderW - w * 0.035, h * 0.35,
    );

    // Antebraço e Punho Esquerdo
    bodyPath.quadraticBezierTo(
      cx - shoulderW - w * 0.045, h * 0.42,
      cx - shoulderW - w * 0.025, h * 0.47,
    );

    // Mão Esquerda (posição neutra relaxada)
    bodyPath.quadraticBezierTo(
      cx - shoulderW - w * 0.02, h * 0.52,
      cx - shoulderW - w * 0.005, h * 0.53,
    );
    bodyPath.quadraticBezierTo(
      cx - shoulderW + w * 0.015, h * 0.52,
      cx - shoulderW + w * 0.005, h * 0.47,
    );

    // Borda Interna do Antebraço e Cotovelo Esquerdo
    bodyPath.quadraticBezierTo(
      cx - shoulderW - w * 0.01, h * 0.41,
      cx - shoulderW, h * 0.35,
    );

    // Borda Interna do Braço até a Axila Esquerda
    bodyPath.quadraticBezierTo(
      cx - shoulderW + w * 0.01, h * 0.29,
      cx - chestW, h * 0.255,
    );

    // Parede Torácica até a Cintura Esquerda
    bodyPath.quadraticBezierTo(
      cx - chestW + w * 0.02, h * 0.32,
      cx - waistW, h * 0.38,
    );

    // Cintura até a Crista Ilíaca e Quadril Esquerdo
    bodyPath.quadraticBezierTo(
      cx - waistW - w * 0.01, h * 0.44,
      cx - hipsW, h * 0.50,
    );

    // Quadril até a Coxa Lateral Esquerda (Vasto Lateral)
    bodyPath.quadraticBezierTo(
      cx - hipsW - w * 0.015, h * 0.56,
      cx - hipsW + w * 0.03, h * 0.65, // Joelho lateral
    );

    // Panturrilha Lateral Esquerda (Gastrocnêmio)
    bodyPath.quadraticBezierTo(
      cx - hipsW + w * 0.045, h * 0.74,
      cx - hipsW + w * 0.065, h * 0.83,
    );

    // Tornozelo e Pé Esquerdo
    bodyPath.quadraticBezierTo(
      cx - hipsW + w * 0.07, h * 0.88,
      cx - hipsW + w * 0.065, h * 0.935, // Calcanhar
    );
    bodyPath.lineTo(cx - w * 0.06, h * 0.935); // Sola do pé
    bodyPath.lineTo(cx - w * 0.065, h * 0.89); // Tornozelo medial

    // Panturrilha Medial Esquerda
    bodyPath.quadraticBezierTo(
      cx - w * 0.05, h * 0.80,
      cx - w * 0.075, h * 0.69,
    );

    // Joelho Medial até a Prega Inguinal Esquerda
    bodyPath.quadraticBezierTo(
      cx - w * 0.08, h * 0.64,
      cx - w * 0.015, h * 0.525,
    );

    // Canto Pélvico Central
    bodyPath.quadraticBezierTo(
      cx, h * 0.52,
      cx + w * 0.015, h * 0.525,
    );

    // Prega Inguinal Direita até Joelho Medial Direito
    bodyPath.quadraticBezierTo(
      cx + w * 0.08, h * 0.64,
      cx + w * 0.075, h * 0.69,
    );

    // Panturrilha Medial Direita
    bodyPath.quadraticBezierTo(
      cx + w * 0.05, h * 0.80,
      cx + w * 0.065, h * 0.89,
    );

    // Pé Direito
    bodyPath.lineTo(cx + w * 0.06, h * 0.935); // Sola do pé
    bodyPath.lineTo(cx + hipsW - w * 0.065, h * 0.935); // Calcanhar

    // Tornozelo e Panturrilha Lateral Direita
    bodyPath.quadraticBezierTo(
      cx + hipsW - w * 0.07, h * 0.88,
      cx + hipsW - w * 0.065, h * 0.83,
    );
    bodyPath.quadraticBezierTo(
      cx + hipsW - w * 0.045, h * 0.74,
      cx + hipsW - w * 0.03, h * 0.65, // Joelho lateral
    );

    // Coxa Lateral Direita até Quadril Direito
    bodyPath.quadraticBezierTo(
      cx + hipsW + w * 0.015, h * 0.56,
      cx + hipsW, h * 0.50,
    );

    // Quadril Direito até a Cintura Direita
    bodyPath.quadraticBezierTo(
      cx + waistW + w * 0.01, h * 0.44,
      cx + waistW, h * 0.38,
    );

    // Cintura até a Parede Torácica Direita
    bodyPath.quadraticBezierTo(
      cx + chestW - w * 0.02, h * 0.32,
      cx + chestW, h * 0.255,
    );

    // Axila Direita até Borda Interna do Braço Direito
    bodyPath.quadraticBezierTo(
      cx + shoulderW - w * 0.01, h * 0.29,
      cx + shoulderW, h * 0.35,
    );

    // Borda Interna do Antebraço Direito até Punho
    bodyPath.quadraticBezierTo(
      cx + shoulderW + w * 0.01, h * 0.41,
      cx + shoulderW - w * 0.005, h * 0.47,
    );

    // Mão Direita
    bodyPath.quadraticBezierTo(
      cx + shoulderW - w * 0.015, h * 0.52,
      cx + shoulderW + w * 0.005, h * 0.53,
    );
    bodyPath.quadraticBezierTo(
      cx + shoulderW + w * 0.02, h * 0.52,
      cx + shoulderW + w * 0.025, h * 0.47,
    );

    // Antebraço Externo e Cotovelo Direito
    bodyPath.quadraticBezierTo(
      cx + shoulderW + w * 0.045, h * 0.42,
      cx + shoulderW + w * 0.035, h * 0.35,
    );

    // Braço Externo e Deltoide Direito
    bodyPath.quadraticBezierTo(
      cx + shoulderW + w * 0.045, h * 0.31,
      cx + shoulderW + w * 0.035, h * 0.245,
    );
    bodyPath.quadraticBezierTo(
      cx + shoulderW + w * 0.04, h * 0.205,
      cx + shoulderW, h * 0.18,
    );

    // Trapézio e Lado Direito do Crânio
    bodyPath.quadraticBezierTo(
      cx + w * 0.12, h * 0.155,
      cx + w * 0.05, h * 0.125,
    );
    bodyPath.cubicTo(
      cx + w * 0.09, h * 0.10,
      cx + w * 0.09, h * 0.02,
      cx, h * 0.02,
    );

    bodyPath.close();

    // 4. Pintura do Corpo com Gradiente Vertical Suave
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF334155), const Color(0xFF1E293B)]
            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(bodyPath, bodyPaint);

    // Contorno de Precisão da Silhueta
    final outlinePaint = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bodyPath, outlinePaint);

    // 5. Linhas Anatômicas Internas Sutis (Clavículas, Peitorais, Umbigo, Joelhos)
    final landmarkPaint = Paint()
      ..color = isDark ? const Color(0x35FFFFFF) : const Color(0x30000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Clavículas
    final leftClavicle = Path()
      ..moveTo(cx - w * 0.02, h * 0.17)
      ..quadraticBezierTo(cx - w * 0.08, h * 0.165, cx - shoulderW + w * 0.06, h * 0.18);
    canvas.drawPath(leftClavicle, landmarkPaint);

    final rightClavicle = Path()
      ..moveTo(cx + w * 0.02, h * 0.17)
      ..quadraticBezierTo(cx + w * 0.08, h * 0.165, cx + shoulderW - w * 0.06, h * 0.18);
    canvas.drawPath(rightClavicle, landmarkPaint);

    // Peitorais / Tórax
    final chestLine = Path()
      ..moveTo(cx - chestW + w * 0.04, h * 0.25)
      ..quadraticBezierTo(cx - w * 0.08, h * 0.265, cx - w * 0.015, h * 0.245)
      ..moveTo(cx + w * 0.015, h * 0.245)
      ..quadraticBezierTo(cx + w * 0.08, h * 0.265, cx + chestW - w * 0.04, h * 0.25);
    canvas.drawPath(chestLine, landmarkPaint);

    // Umbigo (Cicatriz Umbilical)
    final navelDotPaint = Paint()
      ..color = isDark ? const Color(0x60FFFFFF) : const Color(0x50000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.43), 1.8, navelDotPaint);

    // Patelas (Joelhos)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - w * 0.12, h * 0.65), width: w * 0.06, height: h * 0.03),
        const Radius.circular(6),
      ),
      landmarkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + w * 0.12, h * 0.65), width: w * 0.06, height: h * 0.03),
        const Radius.circular(6),
      ),
      landmarkPaint,
    );

    // 6. Destaque Visual de Alta Precisão no Ponto de Medição (highlightY)
    final targetY = h * highlightY;

    if (highlightY >= 0.92) {
      // --- Destaque do Peso (Plataforma de Balança Digital) ---
      final scaleRect = Rect.fromCenter(
        center: Offset(cx, h * 0.955),
        width: w * 0.68,
        height: h * 0.045,
      );
      final scaleGlow = Paint()
        ..color = AppColors.indigoPrimary.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaleRect.inflate(2), const Radius.circular(8)),
        scaleGlow,
      );

      final scalePaint = Paint()
        ..color = isDark ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill;
      final scaleBorder = Paint()
        ..color = AppColors.indigoPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaleRect, const Radius.circular(8)),
        scalePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaleRect, const Radius.circular(8)),
        scaleBorder,
      );

      // Display digital na balança
      final displayRect = Rect.fromCenter(
        center: Offset(cx, h * 0.955),
        width: 26,
        height: 7,
      );
      final displayPaint = Paint()
        ..color = AppColors.indigoPrimary.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(displayRect, const Radius.circular(3)),
        displayPaint,
      );
    } else if (isLateral) {
      // --- Destaque Lateral (Braço / Bíceps) ---
      final armX = cx + shoulderW + w * 0.02;

      // Anel elíptico ao redor do braço
      final tapeRect = Rect.fromCenter(
        center: Offset(armX, targetY),
        width: w * 0.12,
        height: 10,
      );
      _drawMeasuringTapeLoop(canvas, tapeRect, isDark);

      // Retículo de mira no ponto médio
      _drawTargetReticle(canvas, Offset(armX, targetY));
    } else {
      // --- Destaque Circunferencial (Tronco, Pescoço, Quadril ou Pernas) ---
      // Calcula a largura da fita de acordo com o segmento corporal
      double bandWidth;
      if (highlightY < 0.22) {
        bandWidth = w * 0.32; // Pescoço
      } else if (highlightY < 0.42) {
        bandWidth = waistW * 2.5; // Cintura
      } else if (highlightY < 0.48) {
        bandWidth = waistW * 2.7; // Abdômen
      } else if (highlightY < 0.58) {
        bandWidth = hipsW * 2.4; // Quadril
      } else if (highlightY < 0.72) {
        bandWidth = w * 0.22; // Coxa direita
      } else {
        bandWidth = w * 0.18; // Panturrilha direita
      }

      // Se for coxa ou panturrilha, posiciona no membro direito (hemicorpo padronizado)
      final tapeCenterX = (highlightY >= 0.60) ? cx + w * 0.11 : cx;

      final tapeRect = Rect.fromCenter(
        center: Offset(tapeCenterX, targetY),
        width: bandWidth,
        height: 11,
      );

      _drawMeasuringTapeLoop(canvas, tapeRect, isDark);
      _drawTargetReticle(canvas, Offset(tapeCenterX, targetY));
    }

    // 7. Badge Flutuante com o Nome do Marco Anatômico
    if (landmarkText != null && highlightY < 0.90) {
      _drawLandmarkCallout(canvas, size, targetY, landmarkText!);
    }
  }

  /// Desenha a fita métrica em perspectiva 3D com marcas de calibração milimétricas
  void _drawMeasuringTapeLoop(Canvas canvas, Rect rect, bool isDark) {
    // Parte de trás da fita (passa por trás do corpo com linha sutil tracejada)
    final backPaint = Paint()
      ..color = AppColors.indigoPrimary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      backPaint,
    );

    // Aura de brilho neon na parte frontal
    final glowPaint = Paint()
      ..color = AppColors.indigoPrimary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      rect,
      0,
      math.pi,
      false,
      glowPaint,
    );

    // Fita métrica frontal principal (luminous ribbon)
    final tapeFrontPaint = Paint()
      ..color = AppColors.indigoPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      0,
      math.pi,
      false,
      tapeFrontPaint,
    );

    // Tracinhos de calibração métrica da fita
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    final double step = rect.width / 10;
    for (int i = 1; i < 10; i++) {
      final double tx = rect.left + (step * i);
      final double relX = (tx - rect.center.dx) / (rect.width / 2);
      final double clamped = relX.clamp(-1.0, 1.0);
      final double ty = rect.center.dy + (rect.height / 2) * math.sqrt(1 - (clamped * clamped));
      canvas.drawLine(Offset(tx, ty - 2), Offset(tx, ty + 2), tickPaint);
    }
  }

  /// Desenha o retículo de mira focal brilhante no ponto anatômico
  void _drawTargetReticle(Canvas canvas, Offset center) {
    // Halo externo
    final haloPaint = Paint()
      ..color = AppColors.indigoPrimary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, haloPaint);

    // Anel externo
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 6, ringPaint);

    // Ponto focal central
    final corePaint = Paint()
      ..color = AppColors.indigoPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, corePaint);
  }

  /// Desenha a tag flutuante elegante com linha guia indicando o marco anatômico
  void _drawLandmarkCallout(
    Canvas canvas,
    Size size,
    double targetY,
    String text,
  ) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        letterSpacing: 0.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgePaddingH = 7.0;
    final badgePaddingV = 3.0;
    final badgeW = textPainter.width + (badgePaddingH * 2);
    final badgeH = textPainter.height + (badgePaddingV * 2);

    // Posição flutuante no topo ou lateral
    final badgeX = 8.0;
    final badgeY = math.max(6.0, targetY - badgeH - 6.0);

    // Linha guia conectando badge ao corpo
    final guideLinePaint = Paint()
      ..color = AppColors.indigoPrimary.withValues(alpha: 0.5)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final badgeRight = badgeX + badgeW;
    final badgeCenterY = badgeY + (badgeH / 2);

    final guidePath = Path()
      ..moveTo(badgeRight, badgeCenterY)
      ..lineTo(badgeRight + 8, badgeCenterY)
      ..lineTo(size.width * 0.38, targetY);
    canvas.drawPath(guidePath, guideLinePaint);

    // Fundo do badge
    final badgeBgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;

    final badgeBorderPaint = Paint()
      ..color = AppColors.indigoPrimary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
      const Radius.circular(6),
    );

    canvas.drawRRect(badgeRRect, badgeBgPaint);
    canvas.drawRRect(badgeRRect, badgeBorderPaint);

    // Renderiza o texto
    textPainter.paint(canvas, Offset(badgeX + badgePaddingH, badgeY + badgePaddingV));
  }

  @override
  bool shouldRepaint(covariant AnatomicalSilhouettePainter oldDelegate) {
    return oldDelegate.highlightY != highlightY ||
        oldDelegate.isLateral != isLateral ||
        oldDelegate.isDark != isDark ||
        oldDelegate.sexo != sexo ||
        oldDelegate.landmarkText != landmarkText;
  }
}
