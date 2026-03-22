CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Вставляем запись в лог в формате JSON
    INSERT INTO audit_log (table_name, operation, row_id, old_data, new_data)
    VALUES (
        TG_TABLE_NAME,                 -- Имя таблицы (автоматически 'accounts')
        TG_OP,                         -- Тип операции (автоматически 'UPDATE')
        COALESCE(NEW.id, OLD.id),      -- ID записи
        to_jsonb(OLD),                 -- Конвертируем старую строку в JSON
        to_jsonb(NEW)                  -- Конвертируем новую строку в JSON
    );
    RETURN NEW; -- Пропускаем операцию дальше
END;
$$ LANGUAGE plpgsql;
