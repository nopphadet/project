package main

import (
	"database/sql"
	"log"
	showproducts "newmos/newmos_api/Golistproduct"
	login "newmos/newmos_api/golanglogin"
	products "newmos/newmos_api/golangnewproducts"
	register "newmos/newmos_api/golangregister"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

func Init() {
	r := gin.Default()

	// Register routes
	r.POST("/register", register.Register)
	r.POST("/login", login.Login)

	// Product routes
	r.GET("/products", products.GetProduct)                             // Get list of products
	r.POST("/products", products.Product)                               // Add a new product
	r.PUT("/products/update", products.UpdateProduct)                   // Update product details
	r.GET("/ProductProvider/categories", productProvider.GetCategories) // Fetch available product categories
	r.GET("/ProductProvider/search", productProvider.SearchProducts)    // Search products by name and category

	// Product change history route
	r.GET("/product-changes", products.GetProductChangeHistory)

	// Show products route
	r.GET("/showproducts", showproducts.Showproducts)

	// Serve static files (uploaded images, etc.)
	r.Static("/uploads", "./uploads")

	// Start the server on port 7070
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
