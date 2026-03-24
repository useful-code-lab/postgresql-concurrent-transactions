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
		log.Fatal("Укажите -from, -to и -amount")
	}

	ctx := context.Background()
	connStr := "postgres://admin:password123@localhost:5433/banking_db"
	conn, err := pgx.Connect(ctx, connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close(ctx)

	err = runOptimisticTransfer(ctx, conn, *from, *to, *amount)
	if err != nil {
		log.Fatalf("\n❌ Ошибка после всех попыток: %v", err)
	}
	fmt.Println("\n✅ Успех! Оптимистичная блокировка сработала.")
}

func runOptimisticTransfer(ctx context.Context, conn *pgx.Conn, from, to string, amount float64) error {
	for i := 0; i < 10; i++ { // Увеличим до 10 попыток для наглядности
		err := pgx.BeginFunc(ctx, conn, func(tx pgx.Tx) error {
			_, err := tx.Exec(ctx, "CALL make_transfer_v5_optimistic($1, $2, 'RUB', $3)", from, to, amount)
			return err
		})

		if err != nil {
			if pgErr, ok := err.(*pgconn.PgError); ok && pgErr.Code == "40001" {
				fmt.Printf("⚠️ Попытка %d: Конфликт версий. Ждем и повторяем...\n", i+1)
				time.Sleep(100 * time.Millisecond)
				continue
			}
			return err
		}
		return nil
	}
	return fmt.Errorf("превышено количество попыток ретрая")
}
