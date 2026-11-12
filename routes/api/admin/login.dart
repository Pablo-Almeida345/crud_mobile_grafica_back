import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

// Função para retornar mensagens de padronizadas de erro
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
  if (context.request.method.name.toUpperCase() != 'POST') {
    return respostaErro(405, 'Método não permitido.');
  }

  // Recupera o cliente do Supabase injetado pelo middleware
  final supabase = context.read<SupabaseClient?>();
  if (supabase == null) {
    return respostaErro(500, 'Cliente do Supabase indisponível.');
  }

  // Recebe os dados enviados pelo frontend
  dynamic dados;

  try {
    dados = await context.request.json();
  } on FormatException {
    return respostaErro(400, 'JSON inválido.');
  } catch (e) {
    return respostaErro(400, 'Não foi possível ler os dados enviados.');
  }

  // Verifica se os dados estão no formato correto
  if (dados is! Map<String, dynamic>) {
    return respostaErro(400, 'Formato de dados inválido.');
  }

  // Recupera o e-mail e a senha com normalização
  final email = dados['email']?.toString().trim().toLowerCase() ?? '';
  final senha = dados['senha']?.toString() ?? '';

  // Verifica se os campos estão preenchidos
  if (email.isEmpty || senha.isEmpty) {
    return respostaErro(400, 'E-mail e senha são obrigatórios para o login!');
  }

  // Validação simples do formato do e-mail
  final regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!regexEmail.hasMatch(email)) {
    return respostaErro(400, 'E-mail inválido!');
  }

  // Verifica o limite de bytes da senha (restrição do BCrypt)
  if (utf8.encode(senha).length > 72) {
    return respostaErro(400, 'A senha excede o limite de 72 bytes.');
  }

  try {
    // Busca o administrador no Supabase pelo e-mail
    final response = await supabase
        .from('administradores')
        .select()
        .eq('email', email)
        .maybeSingle();

    // Verifica se o administrador existe
    if (response == null) {
      return respostaErro(401, 'E-mail ou senha inválidos!');
    }

    final adminEncontrado = response;

    final idAdmin = adminEncontrado['id'].toString();
    final nomeAdmin = adminEncontrado['nome'].toString();
    final emailAdmin = adminEncontrado['email'].toString();
    final senhaHash = adminEncontrado['senha']?.toString() ?? '';

    // Verifica se a senha armazenada é um hash BCrypt válido
    if (!senhaHash.startsWith(r'$2')) {
      return respostaErro(401, 'E-mail ou senha inválidos!');
    }

    // Compara a senha informada com o hash armazenado
    bool senhaCorreta = false;
    try {
      senhaCorreta = BCrypt.checkpw(senha, senhaHash);
    } catch (e) {
      senhaCorreta = false;
    }

    // Bloqueia o login caso a senha esteja incorreta
    if (!senhaCorreta) {
      return respostaErro(401, 'E-mail ou senha inválidos!');
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

    return respostaErro(500, 'Erro interno ao realizar login.');
  }
}