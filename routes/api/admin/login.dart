import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

// Função para retornar mensagens padronizadas de erro
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

  // Recupera o cliente do Supabase injetado pelo middleware com segurança
  SupabaseClient? supabase;
  try {
    supabase = context.read<SupabaseClient>();
  } catch (e) {
    print('SupabaseClient não encontrado no RequestContext: $e');
    supabase = null;
  }

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

  try {
    // Busca o administrador na tabela 'admin' pelo e-mail
    final adminEncontrado = await supabase
        .from('admin')
        .select('id_adm, nome, email, senha')
        .eq('email', email)
        .maybeSingle();

    if (adminEncontrado == null) {
      return respostaErro(401, 'E-mail ou senha inválidos!');
    }

    final idAdmin = adminEncontrado['id_adm']?.toString() ?? '';
    final nomeAdmin = adminEncontrado['nome']?.toString() ?? '';
    final emailAdmin = adminEncontrado['email']?.toString() ?? '';
    final senhaArmazenada = adminEncontrado['senha']?.toString() ?? '';

    // Gera o mesmo hash SHA-256 em Base64 usado no cadastrar.dart
    final senhaHashEnviada =
        base64Encode(sha256.convert(utf8.encode(senha)).bytes);

    if (senhaArmazenada.isEmpty || senhaHashEnviada != senhaArmazenada) {
      return respostaErro(401, 'E-mail ou senha inválidos!');
    }

    // Login validado com sucesso
    return Response.json(
      statusCode: 200,
      body: {
        'sucesso': true,
        'mensagem': 'Login realizado com sucesso!',
        'usuario': {
          'id_adm': idAdmin,
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