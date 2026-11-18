# Estágio de Build (Usa a SDK do Dart para compilar o binário completo)
FROM dart:stable AS build

WORKDIR /app

# Ativa o CLI do Dart Frog e puxa as dependências
RUN dart pub global activate dart_frog_cli
COPY pubspec.* ./
RUN dart pub get

# Copia todo o código fonte e as rotas
COPY . .

# Gera o build de produção do Dart Frog (cria a pasta build/)
RUN dart pub global run dart_frog_cli:dart_frog build

# Compila o binário standalone definitivo do servidor do Dart Frog
RUN dart compile exe build/bin/server.dart -o bin/server

# Estágio de Execução Final (Imagem super leve e limpa)
FROM debian:bookworm-slim

WORKDIR /app

# Copia o binário compilado e os arquivos necessários do build
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/build /app/build

EXPOSE 8080

# Inicia o binário compilado diretamente
CMD ["./bin/server"]