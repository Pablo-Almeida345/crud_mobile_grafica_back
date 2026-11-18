FROM dart:stable AS build

WORKDIR /app

# Ativa o CLI do Dart Frog
RUN dart pub global activate dart_frog_cli

# Baixa as dependências
COPY pubspec.* ./
RUN dart pub get

# Copia todo o código fonte
COPY . .

# CRUCIAL: Este comando gera a pasta build/ com as rotas que o Render procura
RUN dart pub global run dart_frog_cli:dart_frog build

# Compila o binário otimizado para produção
RUN dart compile exe build/bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]