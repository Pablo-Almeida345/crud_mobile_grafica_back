import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'];
  final senha = body['senha'];

  if (email == null || senha == null || email.toString().isEmpty || senha.toString().isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'sucesso': false, 'mensagem': 'E-mail e senha são obrigatórios para o login!'}
    );
  }

  Connection? connection;

  try {
    connection = await Connection.open(
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME'] ?? 'postgres',
        username: Platform.environment['DB_USER'] ?? 'postgres',
        password: Platform.environment['DB_PASSWORD'] ?? '',
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    final resultado = await connection.execute(
      Sql.named('SELECT nome, email FROM administradores WHERE email = @email AND senha = @senha'),
      parameters: {
        'email': email,
        'senha': senha,
      },
    );

    if (resultado.isEmpty) {
      await connection.close();
      return Response.json(
        statusCode: 401,
        body: {'sucesso': false, 'mensagem': 'E-mail ou senha inválidos!'}
      );
    }

    final adminEncontrado = resultado.first;

    await connection.close();

    return Response.json(
      statusCode: 200,
      body: {
        'sucesso': true,
        'mensagem': 'Login realizado com sucesso!',
        'usuario': {
          'nome': adminEncontrado[0],
          'email': adminEncontrado[1]
        }
      },
    );
  } catch (e) {
    if (connection != null) {
      await connection.close();
    }
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Erro interno no servidor: $e'},
    );
  }
}