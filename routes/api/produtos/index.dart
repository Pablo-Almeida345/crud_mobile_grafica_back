import 'dart:io';
import 'package:crud_mobile_grafica_back/models/produtos.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getProdutos(context);
    case HttpMethod.post:
      return _cadastrarProduto(context);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

// 🟢 GET: Buscar todos os produtos
Future<Response> _getProdutos(RequestContext context) async {
  try {
    final connection = context.read<Connection?>();
    if (connection == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Conexão com o banco de dados não disponível.'},
      );
    }

    final results = await connection.execute(
      'SELECT id, nome, descricao, preco, imagem_url FROM produto ORDER BY id DESC',
    );

    final listaProdutos = results.map((row) {
      return Produto(
        id: row[0] as int,
        nome: row[1] as String,
        descricao: row[2] as String,
        preco: (row[3] as num).toDouble(),
        imagemUrl: row[4] as String,
      ).toJson();
    }).toList();

    return Response.json(body: listaProdutos);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'erro': 'Erro ao buscar produtos: ${e.toString()}'},
    );
  }
}

// 🔵 POST: Cadastrar novo produto
Future<Response> _cadastrarProduto(RequestContext context) async {
  try {
    final connection = context.read<Connection?>();
    if (connection == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'erro': 'Conexão com o banco de dados não disponível.'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final produto = Produto.fromJson(body);

    final result = await connection.execute(
      Sql.named(
        'INSERT INTO produto (nome, descricao, preco, imagem_url) '
        'VALUES (@nome, @descricao, @preco, @imagemUrl) RETURNING id',
      ),
      parameters: {
        'nome': produto.nome,
        'descricao': produto.descricao,
        'preco': produto.preco,
        'imagemUrl': produto.imagemUrl,
      },
    );

    final idGerado = result.first[0];

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'mensagem': 'Produto cadastrado com sucesso!',
        'id': idGerado,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'erro': 'Erro ao cadastrar produto: ${e.toString()}'},
    );
  }
}