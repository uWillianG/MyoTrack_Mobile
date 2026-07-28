import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/features/auth/widgets/password_rules.dart';

void main() {
  bool satisfies(String label, String password) => PasswordRule.all
      .firstWhere((r) => r.label.contains(label))
      .isSatisfied(password);

  group('regras individuais', () {
    test('comprimento mínimo de 8', () {
      expect(satisfies('8 caracteres', 'Ab1!efg'), isFalse);
      expect(satisfies('8 caracteres', 'Ab1!efgh'), isTrue);
    });

    test('maiúscula, minúscula, número e símbolo', () {
      expect(satisfies('maiúscula', 'abcdefg1!'), isFalse);
      expect(satisfies('maiúscula', 'Abcdefg1!'), isTrue);

      expect(satisfies('minúscula', 'ABCDEFG1!'), isFalse);
      expect(satisfies('minúscula', 'ABCDEFg1!'), isTrue);

      expect(satisfies('número', 'Abcdefgh!'), isFalse);
      expect(satisfies('número', 'Abcdefg1!'), isTrue);

      expect(satisfies('símbolo', 'Abcdefg12'), isFalse);
      expect(satisfies('símbolo', 'Abcdefg1!'), isTrue);
    });

    test(
      'letras acentuadas contam — o público é brasileiro e o servidor as aceita',
      () {
        // Sem as faixas acentuadas, a tela diria "falta maiúscula" numa senha que o
        // backend aprovaria, e o usuário ficaria sem entender o que fazer.
        expect(satisfies('maiúscula', 'Ácido!9abc'), isTrue);
        expect(satisfies('minúscula', 'ÁCIDÕ!9á'), isTrue);
      },
    );

    test('acento não é símbolo', () {
      // 'á' é letra; se contasse como símbolo, a tela aprovaria uma senha que o
      // servidor recusaria por falta de caractere não alfanumérico.
      expect(satisfies('símbolo', 'Abcdefgá1'), isFalse);
    });
  });

  group('allSatisfied', () {
    test('aprova senha que cumpre as cinco regras', () {
      expect(PasswordRule.allSatisfied('Tr0vao!Verde9'), isTrue);
      expect(PasswordRule.allSatisfied('Cachorro#Azul42'), isTrue);
    });

    test('reprova quando falta qualquer uma', () {
      expect(PasswordRule.allSatisfied(''), isFalse);
      expect(PasswordRule.allSatisfied('senha123'), isFalse);
      expect(PasswordRule.allSatisfied('SENHA123!'), isFalse);
      expect(PasswordRule.allSatisfied('Senha123'), isFalse);
    });

    test(
      'aprova "Senha@123" — a composição basta aqui; a lista de vazadas é do servidor',
      () {
        // A tela não tem como saber que esta senha está em todo dicionário de ataque.
        // O backend recusa e devolve "Essa senha é muito comum"; é assim que o usuário
        // descobre. Duplicar a lista de 20 mil senhas no app não valeria o tamanho.
        expect(PasswordRule.allSatisfied('Senha@123'), isTrue);
      },
    );
  });
}
