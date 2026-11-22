import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

// Função para retornar mensagens de erro padronizadas
Response respostaErro(int statusCode, String mensagem) {
  return Response.json(
    statusCode: statusCode,
    body: {
      'sucesso': false,
      'mensagem': mensagem,
    },
  );
}

// Rota de cadastro de administrador
Future<Response> onRequest(RequestContext context) async {
  // Aceita somente requisições POST
  if (context.request.method.name.toUpperCase() != 'POST') {
    return respostaErro(405, 'Método não permitido.');
  }

  // Recebe os dados enviados pelo frontend / Postman
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

  // Recupera e limpa os campos do formulário
  final nome = dados['nome']?.toString().trim() ?? '';
  final email = dados['email']?.toString().trim().toLowerCase() ?? '';
  final cpf = dados['cpf']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
  final senha = dados['senha']?.toString() ?? '';
  final confirmarSenha = dados['confirmarSenha']?.toString() ?? '';

  // Validações básicas de preenchimento
  if (nome.isEmpty ||
      email.isEmpty ||
      cpf.isEmpty ||
      senha.isEmpty ||
      confirmarSenha.isEmpty) {
    return respostaErro(400, 'Todos os campos são obrigatórios!');
  }

  // Validação do nome
  if (nome.length < 3) {
    return respostaErro(400, 'O nome deve conter pelo menos 3 caracteres.');
  }

  // Validação do e-mail
  final regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!regexEmail.hasMatch(email)) {
    return respostaErro(400, 'E-mail inválido!');
  }

  // Validação apenas da quantidade de números do CPF (11 dígitos)
  if (!RegExp(r'^\d{11}$').hasMatch(cpf)) {
    return respostaErro(400, 'O CPF deve conter 11 números.');
  }

  // Validação do tamanho da senha
  if (senha.length < 8) {
    return respostaErro(400, 'A senha deve conter pelo menos 8 caracteres.');
  }

  // Confirma se as senhas coincidem
  if (senha != confirmarSenha) {
    return respostaErro(400, 'As senhas não coincidem!');
  }

  try {
    // Obtém o cliente do Supabase injetado pelo middleware
    final supabase = context.read<SupabaseClient>();

    // 1. Verifica se o e-mail já está cadastrado na tabela 'admin' usando 'id_adm'
    final resultadoEmail = await supabase
        .from('admin')
        .select('id_adm')
        .eq('email', email)
        .maybeSingle();

    if (resultadoEmail != null) {
      return respostaErro(409, 'Este e-mail já está cadastrado!');
    }

    // 2. Verifica se o CPF já está cadastrado na tabela 'admin' usando 'id_adm'
    final resultadoCpf = await supabase
        .from('admin')
        .select('id_adm')
        .eq('cpf', cpf)
        .maybeSingle();

    if (resultadoCpf != null) {
      return respostaErro(409, 'Este CPF já está cadastrado!');
    }

    // Gera um ID único (UUID v4) e cria o hash SHA-256 em Base64 (44 caracteres)
    final novoId = uuid.v4();
    final bytesSenha = utf8.encode(senha);
    final senhaCriptografada = base64Encode(sha256.convert(bytesSenha).bytes);

    // 3. Insere o novo administrador utilizando a coluna 'id_adm'
    await supabase.from('admin').insert({
      'id_adm': novoId,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senhaCriptografada,
    });

    // Retorna sucesso ao cadastrar
    return Response.json(
      statusCode: 201,
      body: {
        'sucesso': true,
        'mensagem': 'Administrador cadastrado com sucesso!',
        'admin': {
          'id_adm': novoId,
          'nome': nome,
          'email': email,
          'cpf': cpf,
        },
      },
    );
  } catch (e) {
    print('Erro no cadastro de administrador: $e');

    // Tratamento de segurança caso ocorra erro de duplicidade no banco
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('duplicate key') || errorString.contains('unique constraint')) {
      return respostaErro(409, 'Este e-mail ou CPF já está cadastrado no sistema.');
    }

    return respostaErro(500, 'Erro interno ao cadastrar administrador.');
  }
}