import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// Instância global única do Supabase para evitar recriar a conexão a cada request
SupabaseClient? _supabaseClient;

Handler middleware(Handler handler) {
  return _comCors((context) async {
    // Inicializa o cliente do Supabase apenas uma vez (Lazy Loading seguro)
    if (_supabaseClient == null) {
      final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
          'https://fshgacospypbgxzzpnxt.supabase.co';

      final supabaseKey = Platform.environment['SUPABASE_ANON_KEY'] ??
          'sb_publishable_DkO4BfBFcSI3bBeUhojB1Q_pjFPdlMj';

      _supabaseClient = SupabaseClient(
        supabaseUrl,
        supabaseKey,
      );
    }

    final newContext = context.provide<SupabaseClient>(
      () => _supabaseClient!,
    );

    return await handler(newContext);
  });
}

Handler _comCors(Handler handler) {
  return (context) async {
    final metodo = context.request.method;

    // Se não for um método mapeado, passa adiante
    if (metodo != HttpMethod.get &&
        metodo != HttpMethod.post &&
        metodo != HttpMethod.put &&
        metodo != HttpMethod.delete &&
        metodo != HttpMethod.options) {
      return await handler(context);
    }

    final origem = context.request.headers['origin'];

    // CORREÇÃO: Se a origem vier nula (ex: aplicativos nativos Android/iOS), 
    // liberamos explicitamente com '*' ou com a própria origem informada.
    final corsOrigin = (origem != null && origem.isNotEmpty) ? origem : '*';

    final cors = <String, String>{
      'Access-Control-Allow-Origin': corsOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization, apikey',
      'Vary': 'Origin',
    };

    // Responde imediatamente às requisições de teste pré-flight do navegador (OPTIONS)
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