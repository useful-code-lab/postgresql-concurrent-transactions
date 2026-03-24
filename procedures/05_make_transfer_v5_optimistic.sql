CREATE OR REPLACE PROCEDURE make_transfer_v5_optimistic(
    p_from_email TEXT,
    p_to_email TEXT,
    p_currency CHAR(3),
    p_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id UUID; v_from_ver INT; v_from_bal NUMERIC;
    v_to_id UUID; v_to_ver INT;
    v_count INT;
BEGIN
    -- 1. Получаем ID, Баланс и ТЕКУЩУЮ ВЕРСИЮ (без блокировки)
    SELECT a.id, a.version, a.balance INTO v_from_id, v_from_ver, v_from_bal
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_from_email AND a.currency = p_currency;

    SELECT a.id, a.version INTO v_to_id, v_to_ver
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_to_email AND a.currency = p_currency;

    IF v_from_id IS NULL OR v_to_id IS NULL THEN
        RAISE EXCEPTION 'Account not found';
    END IF;

    IF v_from_bal < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- 2. Обновляем отправителя ТОЛЬКО если версия совпала
    UPDATE accounts 
    SET balance = balance - p_amount, version = version + 1 
    WHERE id = v_from_id AND version = v_from_ver;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        -- Кидаем стандартный код ошибки конфликта сериализации
        RAISE EXCEPTION 'Optimistic lock failed: version mismatch' USING ERRCODE = '40001';
    END IF;

    -- 3. Обновляем получателя ТОЛЬКО если версия совпала
    UPDATE accounts 
    SET balance = balance + p_amount, version = version + 1 
    WHERE id = v_to_id AND version = v_to_ver;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        RAISE EXCEPTION 'Optimistic lock failed: version mismatch' USING ERRCODE = '40001';
    END IF;

    -- 4. Лог
    INSERT INTO transactions (from_account_id, to_account_id, amount, description)
    VALUES (v_from_id, v_to_id, p_amount, 'V5: Optimistic Transfer');
END;
$$;
