/* 
   ТЕСТ 1: Read Committed (Поведение по умолчанию)
   Как проверить: откройте два окна psql
*/

-- ОКНО 1
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Результат: 100 000

-- ОКНО 2 (имитация другого платежа)
UPDATE accounts SET balance = balance - 500 WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
COMMIT;

-- ОКНО 1 (повторный запрос в той же транзакции)
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Результат: 99 500 (Non-repeatable read - данные изменились!)
COMMIT;

/* 
   ТЕСТ 2: Repeatable Read (Строгая изоляция снимка)
*/

-- ОКНО 1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Результат: 99 500

-- ОКНО 2
UPDATE accounts SET balance = balance - 500 WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
COMMIT;

-- ОКНО 1
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Результат: 99 500 (Данные НЕ изменились, транзакция видит старый "снимок")
COMMIT;
