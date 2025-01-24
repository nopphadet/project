package showproducts

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

// getDBConnection - ฟังก์ชันสำหรับเชื่อมต่อกับฐานข้อมูล
func getDBConnection() (*sql.DB, error) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp?timeout=30s")
	if err != nil {
		return nil, err
	}

	// การตั้งค่า connection pool
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)

	// ตรวจสอบการเชื่อมต่อ
	if err := db.Ping(); err != nil {
		return nil, err
	}
	return db, nil
}

// Product - โครงสร้างข้อมูลสินค้า
type Product struct {
	ProductNumber string `json:"product_number"`
	ProductName   string `json:"product_name"`
	Category      string `json:"category"`
	Quantity      int    `json:"quantity"`
	Barcode       string `json:"barcode"`
	StockStatus   string `json:"stock_status"`
	ImagePath     string `json:"image_path"`
	ImageUrl      string `json:"image_url"`
	CreatedAt     string `json:"created_at"`
}

// listproducts - ฟังก์ชันสำหรับดึงข้อมูลสินค้าทั้งหมด
func Showproducts(c *gin.Context) {

	db, err := getDBConnection()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	rows, err := db.Query(`
		SELECT product_number, product_name, category, quantity, barcode, stock_status, image_path, created_at 
		FROM products
		ORDER BY created_at DESC`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลได้"})
		return
	}
	defer rows.Close()

	products := []Product{}

	for rows.Next() {
		var product Product
		err := rows.Scan(&product.ProductNumber, &product.ProductName, &product.Category, &product.Quantity, &product.Barcode, &product.StockStatus, &product.ImagePath, &product.CreatedAt)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการอ่านข้อมูล"})
			return
		}

		product.ImageUrl = "https://hfm99nd8-7070.asse.devtunnels.ms/" + product.ImagePath
		log.Println("Constructed Image URL:", product.ImageUrl)
		products = append(products, product)
	}

	if len(products) == 0 {
		c.JSON(http.StatusOK, gin.H{"message": "ไม่มีสินค้าในระบบ"})
		return
	}

	c.JSON(http.StatusOK, products)
}
