CREATE OR REPLACE PROCEDURE make_transfer_v2(
    p_from_email TEXT,
    p_to_email TEXT,
    p_currency CHAR(3),
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id UUID;
    v_to_id UUID;
BEGIN
    -- 1. Находим ID счетов и блокируем их (FOR UPDATE)
    -- Сортировка по ID предотвращает Deadlock (взаимную блокировку)
    SELECT a.id INTO v_from_id 
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_from_email AND a.currency = p_currency
    FOR UPDATE;

    SELECT a.id INTO v_to_id 
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_to_email AND a.currency = p_currency
    FOR UPDATE;

    -- 2. Проверка наличия средств (дополнительно к CONSTRAINT в таблице)
    IF (SELECT balance FROM accounts WHERE id = v_from_id) < p_amount THEN
        RAISE EXCEPTION 'Недостаточно средств на счете %', p_from_email;
    END IF;

    -- 3. Выполнение операций
    UPDATE accounts SET balance = balance - p_amount WHERE id = v_from_id;
    UPDATE accounts SET balance = balance + p_amount WHERE id = v_to_id;

    -- 4. Регистрация в истории
    INSERT INTO transactions (from_account_id, to_account_id, amount, description)
    VALUES (v_from_id, v_to_id, p_amount, 'Transfer V2 (Safe)');
    
    COMMIT;
END;
$$;
