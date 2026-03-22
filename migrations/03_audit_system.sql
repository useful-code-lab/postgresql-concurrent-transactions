-- Создаем таблицу для логов
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,         -- Какая таблица изменилась
    operation TEXT NOT NULL,          -- INSERT, UPDATE или DELETE
    row_id UUID,                      -- ID конкретной записи (счета)
    old_data JSONB,                   -- Состояние строки ДО
    new_data JSONB,                   -- Состояние строки ПОСЛЕ
    changed_by TEXT DEFAULT CURRENT_USER,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
