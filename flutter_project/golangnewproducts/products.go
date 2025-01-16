package products

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

// func New(c *gin.Context) {
// 	getDBConnection()
// 	Product(c)
// 	UpdateProduct(c)

// }

// Database connection helper function
func getDBConnection() (*sql.DB, error) {
	// เพิ่ม Timeout การเชื่อมต่อที่ 30 วินาที
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

// API เพิ่มสินค้า
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

	// ดึงข้อมูลจาก form
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

	c.JSON(http.StatusOK, gin.H{"message": "เพิ่มสินค้าสำเร็จ"})
}

// Product represents the product structure
type Product1 struct {
	ProductNumber string `json:"product_number"`
	ProductName   string `json:"product_name"`
	Quantity      int    `json:"quantity"`
}

// var db *sql.DB


// UpdateProduct handles updating product quantity
func UpdateProduct(c *gin.Context) {
	var requestData struct {
		Barcode  string `json:"barcode"`
		Quantity int    `json:"quantity"`
	}

	// Parse request body
	if err := c.ShouldBindJSON(&requestData); err != nil {
		log.Printf("Invalid request body: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// ตรวจสอบว่าฟิลด์ barcode และ quantity ไม่ว่าง
	if requestData.Barcode == "" || requestData.Quantity < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid barcode or quantity"})
		return
	}

	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection error"})
		return
	}
	defer db.Close()

	// ตรวจสอบว่าสินค้ามีอยู่ในฐานข้อมูลหรือไม่
	var product Product1
	err = db.QueryRow("SELECT product_number, product_name, quantity FROM products WHERE barcode = ?", requestData.Barcode).
		Scan(&product.ProductNumber, &product.ProductName, &product.Quantity)

	if err == sql.ErrNoRows {
		log.Printf("Product not found for barcode: %s", requestData.Barcode)
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	} else if err != nil {
		log.Printf("Error fetching product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching product"})
		return
	}

	// อัปเดตจำนวนสินค้าในฐานข้อมูล
	_, err = db.Exec("UPDATE products SET quantity = ? WHERE barcode = ?", requestData.Quantity, requestData.Barcode)
	if err != nil {
		log.Printf("Error updating product quantity: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error updating product"})
		return
	}

	// อัปเดตโครงสร้างสินค้าเพื่อส่งกลับไปยังผู้เรียก
	product.Quantity = requestData.Quantity
	log.Printf("Product updated successfully: %+v", product)

	c.JSON(http.StatusOK, gin.H{
		"message": "Product updated successfully",
		"product": product,
	})
}

// GetProduct handles fetching product details by barcode
func GetProduct(c *gin.Context) {
	barcode := c.Query("barcode")

	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Barcode is required"})
		return
	}

	db, err := getDBConnection()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection error"})
		return
	}

	var product Product1
	err = db.QueryRow("SELECT product_number, product_name, quantity FROM products WHERE barcode = ?", barcode).
		Scan(&product.ProductNumber, &product.ProductName, &product.Quantity)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching product"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"product": product,
	})
}
