-- Добавляем уникальное ограничение, чтобы ON CONFLICT понимал, по какому полю проверять дубликаты
ALTER TABLE accounts 
ADD CONSTRAINT unique_customer_currency UNIQUE (customer_id, currency);

-- Добавляем индекс для ускорения поиска по email (частая операция в транзакциях)
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
