# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copie des dépendances
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copie du code source et build web
COPY . .
RUN flutter build web --release

# Stage 2: Serveur Web Nginx léger
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
