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

func New(c *gin.Context) {
	getDBConnection()
	Product(c)
	
}

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

