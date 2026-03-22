CREATE OR REPLACE PROCEDURE make_transfer(
    p_sender_id UUID,
    p_receiver_id UUID,
    p_amount NUMERIC,
    p_description TEXT DEFAULT 'Internal transfer'
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Уменьшаем баланс отправителя
    -- Констрейнт 'positive_balance' сам выкинет ошибку, если денег мало
    UPDATE accounts 
    SET balance = balance - p_amount 
    WHERE id = p_sender_id AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Отправитель не найден или счет заморожен';
    END IF;

    -- 2. Увеличиваем баланс получателя
    UPDATE accounts 
    SET balance = balance + p_amount 
    WHERE id = p_receiver_id AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Получатель не найден или счет заморожен';
    END IF;

    -- 3. Фиксируем запись в истории (Ledger)
    INSERT INTO transactions (from_account_id, to_account_id, amount, description)
    VALUES (p_sender_id, p_receiver_id, p_amount, p_description);

    -- В процедурах COMMIT происходит автоматически в конце блока, 
    -- либо откатывается при EXCEPTION.
END;
$$;
