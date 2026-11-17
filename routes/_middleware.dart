import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// Instância global única do Supabase
SupabaseClient? _supabaseClient;

Handler middleware(Handler handler) {
  // 1. Inicializa o cliente do Supabase utilizando o .env
  if (_supabaseClient == null) {
    final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? 'https://fshgacospypbgxzzpnxt.supabase.co';
    final supabaseKey = Platform.environment['SUPABASE_PUBLISHABLE_KEY'] ?? 'sb_publishable_DkO4BfBFcSI3bBeUhojB1Q_pjFPdlMj';

    _supabaseClient = SupabaseClient(
      supabaseUrl,
      supabaseKey,
    );
  }

  // 2. Injeta o Supabase usando o provider oficial do Dart Frog e aplica o CORS
  return handler
      .use(provider<SupabaseClient>((context) => _supabaseClient!))
      .use(_addCorsHeaders());
}

// Middleware dedicado apenas para gerenciar os Headers CORS
Middleware _addCorsHeaders() {
  return (handler) {
    return (context) async {
      final request = context.request;
      final origin = request.headers['origin'] ?? '*';

      final corsHeaders = {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Accept, Content-Type, Authorization, apikey',
        'Vary': 'Origin',
      };

      // Responde imediatamente a requisições OPTIONS (Pre-flight)
      if (request.method == HttpMethod.options) {
        return Response(statusCode: HttpStatus.noContent, headers: corsHeaders);
      }

      try {
        final response = await handler(context);
        return response.copyWith(
          headers: {
            ...response.headers,
            ...corsHeaders,
          },
        );
      } catch (_, stackTrace) {
        stderr.writeln('Erro interno ao processar a requisição.');
        stderr.writeln(stackTrace);

        return Response.json(
          statusCode: HttpStatus.internalServerError,
          headers: corsHeaders,
          body: {'error': 'Erro interno no servidor.'},
        );
      }
    };
  };
}