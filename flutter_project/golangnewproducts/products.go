package products

import (
	// "database/sql"
	"database/sql"
	"log"
	"net/http"
	"strconv"

	// "strconv"

	// "strconv" // Import strconv for converting string to int

	"github.com/gin-gonic/gin"
	// "golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

// API เพิ่มสินค้า
func Product() {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	// ทดสอบการเชื่อมต่อ
	if err := db.Ping(); err != nil {
		log.Fatalf("การเชื่อมต่อฐานข้อมูลล้มเหลว: %v", err)
	}

	r := gin.Default()
	r.POST("/products", func(c *gin.Context) {
		type Product struct {
			ProductNumber string `json:"product_number" binding:"required"`
			ProductName   string `json:"product_name" binding:"required"`
			Category      string `json:"category" binding:"required"`
			Quantity      int    `json:"quantity" binding:"required"`
			Barcode       string `json:"barcode" binding:"required"`
			StockStatus   string `json:"stock_status" binding:"required"`
		}

		// ดึงข้อมูลจาก form
		quantityStr := c.DefaultPostForm("quantity", "0") // Get the quantity as a string
		quantity, err := strconv.Atoi(quantityStr)        // Convert the string to an integer
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid quantity"})
			return
		}

		product := Product{
			ProductNumber: c.DefaultPostForm("product_number", ""),
			ProductName:   c.DefaultPostForm("product_name", ""),
			Category:      c.DefaultPostForm("category", ""),
			Quantity:      quantity, // Set the quantity field after conversion
			Barcode:       c.DefaultPostForm("barcode", ""),
			StockStatus:   c.DefaultPostForm("stock_status", ""),
		}

		// รับไฟล์รูปภาพ
		file, _ := c.FormFile("image")
		imagePath := "./uploads/" + file.Filename
		if err := c.SaveUploadedFile(file, imagePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกรูปภาพได้"})
			return
		}

		// SQL สำหรับบันทึกข้อมูลสินค้า
		query := `INSERT INTO products (product_number, product_name, category, quantity, barcode, stock_status, image_path, created_at) 
			  VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`

		// Log the query and parameters
		log.Printf("Executing query: %s\nWith parameters: %v\n", query, []interface{}{
			product.ProductNumber, product.ProductName, product.Category, product.Quantity,
			product.Barcode, product.StockStatus, imagePath,
		})
		_, err = db.Exec(query, product.ProductNumber, product.ProductName, product.Category, product.Quantity, product.Barcode, product.StockStatus, imagePath)
		if err != nil {
			log.Println("Error inserting product:", err) // Log the error
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเพิ่มสินค้าได้"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "เพิ่มสินค้าสำเร็จ"})
	})
}
