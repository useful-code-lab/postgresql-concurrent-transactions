FROM postgres:16-alpine

# Устанавливаем часовой пояс (важно для транзакций)
ENV TZ=Europe/Moscow

# Все .sql файлы из папки migrations будут выполнены при первом старте
COPY ./migrations/ /docker-entrypoint-initdb.d/
