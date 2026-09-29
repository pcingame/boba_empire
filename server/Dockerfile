# Build 2 giai đoạn: biên dịch AOT ở image đầy đủ (có SDK), CHẠY ở image
# `dart:stable` gốc — nhỏ, khởi động nhanh, đúng khuyến nghị chính thức của
# Dart cho Cloud Run (https://dart.dev/tools/cloud/cloud-run).
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM dart:stable
COPY --from=build /app/bin/server /app/bin/server

# Cloud Run tự đặt biến PORT — server.dart đã đọc đúng biến này
# (Platform.environment['PORT'] ?? '8080').
EXPOSE 8080
CMD ["/app/bin/server"]
