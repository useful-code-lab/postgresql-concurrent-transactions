CREATE OR REPLACE PROCEDURE make_transfer_v4(
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
    -- 1. Находим ID
    SELECT a.id INTO v_from_id 
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_from_email AND a.currency = p_currency;

    SELECT a.id INTO v_to_id 
    FROM accounts a JOIN customers c ON a.customer_id = c.id
    WHERE c.email = p_to_email AND a.currency = p_currency;

    IF v_from_id IS NULL OR v_to_id IS NULL THEN
        RAISE EXCEPTION 'Счет не найден для % или %', p_from_email, p_to_email;
    END IF;

    -- 2. Сортировка UUID для защиты от Deadlock
    IF v_from_id < v_to_id THEN
        v_first_lock := v_from_id; v_second_lock := v_to_id;
    ELSE
        v_first_lock := v_to_id; v_second_lock := v_from_id;
    END IF;

    -- 3. Блокировка в строгом порядке
    PERFORM id FROM accounts WHERE id = v_first_lock FOR UPDATE;
    PERFORM id FROM accounts WHERE id = v_second_lock FOR UPDATE;

    -- 4. Проверка баланса
    IF (SELECT balance FROM accounts WHERE id = v_from_id) < p_amount THEN
        RAISE EXCEPTION 'Недостаточно средств на счете %', p_from_email;
    END IF;

    -- 5. Сами обновления
    UPDATE accounts SET balance = balance - p_amount WHERE id = v_from_id;
    UPDATE accounts SET balance = balance + p_amount WHERE id = v_to_id;

    -- 6. Логирование
    INSERT INTO transactions (from_account_id, to_account_id, amount, description)
    VALUES (v_from_id, v_to_id, p_amount, 'Transfer v4: Success');

END;
$$;
