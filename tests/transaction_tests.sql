-- ТЕСТОВЫЙ СЦЕНАРИЙ ДЛЯ ПРОВЕРКИ ТРАНЗАКЦИЙ
-- Перед запуском убедитесь, что Seed Data загружена

DO $$
DECLARE
    v_sender_id UUID;
    v_receiver_id UUID;
    v_initial_balance_sender NUMERIC;
    v_initial_balance_receiver NUMERIC;
    v_final_balance_sender NUMERIC;
BEGIN
    -- 1. ПОДГОТОВКА: Берем реальные ID из базы
    SELECT id, balance INTO v_sender_id, v_initial_balance_sender 
    FROM accounts WHERE balance > 1000 LIMIT 1;
    
    SELECT id, balance INTO v_receiver_id, v_initial_balance_receiver 
    FROM accounts WHERE id != v_sender_id LIMIT 1;

    RAISE NOTICE '--- СТАРТ ТЕСТИРОВАНИЯ ---';
    RAISE NOTICE 'Отправитель: %, Баланс: %', v_sender_id, v_initial_balance_sender;

    -- =========================================================
    -- ТЕСТ №1: Успешный перевод (Happy Path)
    -- =========================================================
    BEGIN
        CALL make_transfer(v_sender_id, v_receiver_id, 100.00, 'Test: Success Transfer');
        RAISE NOTICE 'Тест 1 (Успех): ПРОЙДЕН';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Тест 1 (Успех): ОШИБКА - %', SQLERRM;
    END;

    -- =========================================================
    -- ТЕСТ №2: Недостаточно средств (Atomic Rollback)
    -- Ожидаем ошибку констрейнта positive_balance
    -- =========================================================
    BEGIN
        -- Пытаемся перевести миллион
        CALL make_transfer(v_sender_id, v_receiver_id, 1000000.00, 'Test: Overdraft');
        RAISE NOTICE 'Тест 2 (Овердрафт): ОШИБКА (Транзакция не заблокирована!)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Тест 2 (Овердрафт): ПРОЙДЕН (Ошибка перехвачена: %)', SQLERRM;
    END;

    -- =========================================================
    -- ТЕСТ №3: Несуществующий получатель
    -- Проверяем RAISE EXCEPTION в процедуре
    -- =========================================================
    BEGIN
        CALL make_transfer(v_sender_id, '00000000-0000-0000-0000-000000000000', 10.00);
        RAISE NOTICE 'Тест 3 (Битый ID): ОШИБКА (Транзакция не заблокирована!)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Тест 3 (Битый ID): ПРОЙДЕН (Ошибка перехвачена: %)', SQLERRM;
    END;

    -- ФИНАЛЬНАЯ ПРОВЕРКА
    SELECT balance INTO v_final_balance_sender FROM accounts WHERE id = v_sender_id;
    RAISE NOTICE '--- ТЕСТЫ ЗАВЕРШЕНЫ ---';
    RAISE NOTICE 'Итоговый баланс отправителя: % (Должен быть на 100 меньше начального)', v_final_balance_sender;

END $$;

-- Посмотреть записи в журнале (только от Теста №1)
SELECT * FROM transactions ORDER BY created_at DESC LIMIT 5;
