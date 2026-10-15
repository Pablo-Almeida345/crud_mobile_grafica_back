import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

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

    final verifProduto = await connection.execute(
      Sql.named('SELECT id, nome, preco, estoque FROM produtos WHERE id = @id'),
      parameters: {'id': id},
    );

    if (verifProduto.isEmpty) {
      await connection.close();
      return Response.json(statusCode: 404, body: {'erro': 'Produto não encontrado'});
    }

    final produtoAtual = verifProduto.first;

    if (method == HttpMethod.put) {
      final body = await context.request.json() as Map<String, dynamic>;

      final novoNome = body['nome'] ?? produtoAtual[1];
      final novoPreco = body['preco'] ?? produtoAtual[2];
      final novoEstoque = body['estoque'] ?? produtoAtual[3];

      await connection.execute(
        Sql.named('UPDATE produtos SET nome = @nome, preco = @preco, estoque = @estoque WHERE id = @id'),
        parameters: {
          'id': id,
          'nome': novoNome,
          'preco': novoPreco,
          'estoque': novoEstoque,
        },
      );

      await connection.close();

      return Response.json(
        statusCode: 200,
        body: {
          'mensagem': 'Produto atualizado com sucesso!',
          'produto': {
            'id': id,
            'nome': novoNome,
            'preco': novoPreco,
            'estoque': novoEstoque,
          }
        },
      );
    }

    if (method == HttpMethod.delete) {
      await connection.execute(
        Sql.named('DELETE FROM produtos WHERE id = @id'),
        parameters: {'id': id},
      );

      await connection.close();

      return Response.json(
        statusCode: 200,
        body: {'mensagem': 'Produto deletado com sucesso!'},
      );
    }

    await connection.close();
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
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