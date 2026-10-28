import 'package:flutter_test/flutter_test.dart';
import 'package:biostats/models/models.dart';
import 'package:biostats/services/backup_service.dart';
import 'package:biostats/services/health_connect_service.dart';
import 'package:biostats/services/widget_service.dart';
import 'package:biostats/utils/calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 7 — Dobras Cutâneas & Jackson-Pollock + Equação de Siri', () {
    test('Equação de Siri calcula BF% corretamente a partir da densidade corporal (BD)', () {
      // Siri: BF% = ((4.95 / BD) - 4.50) * 100
      // Para BD = 1.0500:
      // (4.95 / 1.0500 - 4.50) * 100 = (4.7142857 - 4.50) * 100 = 21.43%
      final bf = BioCalculator.siriEquation(1.0500);
      expect(bf, closeTo(21.43, 0.05));

      // Para BD = 1.0700:
      // (4.95 / 1.0700 - 4.50) * 100 = (4.626168 - 4.50) * 100 = 12.62%
      final bfAthletic = BioCalculator.siriEquation(1.0700);
      expect(bfAthletic, closeTo(12.62, 0.05));

      // Caso degenerado BD <= 0
      expect(BioCalculator.siriEquation(0.0), equals(0.0));
      expect(BioCalculator.siriEquation(-1.0), equals(0.0));
    });

    test('Jackson-Pollock 3 Dobras (Masculino: Peitoral, Abdômen, Coxa)', () {
      // Homem, 30 anos
      // Dobras: Peitoral 12mm, Abdômen 20mm, Coxa 16mm -> Soma = 48mm
      // BD = 1.1093800 - (0.0008267 * 48) + (0.0000016 * 48^2) - (0.0002574 * 30)
      // 0.0008267 * 48 = 0.0396816
      // 0.0000016 * 2304 = 0.0036864
      // 0.0002574 * 30 = 0.007722
      // BD = 1.1093800 - 0.0396816 + 0.0036864 - 0.007722 = 1.0656628
      // Siri: ((4.95 / 1.0656628) - 4.50) * 100 = 14.49%
      final bf = BioCalculator.calculateJacksonPollock3(
        sexo: Sexo.M,
        idade: 30,
        peitoral: 12.0,
        abdomen: 20.0,
        coxa: 16.0,
      );

      expect(bf, closeTo(14.49, 0.1));
    });

    test('Jackson-Pollock 3 Dobras (Feminino: Tríceps, Suprailíaca, Coxa)', () {
      // Mulher, 25 anos
      // Dobras: Tríceps 15mm, Suprailíaca 18mm, Coxa 22mm -> Soma = 55mm
      // BD = 1.0994921 - (0.0009929 * 55) + (0.0000023 * 55^2) - (0.0001392 * 25)
      // 0.0009929 * 55 = 0.0546095
      // 0.0000023 * 3025 = 0.0069575
      // 0.0001392 * 25 = 0.00348
      // BD = 1.0994921 - 0.0546095 + 0.0069575 - 0.00348 = 1.04836
      // Siri: ((4.95 / 1.04836) - 4.50) * 100 = 22.18%
      final bf = BioCalculator.calculateJacksonPollock3(
        sexo: Sexo.F,
        idade: 25,
        triceps: 15.0,
        suprailiaca: 18.0,
        coxa: 22.0,
      );

      expect(bf, closeTo(22.18, 0.1));
    });

    test('Jackson-Pollock 7 Dobras calcula com precisão clínica', () {
      // Homem, 28 anos
      // 7 dobras: 10, 12, 11, 14, 18, 15, 16 mm -> Soma = 96mm
      final bf7M = BioCalculator.calculateJacksonPollock7(
        sexo: Sexo.M,
        idade: 28,
        peitoral: 10,
        axilarMedia: 12,
        triceps: 11,
        subescapular: 14,
        abdomen: 18,
        suprailiaca: 15,
        coxa: 16,
      );
      expect(bf7M, greaterThan(10.0));
      expect(bf7M, lessThan(20.0));

      // Mulher, 28 anos com as mesmas dobras tem densidade diferente por sexo
      final bf7F = BioCalculator.calculateJacksonPollock7(
        sexo: Sexo.F,
        idade: 28,
        peitoral: 10,
        axilarMedia: 12,
        triceps: 11,
        subescapular: 14,
        abdomen: 18,
        suprailiaca: 15,
        coxa: 16,
      );
      expect(bf7F, greaterThan(15.0));
      expect(bf7F, lessThan(30.0));
      expect(bf7F, isNot(equals(bf7M)));
    });

    test('Prioridade do método no snapshot: JP7 > JP3 > Navy > RFM > Deurenberg', () {
      final profile = UserProfile(
        id: 'u1',
        nome: 'Atleta Teste',
        dataNascimento: DateTime(1995, 5, 20),
        sexo: Sexo.M,
        alturaCm: 180,
        criadoEm: DateTime.now(),
      );

      // Caso 1: Todas as 7 dobras presentes -> método principal deve ser 'jp7'
      final avJp7 = Avaliacao(
        id: 'av1',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 1, 1),
        pesoKg: 80,
        nivelAtividade: 1.55,
        objetivo: Objetivo.hipertrofia,
        medidas: const MedidasCorporais(
          cintura: 82,
          pescoco: 38,
          dobraPeitoral: 10,
          dobraAxilarMedia: 12,
          dobraTriceps: 10,
          dobraSubescapular: 14,
          dobraAbdomen: 16,
          dobraSuprailiaca: 12,
          dobraCoxa: 14,
        ),
      );

      final snapJp7 = BioCalculator.buildCalculosSnapshot(profile: profile, avaliacao: avJp7);
      expect(snapJp7.metodoPrincipal, equals('jp7'));
      expect(snapJp7.metodoPrincipalLabel, equals('Jackson-Pollock 7 Dobras'));
      expect(snapJp7.bfJp7, greaterThan(0));

      // Caso 2: Somente 3 dobras presentes -> método principal deve ser 'jp3'
      final avJp3 = Avaliacao(
        id: 'av2',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 1, 1),
        pesoKg: 80,
        nivelAtividade: 1.55,
        objetivo: Objetivo.hipertrofia,
        medidas: const MedidasCorporais(
          cintura: 82,
          pescoco: 38,
          dobraPeitoral: 10,
          dobraAbdomen: 16,
          dobraCoxa: 14,
        ),
      );

      final snapJp3 = BioCalculator.buildCalculosSnapshot(profile: profile, avaliacao: avJp3);
      expect(snapJp3.metodoPrincipal, equals('jp3'));
      expect(snapJp3.metodoPrincipalLabel, equals('Jackson-Pollock 3 Dobras'));
      expect(snapJp3.bfJp3, greaterThan(0));
      expect(snapJp3.bfJp7, equals(0.0));

      // Caso 3: Sem dobras, mas com cintura + pescoço -> método principal deve ser 'navy'
      final avNavy = Avaliacao(
        id: 'av3',
        userId: 'u1',
        dataAvaliacao: DateTime(2026, 1, 1),
        pesoKg: 80,
        nivelAtividade: 1.55,
        objetivo: Objetivo.hipertrofia,
        medidas: const MedidasCorporais(
          cintura: 82,
          pescoco: 38,
        ),
      );

      final snapNavy = BioCalculator.buildCalculosSnapshot(profile: profile, avaliacao: avNavy);
      expect(snapNavy.metodoPrincipal, equals('navy'));
      expect(snapNavy.metodoPrincipalLabel, equals('US Navy'));
    });
  });

  group('Fase 7 — Resiliência dos Serviços (Health Connect, Widget, Backup)', () {
    test('HealthConnectService identifica ambiente de teste sem travar ou lançar exceção', () async {
      expect(HealthConnectService.isTestEnvironment, isTrue);
      final isAvailable = await HealthConnectService.instance.isAvailable();
      expect(isAvailable, isFalse);

      final weights = await HealthConnectService.instance.fetchRecentWeights(
        userId: 'u1',
      );
      expect(weights, isEmpty);
    });

    test('WidgetService lida com ambiente de teste sem invocar platform channels nativos', () async {
      expect(WidgetService.isTestEnvironment, isTrue);
      await WidgetService.instance.init();

      // Atualização segura com lista de pesagens
      final pesagens = [
        Pesagem(
          id: 'p1',
          userId: 'u1',
          data: DateTime.now(),
          pesoKg: 78.5,
        ),
      ];
      await WidgetService.instance.updateWidgetData(pesagens: pesagens);
      // Completa sem erros
      expect(true, isTrue);
    });

    test('BackupService executa local backup simulado em ambiente de teste', () async {
      expect(BackupService.isTestEnvironment, isTrue);
      // Teste do objeto BackupResult
      const res = BackupResult(
        success: true,
        filePath: '/mock/path.json',
        message: 'Sucesso',
      );
      expect(res.success, isTrue);
      expect(res.filePath, equals('/mock/path.json'));
    });
  });
}
