-- Обнуляем и задаем чистые стартовые данные для тестов изоляции
BEGIN;

-- Устанавливаем баланс Алексея в 100 000
UPDATE accounts 
SET balance = 100000.00 
WHERE customer_id = (SELECT id FROM customers WHERE email = 'alex@bank.pro');

-- Устанавливаем баланс Ивана в 100 000
UPDATE accounts 
SET balance = 100000.00 
WHERE customer_id = (SELECT id FROM customers WHERE email = 'ivan@bank.pro');

COMMIT;

-- Проверка перед тестом
SELECT c.full_name, a.balance, a.currency 
FROM accounts a 
JOIN customers c ON a.customer_id = c.id;
