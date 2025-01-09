package products

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

// Database connection helper function
func getDBConnection() (*sql.DB, error) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		return nil, err
	}
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

// API ค้นหาสินค้าด้วย Barcode
func SearchProduct(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	barcode := c.Query("barcode")
	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "กรุณาระบุ Barcode"})
		return
	}

	sqlQuery := `
		SELECT product_number, product_name, category, quantity, stock_status 
		FROM products 
		WHERE barcode = ?`
	var product struct {
		ProductNumber string `json:"product_number"`
		ProductName   string `json:"product_name"`
		Category      string `json:"category"`
		Quantity      int    `json:"quantity"`
		StockStatus   string `json:"stock_status"`
	}

	err = db.QueryRow(sqlQuery, barcode).Scan(
		&product.ProductNumber,
		&product.ProductName,
		&product.Category,
		&product.Quantity,
		&product.StockStatus,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"message": "ไม่พบสินค้า"})
		return
	} else if err != nil {
		log.Printf("Error retrieving product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลสินค้าได้"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"product": product})
}

// API อัปเดต Quantity
func UpdateQuantity(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	var request struct {
		Barcode  string `json:"barcode" binding:"required"`
		Quantity int    `json:"quantity" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ครบถ้วน"})
		return
	}

	// อัปเดตจำนวนสินค้า
	query := `UPDATE products SET quantity = ? WHERE barcode = ?`
	result, err := db.Exec(query, request.Quantity, request.Barcode)
	if err != nil {
		log.Printf("Error updating quantity: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถอัปเดตข้อมูลได้"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบสินค้า"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "อัปเดตข้อมูลสำเร็จ"})
}

// API ดึงรายการสินค้าทั้งหมด
func GetProducts(c *gin.Context) {
	db, err := getDBConnection()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเชื่อมต่อฐานข้อมูลได้"})
		return
	}
	defer db.Close()

	rows, err := db.Query("SELECT product_number, product_name, category, quantity, barcode, stock_status FROM products")
	if err != nil {
		log.Printf("Error querying products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลสินค้าได้"})
		return
	}
	defer rows.Close()

	var products []map[string]interface{}
	for rows.Next() {
		var product struct {
			ProductNumber string `json:"product_number"`
			ProductName   string `json:"product_name"`
			Category      string `json:"category"`
			Quantity      int    `json:"quantity"`
			Barcode       string `json:"barcode"`
			StockStatus   string `json:"stock_status"`
		}
		if err := rows.Scan(
			&product.ProductNumber,
			&product.ProductName,
			&product.Category,
			&product.Quantity,
			&product.Barcode,
			&product.StockStatus,
		); err != nil {
			log.Printf("Error scanning product: %v", err)
			continue
		}
		products = append(products, map[string]interface{}{
			"product_number": product.ProductNumber,
			"product_name":   product.ProductName,
			"category":       product.Category,
			"quantity":       product.Quantity,
			"barcode":        product.Barcode,
			"stock_status":   product.StockStatus,
		})
	}

	c.JSON(http.StatusOK, gin.H{"products": products})
}
