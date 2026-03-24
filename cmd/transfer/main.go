package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func main() {
	from := flag.String("from", "", "Email отправителя")
	to := flag.String("to", "", "Email получателя")
	amount := flag.Float64("amount", 0, "Сумма")
	flag.Parse()

	if *from == "" || *to == "" || *amount <= 0 {
		fmt.Println("Использование: go run cmd/transfer/main.go -from=ivan@bank.pro -to=alex@bank.pro -amount=100")
		return
	}

	ctx := context.Background()
	// Твои настройки Docker (порт 5433)
	connStr := "postgres://admin:password123@localhost:5433/banking_db"

	conn, err := pgx.Connect(ctx, connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close(ctx)

	err = runTransfer(ctx, conn, *from, *to, *amount)
	if err != nil {
		log.Fatalf("❌ Ошибка: %v", err)
	}

	fmt.Println("✅ Готово! Деньги переведены.")
}

func runTransfer(ctx context.Context, conn *pgx.Conn, from, to string, amount float64) error {
	for i := 0; i < 5; i++ {
		err := pgx.BeginFunc(ctx, conn, func(tx pgx.Tx) error {
			_, err := tx.Exec(ctx, "CALL make_transfer_v4($1, $2, 'RUB', $3)", from, to, amount)
			return err
		})

		if err != nil {
			if pgErr, ok := err.(*pgconn.PgError); ok {
				// Retry только если база занята (конфликт транзакций)
				if pgErr.Code == "40001" || pgErr.Code == "40P01" {
					log.Printf("Попытка %d: база занята, повторяю...", i+1)
					time.Sleep(100 * time.Millisecond)
					continue
				}
			}
			return err // Ошибки баланса или отсутствия счета прерывают выполнение
		}
		return nil
	}
	return fmt.Errorf("превышено число попыток")
}
