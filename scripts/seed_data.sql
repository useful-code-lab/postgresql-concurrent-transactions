-- 1. Включаем расширение для UUID (на всякий случай)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Наполнение валют (с проверкой на существование)
INSERT INTO currencies (code, name)
VALUES ('RUB', 'Russian Ruble'), ('USD', 'US Dollar')
ON CONFLICT (code) DO NOTHING;

-- 3. Наполнение клиентов с проверкой по email
-- Используем временную таблицу для удобства сопоставления со счетами
DO $$
DECLARE
    cust_1_id UUID;
    cust_2_id UUID;
BEGIN
    -- Добавляем первого клиента
    INSERT INTO customers (full_name, email)
    VALUES ('Алексей', 'alex@bank.pro')
    ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
    RETURNING id INTO cust_1_id;

    -- Добавляем второго клиента
    INSERT INTO customers (full_name, email)
    VALUES ('Иван', 'ivan@bank.pro')
    ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
    RETURNING id INTO cust_2_id;

    -- 4. Создаем счета, если их еще нет у этих клиентов
    INSERT INTO accounts (customer_id, currency, balance, status)
    VALUES (cust_1_id, 'RUB', 100000.00, 'active')
    ON CONFLICT DO NOTHING;

    INSERT INTO accounts (customer_id, currency, balance, status)
    VALUES (cust_2_id, 'RUB', 5000.00, 'active')
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Seed data applied successfully';
END $$;

-- 5. Финальная проверка (просто выводит результат в консоль)
SELECT c.full_name, a.balance, a.currency, a.id as account_id
FROM accounts a
JOIN customers c ON a.customer_id = c.id;
