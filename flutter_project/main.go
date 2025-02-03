package main

import (
	"database/sql"
	"log"
	showproducts "newmos/newmos_api/Golistproduct"
	productProvider "newmos/newmos_api/golangProductProvider"
	
	login "newmos/newmos_api/golanglogin"
	products "newmos/newmos_api/golangnewproducts"
	register "newmos/newmos_api/golangregister"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

func Init() {
	r := gin.Default()

	r.POST("/register", register.Register)
	r.POST("/login", login.Login)
	r.GET("/products", products.GetProduct)
	r.POST("/products", products.Product)
	r.PUT("/products/update", products.UpdateProduct)
	r.GET("/ProductProvider/search", productProvider.SearchProducts)
	r.GET("/showproducts", showproducts.Showproducts)
	r.Static("/uploads", "./uploads")
	r.Run(":7070")
}
func main() {

	Init()

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
