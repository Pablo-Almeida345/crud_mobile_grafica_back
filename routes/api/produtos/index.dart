import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';

const uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
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

    if (method == HttpMethod.post) {
      final body = await context.request.json() as Map<String, dynamic>;
      
      final String id = uuid.v4();
      final nome = body['nome'];
      final preco = body['preco'];
      final estoque = body['estoque'];

      await connection.execute(
        Sql.named('INSERT INTO produtos (id, nome, preco, estoque) VALUES (@id, @nome, @preco, @estoque)'),
        parameters: {
          'id': id,
          'nome': nome,
          'preco': preco,
          'estoque': estoque,
        },
      );

      await connection.close();

      final novoProduto = {
        'id': id,
        'nome': nome,
        'preco': preco,
        'estoque': estoque,
      };

      return Response.json(
        statusCode: 201,
        body: {'mensagem': 'Produto cadastrado com sucesso!', 'produto': novoProduto},
      );
    }

    if (method == HttpMethod.get) {
      final resultado = await connection.execute('SELECT id, nome, preco, estoque FROM produtos');

      await connection.close();

      final produtosBD = resultado.map((linha) => {
        'id': linha[0],
        'nome': linha[1],
        'preco': linha[2],
        'estoque': linha[3],
      }).toList();

      return Response.json(statusCode: 200, body: produtosBD);
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