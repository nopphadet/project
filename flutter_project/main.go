package main

import (
	"database/sql"
	"log"
	products "newmos/newmos_api/golangnewproducts"

	// "net/http"
	login "newmos/newmos_api/golanglogin"
	register "newmos/newmos_api/golangregister"

	// update "newmos/newmos_api/golangupdateProduct"

	// "regexp"

	// "strconv" // Import strconv for converting string to int

	"github.com/gin-gonic/gin"
	// "golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

func Init() {
	r := gin.Default()
	r.POST("/register", register.Register)
	r.POST("/login", login.Login)
	r.GET("/products", products.GetProduct)
	r.POST("/products", products.Product)
	r.PUT("/products/update", products.UpdateProduct)
	r.Run(":7070")
}

func main() {

	Init()

	// เชื่อมต่อกับฐานข้อมูล MySQL
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("การเชื่อมต่อฐานข้อมูลล้มเหลว: %v", err)
	}

	r := gin.Default()

	r.Run(":7070")
}
