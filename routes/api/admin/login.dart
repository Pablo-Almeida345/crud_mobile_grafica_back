
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

// Função para retornar mensagens de erro
Response respostaErro(int statusCode, String mensagem) {
  return Response.json(
    statusCode: statusCode,
    body: {
      'sucesso': false,
      'mensagem': mensagem,
    },
  );
}

// Rota de login do administrador
Future<Response> onRequest(RequestContext context) async {

  // Aceita somente requisições POST
  if (context.request.method != HttpMethod.post) {
    return respostaErro(
      405,
      'Método não permitido.',
    );
  }

  // Recebe os dados enviados pelo frontend
  dynamic dados;

  try {
    dados = await context.request.json();
  } on FormatException {
    return respostaErro(
      400,
      'JSON inválido.',
    );
  } catch (e) {
    return respostaErro(
      400,
      'Não foi possível ler os dados enviados.',
    );
  }

  // Verifica se os dados estão no formato correto
  if (dados is! Map<String, dynamic>) {
    return respostaErro(
      400,
      'Formato de dados inválido.',
    );
  }

  // Recupera o e-mail e a senha
  final email =
      dados['email']?.toString().trim().toLowerCase() ?? '';

  final senha =
      dados['senha']?.toString() ?? '';

  // Verifica se os campos estão preenchidos
  if (email.isEmpty || senha.isEmpty) {
    return respostaErro(
      400,
      'E-mail e senha são obrigatórios para o login!',
    );
  }

  // Validação do formato do e-mail
  final regexEmail = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  if (!regexEmail.hasMatch(email)) {
    return respostaErro(
      400,
      'E-mail inválido!',
    );
  }

  // Verifica o limite de bytes da senha
  if (utf8.encode(senha).length > 72) {
    return respostaErro(
      400,
      'A senha excede o limite de 72 bytes.',
    );
  }

  try {
    // Recupera a conexão injetada pelo middleware
    final connection = context.read<Connection?>();

    // Verifica se a conexão está disponível
    if (connection == null) {
      return respostaErro(
        500,
        'Conexão com o banco de dados indisponível.',
      );
    }

    // Busca o administrador pelo e-mail
    final resultado = await connection.execute(
      Sql.named('''
        SELECT
          id,
          nome,
          email,
          senha
        FROM administradores
        WHERE email = @email
        LIMIT 1
      '''),
      parameters: {
        'email': email,
      },
    );

    // Verifica se o administrador existe
    if (resultado.isEmpty) {
      return respostaErro(
        401,
        'E-mail ou senha inválidos!',
      );
    }

    // Recupera os dados do administrador
    final adminEncontrado = resultado.first.toColumnMap();

    final idAdmin =
        adminEncontrado['id'].toString();

    final nomeAdmin =
        adminEncontrado['nome'].toString();

    final emailAdmin =
        adminEncontrado['email'].toString();

    final senhaHash =
        adminEncontrado['senha']?.toString() ?? '';

    // Verifica se a senha armazenada é um hash BCrypt
    if (!senhaHash.startsWith(r'$2')) {
      return respostaErro(
        401,
        'E-mail ou senha inválidos!',
      );
    }

    // Compara a senha informada com o hash armazenado
    bool senhaCorreta = false;

    try {
      senhaCorreta = BCrypt.checkpw(
        senha,
        senhaHash,
      );
    } catch (e) {
      // Hash inválido ou incompatível
      senhaCorreta = false;
    }

    // Bloqueia o login caso a senha esteja incorreta
    if (!senhaCorreta) {
      return respostaErro(
        401,
        'E-mail ou senha inválidos!',
      );
    }

    // Login validado com sucesso
    return Response.json(
      statusCode: 200,
      body: {
        'sucesso': true,
        'mensagem': 'Login realizado com sucesso!',
        'usuario': {
          'id': idAdmin,
          'nome': nomeAdmin,
          'email': emailAdmin,
        },
      },
    );

  } catch (e) {
    // Registra o erro no terminal do backend
    print('Erro no login do administrador: $e');

    // Retorna mensagem genérica ao frontend
    return respostaErro(
      500,
      'Erro interno ao realizar login.',
    );
  }
}
