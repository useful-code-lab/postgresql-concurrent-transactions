-- 1. Справочник валют (для строгости)
CREATE TABLE currencies (
    code CHAR(3) PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO currencies (code, name) VALUES ('RUB', 'Russian Ruble'), ('USD', 'US Dollar');

-- 2. Клиенты
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Счета с защитой от отрицательного баланса
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    currency CHAR(3) REFERENCES currencies(code),
    balance NUMERIC(19, 4) NOT NULL DEFAULT 0.0000,
    status TEXT CHECK (status IN ('active', 'frozen', 'closed')) DEFAULT 'active',
    CONSTRAINT positive_balance CHECK (balance >= 0) 
);

-- 4. История транзакций (Ledger)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_account_id UUID REFERENCES accounts(id),
    to_account_id UUID REFERENCES accounts(id),
    amount NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
