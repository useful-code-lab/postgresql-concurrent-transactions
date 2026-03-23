Для тестирования скриптов можно применить расширнение VSC 
```
Database Client
Database Client
database-client.com
```
1. Запуск docker `docker compose up -d`

2. Подключение к psql в 2-х окнах терминалов. 
`docker exec -it pg_banking_pro psql -U admin -d banking_db`

3. Последовательно выполняем SQL-запросы в разных окнах терминала.

