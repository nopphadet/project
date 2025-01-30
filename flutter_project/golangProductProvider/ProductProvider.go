package productProvider

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

func getDBConnection() (*sql.DB, error) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp?timeout=30s")
	if err != nil {
		return nil, err
	}

	// ปรับการตั้งค่า connection pool
	db.SetMaxOpenConns(10)                  // กำหนดจำนวนการเชื่อมต่อสูงสุด
	db.SetMaxIdleConns(5)                   // กำหนดจำนวนการเชื่อมต่อที่ไม่ได้ใช้งาน
	db.SetConnMaxLifetime(30 * time.Minute) // กำหนดเวลาชีวิตสูงสุดของการเชื่อมต่อ

	// ตรวจสอบการเชื่อมต่อ
	if err := db.Ping(); err != nil {
		return nil, err
	}
	return db, nil
}

// Function to get available categories from the database
func GetCategories(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	// Query to get distinct categories
	rows, err := db.Query("SELECT DISTINCT category FROM products")
	if err != nil {
		log.Printf("Error fetching categories: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลประเภทสินค้าได้"})
		return
	}
	defer rows.Close()

	var categories []string
	for rows.Next() {
		var category string
		if err := rows.Scan(&category); err != nil {
			log.Printf("Error scanning category: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลประเภทสินค้าได้"})
			return
		}
		categories = append(categories, category)
	}

	c.JSON(http.StatusOK, gin.H{"categories": categories})
}

// Search products by product name or category
func SearchProducts(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	productName := c.DefaultQuery("product_name", "")
	category := c.DefaultQuery("category", "")

	// Building the query
	query := "SELECT product_number, product_name, category, quantity, barcode FROM products WHERE 1=1"
	if productName != "" {
		query += " AND product_name LIKE ?"
	}
	if category != "" && category != "ทั้งหมด" {
		query += " AND category = ?"
	}

	// Executing the query
	rows, err := db.Query(query, "%"+productName+"%", category)
	if err != nil {
		log.Printf("Error fetching products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถค้นหาสินค้าได้"})
		return
	}
	defer rows.Close()

	var products []map[string]interface{}
	for rows.Next() {
		var productNumber, productName, category, barcode string
		var quantity int
		if err := rows.Scan(&productNumber, &productName, &category, &quantity, &barcode); err != nil {
			log.Printf("Error scanning product: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลสินค้าได้"})
			return
		}

		products = append(products, map[string]interface{}{
			"product_number": productNumber,
			"product_name":   productName,
			"category":       category,
			"quantity":       quantity,
			"barcode":        barcode,
		})
	}

	c.JSON(http.StatusOK, gin.H{"products": products})
}

func Product(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	type Product struct {
		ProductNumber string `json:"product_number" binding:"required"`
		ProductName   string `json:"product_name" binding:"required"`
		Category      string `json:"category" binding:"required"`
		Quantity      int    `json:"quantity" binding:"required"`
		Barcode       string `json:"barcode" binding:"required"`
		StockStatus   string `json:"stock_status" binding:"required"`
	}

	quantityStr := c.DefaultPostForm("quantity", "0")
	quantity, err := strconv.Atoi(quantityStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "จำนวนไม่ถูกต้อง"})
		return
	}

	product := Product{
		ProductNumber: c.DefaultPostForm("product_number", ""),
		ProductName:   c.DefaultPostForm("product_name", ""),
		Category:      c.DefaultPostForm("category", ""),
		Quantity:      quantity,
		Barcode:       c.DefaultPostForm("barcode", ""),
		StockStatus:   c.DefaultPostForm("stock_status", ""),
	}

	// ตรวจสอบฟิลด์บังคับ
	if product.ProductNumber == "" || product.ProductName == "" || product.Category == "" ||
		product.Barcode == "" || product.StockStatus == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "กรุณากรอกข้อมูลให้ครบถ้วน"})
		return
	}

	// รับไฟล์รูปภาพ
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "กรุณาอัปโหลดไฟล์รูปภาพ"})
		return
	}
	imagePath := "./uploads/" + file.Filename
	if err := c.SaveUploadedFile(file, imagePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกรูปภาพได้"})
		return
	}

	// SQL สำหรับบันทึกข้อมูลสินค้า
	query := `
		INSERT INTO products (product_number, product_name, category, quantity, barcode, stock_status, image_path, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`

	_, err = db.Exec(query, product.ProductNumber, product.ProductName, product.Category, product.Quantity, product.Barcode, product.StockStatus, imagePath)
	if err != nil {
		log.Printf("Error inserting product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเพิ่มสินค้าได้"})
		return
	}

	// เก็บประวัติการเพิ่มสินค้า
	changeQuery := `
		INSERT INTO product_changes (product_id, change_type, new_quantity, changed_by)
		VALUES (LAST_INSERT_ID(), 'ADD', ?, ?)`
	_, err = db.Exec(changeQuery, product.Quantity, "admin")
	if err != nil {
		log.Printf("Error logging product change: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกการเปลี่ยนแปลง"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "เพิ่มสินค้าสำเร็จ"})
}
