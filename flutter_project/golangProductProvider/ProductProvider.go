package productProvider

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

// getDBConnection - ฟังก์ชันสำหรับเชื่อมต่อฐานข้อมูล
func getDBConnection() (*sql.DB, error) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp?timeout=30s")
	if err != nil {
		return nil, err
	}

	// ตั้งค่า Connection Pool
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

// SearchProducts - API สำหรับค้นหาสินค้า
func SearchProducts(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	productName := c.DefaultQuery("name", "")
	category := c.DefaultQuery("category", "")

	query := `
		SELECT product_number, product_name, category, quantity, barcode, stock_status, image_path, created_at
		FROM products WHERE 1=1`
	var args []interface{}

	if productName != "" {
		query += " AND product_name COLLATE utf8mb4_general_ci LIKE ?"
		args = append(args, "%"+productName+"%")
	}

	if category != "" && category != "ทั้งหมด" {
		query += " AND category = ?"
		args = append(args, category)
	}

	// query += " ORDER BY created_at DESC" // ✅ ดึงสินค้าล่าสุดก่อน

	log.Printf("Executing query: %s, args: %v", query, args)
	rows, err := db.Query(query, args...)
	if err != nil {
		log.Printf("Error fetching products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถค้นหาสินค้าได้"})
		return
	}
	defer rows.Close()

	products := []Product{}

	for rows.Next() {
		var product Product
		err := rows.Scan(&product.ProductNumber, &product.ProductName, &product.Category, &product.Quantity, &product.Barcode, &product.StockStatus, &product.ImagePath, &product.CreatedAt)
		if err != nil {
			log.Printf("Error scanning product: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการอ่านข้อมูล"})
			return
		}

		// ✅ ปรับ Image URL ให้ตรงกับระบบของ showproducts
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
