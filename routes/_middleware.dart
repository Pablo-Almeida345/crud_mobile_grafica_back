import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Handler middleware(Handler handler) {
  return _comCors((context) async {
    final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
        'https://fshgacospypbgxzzpnxt.supabase.co';

    final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ??
        'sb_publishable_DkO4BfBFcSI3bBeUhojB1Q_pjFPdlMj';

    final supabase = SupabaseClient(
      supabaseUrl,
      supabaseKey,
    );

    final newContext = context.provide<SupabaseClient>(
      () => supabase,
    );

    return await handler(newContext);
  });
}

Handler _comCors(Handler handler) {
  return (context) async {
    final metodo = context.request.method;

    // Mantém os outros métodos com o comportamento existente.
    if (metodo != HttpMethod.get &&
        metodo != HttpMethod.post &&
        metodo != HttpMethod.options) {
      return await handler(context);
    }

    const origensPermitidas = {
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://localhost:8081',
      'http://127.0.0.1:8081',
    };

    final origem = context.request.headers['origin'];

    final cors = <String, String>{
      if (origem != null && origensPermitidas.contains(origem))
        'Access-Control-Allow-Origin': origem,
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Accept, Content-Type',
      'Vary': 'Origin',
    };

    // A verificação do navegador não precisa acessar o banco.
    if (metodo == HttpMethod.options) {
      return Response(
        statusCode: HttpStatus.noContent,
        headers: cors,
      );
    }

    try {
      final resposta = await handler(context);

      final varyAnterior =
          resposta.headers['vary'] ?? resposta.headers['Vary'] ?? '';

      final vary = varyAnterior
          .split(',')
          .map((valor) => valor.trim())
          .where((valor) => valor.isNotEmpty)
          .toList();

      if (!vary.any(
        (valor) => valor == '*' || valor.toLowerCase() == 'origin',
      )) {
        vary.add('Origin');
      }

      final headers = <String, String>{
        ...resposta.headers,
        ...cors,
      };

      headers.removeWhere(
        (nome, _) => nome.toLowerCase() == 'vary',
      );

      headers['Vary'] = vary.contains('') ? '' : vary.join(', ');

      return resposta.copyWith(headers: headers);
    } catch (_, stackTrace) {
      stderr.writeln('Erro interno ao processar a requisição.');
      stderr.writeln(stackTrace);

      return Response.json(
        statusCode: HttpStatus.internalServerError,
        headers: cors,
        body: {
          'error': 'Erro interno no servidor.',
        },
      );
    }
  };
}