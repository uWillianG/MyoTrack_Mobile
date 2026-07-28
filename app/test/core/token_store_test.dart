import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myotrack/core/auth/token_store.dart';

/// Monta um JWT sem assinatura válida — o TokenStore só lê o payload, e é isso
/// que o teste precisa exercitar.
String _jwtWithPayload(Map<String, dynamic> payload) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(json.encode(m))).replaceAll('=', '');
  return '${seg({'alg': 'HS256'})}.${seg(payload)}.assinatura-falsa';
}

void main() {
  const dotNetClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  test('lê o claim curto `role` como lista', () {
    final token = _jwtWithPayload({
      'sub': '1',
      'role': ['Trainer', 'Admin'],
    });

    expect(TokenStore.rolesFromAccessToken(token), ['Trainer', 'Admin']);
  });

  test(
    'aceita o claim como string única — é assim que vem com um papel só',
    () {
      final token = _jwtWithPayload({'sub': '1', 'role': 'Student'});

      expect(TokenStore.rolesFromAccessToken(token), ['Student']);
    },
  );

  test(
    'lê o claim longo do .NET, para tokens emitidos pelo backend antigo',
    () {
      final token = _jwtWithPayload({
        'sub': '1',
        dotNetClaim: ['Nutritionist'],
      });

      expect(TokenStore.rolesFromAccessToken(token), ['Nutritionist']);
    },
  );

  test('token sem papéis devolve lista vazia', () {
    expect(
      TokenStore.rolesFromAccessToken(_jwtWithPayload({'sub': '1'})),
      isEmpty,
    );
  });

  test(
    'token malformado não lança — a UI só perde os itens de menu por papel',
    () {
      expect(TokenStore.rolesFromAccessToken('nao-e-um-jwt'), isEmpty);
      expect(TokenStore.rolesFromAccessToken('a.b'), isEmpty);
      expect(TokenStore.rolesFromAccessToken(''), isEmpty);
      expect(
        TokenStore.rolesFromAccessToken('a.!!!nao-e-base64!!!.c'),
        isEmpty,
      );
    },
  );
}
