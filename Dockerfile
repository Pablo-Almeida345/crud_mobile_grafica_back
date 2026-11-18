FROM dart:stable AS build

WORKDIR /app

# Instala o CLI do Dart Frog
RUN dart pub global activate dart_frog_cli

# Copia as dependências e baixa os pacotes
COPY pubspec.* ./
RUN dart pub get

# Copia o restante do código
COPY . .

# IMPORTANTE: Gera a build de produção do Dart Frog (crucial para as rotas funcionarem)
RUN dart pub global run dart_frog_cli:dart_frog build

# Compila o binário otimizado
RUN dart compile exe build/bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]