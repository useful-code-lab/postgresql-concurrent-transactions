-- 1. Полностью удаляем старую таблицу (вместе с данными!)
DROP TABLE IF EXISTS transactions CASCADE;

-- 2. Создаем таблицу ПРАВИЛЬНО (с PARTITION BY RANGE)
CREATE TABLE transactions (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    from_account_id UUID REFERENCES accounts(id),
    to_account_id UUID REFERENCES accounts(id),
    amount NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
    description TEXT,
    -- Поле, по которому будем делить таблицу
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- ВАЖНО: поле партиционирования ОБЯЗАНО входить в Primary Key
    PRIMARY KEY (id, created_at) 
) PARTITION BY RANGE (created_at);

-- 3. Теперь создаем партиции (на текущий 2026 год, судя по твоим логам)
CREATE TABLE transactions_2026_03 PARTITION OF transactions
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE transactions_2026_04 PARTITION OF transactions
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

-- 4. Создаем партицию "по умолчанию" (чтобы INSERT не падал, если дата вне диапазона)
CREATE TABLE transactions_default PARTITION OF transactions DEFAULT;
