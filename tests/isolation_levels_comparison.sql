-- ============================================================================
-- СРАВНЕНИЕ УРОВНЕЙ ИЗОЛЯЦИИ: READ COMMITTED vs REPEATABLE READ vs SERIALIZABLE
-- ============================================================================

/*
  СЦЕНАРИЙ 1: READ COMMITTED (Поведение по умолчанию)
  Проблема: "Непостоянство данных" (Non-repeatable Read). 
  В одной транзакции один и тот же запрос выдает разные результаты.
*/

-- ТЕРМИНАЛ 1 (Аудитор):
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro'); 
-- Видим, например, 50 000

-- ТЕРМИНАЛ 2 (Внешнее изменение):
UPDATE accounts SET balance = balance + 1000 WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
COMMIT;

-- ТЕРМИНАЛ 1 (Аудитор повторяет запрос):
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Результат ИЗМЕНИЛСЯ (стало 51 000). Транзакция видит чужие коммиты сразу.
COMMIT;


/*
  СЦЕНАРИЙ 2: REPEATABLE READ (Снимок данных)
  Решение: "Заморозка мира". Транзакция видит данные такими, какими они были на старте.
*/

-- ТЕРМИНАЛ 1 (Бухгалтер):
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro'); 
-- Видим 51 000

-- ТЕРМИНАЛ 2 (Внешнее изменение):
UPDATE accounts SET balance = balance + 5000 WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
COMMIT;

-- ТЕРМИНАЛ 1 (Бухгалтер повторяет запрос):
SELECT balance FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Результат НЕ ИЗМЕНИЛСЯ (всё еще 51 000). База гарантирует стабильность отчета.
COMMIT;


/*
  СЦЕНАРИЙ 3: SERIALIZABLE (Высшая защита)
  Задача: Соблюсти бизнес-правило "Сумма всех счетов клиента не > 200 000".
  Обычный Repeatable Read здесь бы провалился (оба бы добавили денег, не зная друг о друге).
*/

-- ТЕРМИНАЛ 1 (Оператор А):
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT SUM(balance) FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- Видит 56 000. Решает добавить 100 000.
UPDATE accounts SET balance = balance + 100000 WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');

-- ТЕРМИНАЛ 2 (Оператор Б):
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT SUM(balance) FROM accounts WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');
-- ТОЖЕ видит 56 000 (Т1 еще не закоммитил). Решает добавить 80 000 (думает, что 56+80 < 200).
UPDATE accounts SET balance = balance + 80000 WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');

-- ТЕРМИНАЛ 1:
COMMIT; -- Успешно! (Баланс стал 156 000)

-- ТЕРМИНАЛ 2:
COMMIT; 
-- ОШИБКА: ERROR: could not serialize access due to read/write dependencies among transactions
-- База поняла, что если бы они шли по очереди, второй бы увидел > 156к и не сделал бы UPDATE.
