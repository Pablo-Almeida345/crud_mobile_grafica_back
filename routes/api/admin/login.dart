import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  // Pega a conexão injetada globalmente pelo _middleware.dart
  final connection = context.read<Connection?>();
  if (connection == null) {
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Conexão com o banco de dados indisponível.'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'];
    final senha = body['senha'];

    if (email == null || senha == null || email.toString().isEmpty || senha.toString().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'sucesso': false, 'mensagem': 'E-mail e senha são obrigatórios para o login!'}
      );
    }

    // Consulta o administrador na base de dados
    final resultado = await connection.execute(
      Sql.named('SELECT nome, email FROM administradores WHERE email = @email AND senha = @senha'),
      parameters: {
        'email': email,
        'senha': senha,
      },
    );

    if (resultado.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {'sucesso': false, 'mensagem': 'E-mail ou senha inválidos!'}
      );
    }

    final adminEncontrado = resultado.first;

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
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Erro interno no servidor: $e'},
    );
  }
}