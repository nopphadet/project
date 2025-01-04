package main

import (
	"database/sql"
	"log"

	// "net/http"

	register "newmos/newmos_api/golangregister"

	// "regexp"

	// "strconv" // Import strconv for converting string to int

	"github.com/gin-gonic/gin"
	// "golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	//products.Product()
	register.Inint()
	// register.Register()

	// เชื่อมต่อกับฐานข้อมูล MySQL
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	// ทดสอบการเชื่อมต่อ
	if err := db.Ping(); err != nil {
		log.Fatalf("การเชื่อมต่อฐานข้อมูลล้มเหลว: %v", err)
	}

	// สร้าง Router สำหรับ Gin
	r := gin.Default()

	// API สมัครสมาชิก

	// รันเซิร์ฟเวอร์ที่พอร์ต 7070
	r.Run(":7070")
}
