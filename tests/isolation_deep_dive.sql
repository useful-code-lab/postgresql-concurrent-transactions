/* 
   СЦЕНАРИЙ 1: READ COMMITTED (Проблема "Исчезающих денег" в отчете)
   Суть: Внутри одной транзакции сумма балансов не сойдется, если идет перевод.
*/

-- ТЕРМИНАЛ 1 (Аудитор)
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT SUM(balance) FROM accounts; -- Запомните сумму (например, 200 000)

-- ТЕРМИНАЛ 2 (Перевод)
CALL make_transfer_v3('alex@bank.pro', 'ivan@bank.pro', 'RUB', 50000);

-- ТЕРМИНАЛ 1 (Аудитор делает повторный запрос)
SELECT SUM(balance) FROM accounts; -- Сумма может измениться или "поплыть" (Read Skew)
COMMIT;


/* 
   СЦЕНАРИЙ 2: REPEATABLE READ (Целостный отчет / Snapshot)
   Суть: Транзакция видит мир "замороженным" на момент своего старта.
*/

-- ТЕРМИНАЛ 1 (Аудитор)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT SUM(balance) FROM accounts; -- Запомните сумму

-- ТЕРМИНАЛ 2 (Перевод)
CALL make_transfer_v3('ivan@bank.pro', 'alex@bank.pro', 'RUB', 10000);

-- ТЕРМИНАЛ 1 (Аудитор делает повторный запрос)
SELECT SUM(balance) FROM accounts; 
-- Результат БУДЕТ ТАКИМ ЖЕ, как в первый раз. Снимок данных неизменен.
COMMIT;
