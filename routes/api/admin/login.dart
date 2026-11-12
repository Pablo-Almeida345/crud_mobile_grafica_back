
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

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
<<<<<<< HEAD
  if (context.request.method.name.toUpperCase() != 'POST') {
    return Response.json(statusCode: 405, body: {'erro': 'Método não permitido'});
  }

  final supabase = context.read<SupabaseClient?>();
  if (supabase == null) {
    return Response.json(
      statusCode: 500,
      body: {'sucesso': false, 'mensagem': 'Cliente do Supabase indisponível.'},
=======

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
>>>>>>> f6a0d4e75e2f369ce3c630d8ba5fb13b41ce971f
    );
  }

  try {
<<<<<<< HEAD
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

    // Abordagem blindada: Executa a query e converte explicitamente para evitar qualquer erro de tipagem na linha 47/48
    final response = await supabase
        .from('administradores')
        .select()
        .eq('email', email);

    // Converte o resultado de forma segura para uma lista de mapas
    final List<dynamic> lista = response as List<dynamic>;

    if (lista.isNotEmpty) {
      return Response.json(
        statusCode: 400, 
        body: {'sucesso': false, 'mensagem': 'Este e-mail já está cadastrado!'}
      );
    }

    // Insere o novo administrador alinhado com as colunas da tabela do Supabase
    await supabase.from('administradores').insert({
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senha,
    });
=======
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
>>>>>>> f6a0d4e75e2f369ce3c630d8ba5fb13b41ce971f

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
      statusCode: 201,
      body: {
<<<<<<< HEAD
        'sucesso': true, 
        'mensagem': 'Cadastro realizado com sucesso!', 
        'admin': {
          'nome': nome,
          'email': email,
          'cpf': cpf,
        }
=======
        'sucesso': true,
        'mensagem': 'Login realizado com sucesso!',
        'usuario': {
          'id': idAdmin,
          'nome': nomeAdmin,
          'email': emailAdmin,
        },
>>>>>>> f6a0d4e75e2f369ce3c630d8ba5fb13b41ce971f
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
