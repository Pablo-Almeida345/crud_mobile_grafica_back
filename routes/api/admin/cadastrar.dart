import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';

const uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  // Pega a conexão injetada pelo _middleware.dart global
  final connection = context.read<Connection?>();
  if (connection == null) {
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Conexão com o banco de dados indisponível.'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    
    final nome = body['nome'];
    final email = body['email'];
    final cpf = body['cpf'];
    final senha = body['senha'];
    final confirmarSenha = body['confirmarSenha'];

    if (nome == null || email == null || cpf == null || senha == null || confirmarSenha == null ||
        nome.toString().isEmpty || email.toString().isEmpty || cpf.toString().isEmpty || senha.toString().isEmpty || confirmarSenha.toString().isEmpty) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'Todos os campos são obrigatórios!'}
      );
    }

    if (senha != confirmarSenha) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'A senha e a confirmação de senha não coincidem!'}
      );
    }

    // Verifica se o e-mail já existe
    final resultadoEmail = await connection.execute(
      Sql.named('SELECT id FROM administradores WHERE email = @email'),
      parameters: {'email': email},
    );

    if (resultadoEmail.isNotEmpty) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'Este e-mail já está cadastrado!'}
      );
    }

    final novoId = uuid.v4();

    // Insere o novo administrador
    await connection.execute(
      Sql.named('INSERT INTO administradores (id, nome, email, cpf, senha) VALUES (@id, @nome, @email, @cpf, @senha)'),
      parameters: {
        'id': novoId,
        'nome': nome,
        'email': email,
        'cpf': cpf,
        'senha': senha, // Dica: futuramente lembra-te de fazer o hash da senha (ex: com bcrypt) antes de salvar!
      },
    );

    return Response.json(
      statusCode: 201,
      body: {
        'sucesso': true, 
        'mensagem': 'Cadastro realizado com sucesso!', 
        'admin': {
          'id': novoId,
          'nome': nome,
          'email': email,
          'cpf': cpf,
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