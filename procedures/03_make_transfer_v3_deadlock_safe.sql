CREATE OR REPLACE PROCEDURE make_transfer_v3(
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
    v_first_lock UUID;
    v_second_lock UUID;
BEGIN
    -- 1. Получаем ID счетов (пока без блокировки)
    SELECT a.id INTO v_from_id 
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_from_email AND a.currency = p_currency;

    SELECT a.id INTO v_to_id 
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_to_email AND a.currency = p_currency;

    IF v_from_id IS NULL OR v_to_id IS NULL THEN
        RAISE EXCEPTION 'Один из счетов не найден';
    END IF;

    -- 2. СОРТИРОВКА: определяем, кто "меньше" по UUID
    -- Неважно, кто отправитель, важно, чей ID в базе идет первым
    IF v_from_id < v_to_id THEN
        v_first_lock := v_from_id;
        v_second_lock := v_to_id;
    ELSE
        v_first_lock := v_to_id;
        v_second_lock := v_from_id;
    END IF;

    -- 3. БЛОКИРОВКА строго в одном порядке (Меньший -> Больший)
    -- Теперь встречные транзакции не "столкнутся", а встанут в очередь
    PERFORM balance FROM accounts WHERE id = v_first_lock FOR UPDATE;
    PERFORM balance FROM accounts WHERE id = v_second_lock FOR UPDATE;

    -- 4. ПРОВЕРКА баланса (уже внутри безопасной зоны)
    IF (SELECT balance FROM accounts WHERE id = v_from_id) < p_amount THEN
        RAISE EXCEPTION 'Недостаточно средств на счете %', p_from_email;
    END IF;

    -- 5. ПРОВОДКА
    UPDATE accounts SET balance = balance - p_amount WHERE id = v_from_id;
    UPDATE accounts SET balance = balance + p_amount WHERE id = v_to_id;

    -- 6. ЛОГИРОВАНИЕ
    INSERT INTO transactions (from_account_id, to_account_id, amount, description)
    VALUES (v_from_id, v_to_id, p_amount, 'V3: Deadlock Safe Transfer');

    -- В процедуре COMMIT происходит автоматически или явно:
    COMMIT;
END;
$$;
