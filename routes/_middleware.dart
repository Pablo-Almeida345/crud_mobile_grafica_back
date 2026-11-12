import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart' as env;
import 'package:supabase/supabase.dart';

SupabaseClient? _supabaseClient;
final _dotenv = env.DotEnv(includePlatformEnvironment: true)..load();

Handler middleware(Handler handler) {
  return (context) async {
    try {
      if (_supabaseClient == null) {
        final supabaseUrl = _dotenv['SUPABASE_URL'] ?? Platform.environment['SUPABASE_URL'] ?? '';
        final supabaseKey = _dotenv['SUPABASE_PUBLISHABLE_KEY'] ?? Platform.environment['SUPABASE_PUBLISHABLE_KEY'] ?? '';

        if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
          print('❌ ERRO: SUPABASE_URL ou SUPABASE_PUBLISHABLE_KEY não encontrados no .env!');
        } else {
          print('🔌 A inicializar o cliente Supabase...');
          
          _supabaseClient = SupabaseClient(supabaseUrl, supabaseKey);
          
          print('✅ Supabase inicializado com sucesso!');
        }
      }
    } catch (e) {
      print('❌ ERRO AO INICIALIZAR SUPABASE: $e');
    }

    // Injeta o cliente do Supabase no contexto das rotas
    return handler.use(provider<SupabaseClient?>((_) => _supabaseClient))(context);
  };
}