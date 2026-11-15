import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Cliente que responde siempre con el código y el cuerpo indicados.
ApiClient clienteQueResponde(int codigo, [Object? cuerpo]) {
  final mock = MockClient((request) async {
    return http.Response(cuerpo == null ? '' : jsonEncode(cuerpo), codigo);
  });
  return ApiClient(client: mock, baseUrl: 'http://prueba');
}

void main() {
  group('Respuestas exitosas', () {
    test('GET exitoso devuelve el JSON decodificado', () async {
      final api = clienteQueResponde(200, [
        {'id': 1},
      ]);

      final resultado = await api.get('/orders');

      expect(resultado, isA<List>());
      expect(resultado, [
        {'id': 1},
      ]);
    });
  });

  group('Errores del servidor mapeados a Failure', () {
    test('404 lanza NotFoundFailure con el mensaje de detail', () async {
      final api = clienteQueResponde(404, {'detail': 'Order 9 not found'});

      await expectLater(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Order 9 not found',
          ),
        ),
      );
    });

    test('409 lanza ConflictFailure con el mensaje de detail', () async {
      final api = clienteQueResponde(409, {
        'detail': 'Cannot change status from pending to delivered',
      });

      await expectLater(
        api.patch('/orders/1', {'status': 'delivered'}),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Cannot change status from pending to delivered',
          ),
        ),
      );
    });

    test('422 lanza ValidationFailure con el campo y su mensaje', () async {
      final api = clienteQueResponde(422, {
        'detail': [
          {
            'loc': ['body', 'customer'],
            'msg': 'Must be 1-50 characters',
          },
        ],
      });

      await expectLater(
        api.post('/orders', {'customer': ''}),
        throwsA(
          isA<ValidationFailure>().having((f) => f.fields, 'fields', {
            'customer': 'Must be 1-50 characters',
          }),
        ),
      );
    });

    test('503 lanza ServerFailure con statusCode 503', () async {
      final api = clienteQueResponde(503);

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('300 no es éxito y lanza UnexpectedFailure', () async {
      final api = clienteQueResponde(300);

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            300,
          ),
        ),
      );
    });

    test('un 404 sin JSON usa el mensaje genérico', () async {
      final api = ApiClient(
        client: MockClient((request) async => http.Response('<html>', 404)),
        baseUrl: 'http://prueba',
      );

      await expectLater(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Orden no encontrada',
          ),
        ),
      );
    });
  });

  group('Fallos de red', () {
    test('sin conexión lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('sin red');
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });

    test('tiempo agotado lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return http.Response('[]', 200);
      });
      final api = ApiClient(
        client: mock,
        baseUrl: 'http://prueba',
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });
  });
}
