-- Привязываем функцию к таблице accounts
CREATE TRIGGER trg_audit_accounts
AFTER UPDATE OR INSERT OR DELETE ON accounts
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
