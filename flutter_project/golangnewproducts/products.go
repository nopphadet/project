package products // สำหรับการจัดการสินค้า

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"

	// "time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

// func New(c *gin.Context) {
// 	getDBConnection()
// 	Product(c)
// 	UpdateProduct(c)

// }

type ProductController struct {
	dbClient *sql.DB
}

func NewProduct(dbClient *sql.DB) *ProductController {
	return &ProductController{
		dbClient: dbClient,
	}
}

// ProductDeleteRequest สร้าง struct เพื่อรับข้อมูลจาก JSON body
type ProductDeleteRequest struct {
	ProductID int `json:"id" binding:"required"` // รับค่า product_id จาก JSON body
}

func NewProductController(db *sql.DB) *ProductController {
	return &ProductController{dbClient: db}
}

func (p *ProductController) DeleteProduct(c *gin.Context) {
	// รับข้อมูลจาก JSON body และ bind กับ struct ProductDeleteRequest
	var request ProductDeleteRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "ข้อมูลไม่ถูกต้อง: " + err.Error(),
		})
		return
	}

	// Debug: พิมพ์ค่า ProductID เพื่อตรวจสอบ
	println("Received ProductID:", request.ProductID)

	// ลบข้อมูลจากฐานข้อมูล โดยใช้ product_id
	result, err := p.dbClient.Exec("DELETE FROM products WHERE product_id = ?", request.ProductID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "ไม่สามารถลบข้อมูลได้: " + err.Error(),
		})
		return
	}

	// ตรวจสอบว่ามีแถวที่ถูกลบหรือไม่
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "ไม่สามารถตรวจสอบการลบได้: " + err.Error(),
		})
		return
	}

	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "ไม่พบสินค้าที่ระบุ ID",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "ลบสินค้าสำเร็จ",
	})
}

// API เพิ่มสินค้า
func (p *ProductController) Product(c *gin.Context) {
	type Product struct {
		ProductNumber int    `json:"product_id" binding:"required"`
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

	product_id := 0
	product := Product{
		ProductNumber: product_id,
		ProductName:   c.DefaultPostForm("product_name", ""),
		Category:      c.DefaultPostForm("category", ""),
		Quantity:      quantity,
		Barcode:       c.DefaultPostForm("barcode", ""),
		StockStatus:   c.DefaultPostForm("stock_status", ""),
	}

	// ตรวจสอบฟิลด์บังคับ
	if product.ProductName == "" || product.Category == "" ||
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

	// เพิ่มข้อมูลสินค้าลงในฐานข้อมูล
	query := `
		INSERT INTO products (product_id, product_name, category, quantity, barcode, stock_status, image_path, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`

	_, err = p.dbClient.Exec(query, product.ProductNumber, product.ProductName, product.Category, product.Quantity, product.Barcode, product.StockStatus, imagePath)
	if err != nil {
		log.Printf("Error inserting product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเพิ่มสินค้าได้"})
		return
	}

	// เก็บประวัติการเพิ่มสินค้า
	changeQuery := `
    INSERT INTO product_changes (product_id, change_type, new_quantity, changed_by)
    VALUES (LAST_INSERT_ID(), 'ADD', ?, ?)`

	_, err = p.dbClient.Exec(changeQuery, product.Quantity, "admin") // เปลี่ยน "admin" เป็นชื่อผู้ที่ทำการเพิ่ม
	if err != nil {
		log.Printf("Error logging product change: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกการเปลี่ยนแปลง"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "เพิ่มสินค้าสำเร็จ"})
}

// UpdateProduct handles updating product quantity
func (p *ProductController) UpdateProduct(c *gin.Context) {

	type Product1 struct {
		ProductNumber string `json:"product_id"`
		ProductName   string `json:"product_name"`
		Quantity      int    `json:"quantity"`
	}
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

	// ตรวจสอบว่าสินค้ามีอยู่ในฐานข้อมูลหรือไม่
	var product Product1
	err := p.dbClient.QueryRow("SELECT product_id, product_name, quantity FROM products WHERE barcode = ?", requestData.Barcode).
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

	// บันทึกการเปลี่ยนแปลงลงในตาราง product_changes
	_, err = p.dbClient.Exec(`
		INSERT INTO product_changes (product_id, change_type, old_quantity, new_quantity, changed_by, created_at)
		VALUES (?, 'UPDATE', ?, ?, ?, CURRENT_TIMESTAMP)`,
		product.ProductNumber, product.Quantity, requestData.Quantity, "admin") // ใช้ "admin" แทนชื่อผู้ที่ทำการอัปเดตหรือดึงจาก JWT หรือการล็อกอิน

	if err != nil {
		log.Printf("Error logging product change: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error logging product change"})
		return
	}

	// อัปเดตจำนวนสินค้าในฐานข้อมูล
	_, err = p.dbClient.Exec("UPDATE products SET quantity = ? WHERE barcode = ?", requestData.Quantity, requestData.Barcode)
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
func (p *ProductController) GetProduct(c *gin.Context) {
	type Product1 struct {
		ProductNumber string `json:"product_id"`
		ProductName   string `json:"product_name"`
		Quantity      int    `json:"quantity"`
	}
	barcode := c.Query("barcode")

	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Barcode is required"})
		return
	}

	var product Product1
	err := p.dbClient.QueryRow("SELECT product_id, product_name, quantity FROM products WHERE barcode = ?", barcode).
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

// ดึงประวัติการเปลี่ยนแปลงสินค้าจากฐานข้อมูล
func (p *ProductController) GetProductChangeHistory(c *gin.Context) {

	rows, err := p.dbClient.Query(`
		SELECT ProductName, product_id, change_type, old_quantity, new_quantity, changed_by, created_at 
		FROM product_changes
		ORDER BY created_at DESC`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลประวัติการเปลี่ยนแปลงได้"})
		return
	}
	defer rows.Close()

	var productChanges []map[string]interface{}

	for rows.Next() {
		var ProductName, productNumber, changeType, changedBy, createdAt sql.NullString
		var oldQuantity, newQuantity sql.NullInt32

		// ใช้ rows.Scan สำหรับจับคู่กับคอลัมน์จาก query result
		err := rows.Scan(&ProductName, &productNumber, &changeType, &oldQuantity, &newQuantity, &changedBy, &createdAt)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถอ่านข้อมูลประวัติการเปลี่ยนแปลงได้"})
			log.Printf("Error scanning row: %v", err) // log เพิ่มเติมเพื่อง่ายต่อการ debug
			return
		}

		// สร้างแผนที่สำหรับข้อมูลในแถวปัจจุบันและจัดการค่า NULL
		productChanges = append(productChanges, map[string]interface{}{
			"ProductName":  getStringValue(ProductName),
			"product_id":   getStringValue(productNumber),
			"change_type":  getStringValue(changeType),
			"old_quantity": getIntValue(oldQuantity),
			"new_quantity": getIntValue(newQuantity),
			"changed_by":   getStringValue(changedBy),
			"created_at":   getStringValue(createdAt),
		})
	}

	// ตรวจสอบว่าผลลัพธ์ไม่มีปัญหาจากการอ่านข้อมูล
	if err := rows.Err(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในชุดผลลัพธ์ของการดึงข้อมูล"})
		log.Printf("Error reading rows: %v", err) // log เพิ่มเติมเพื่อง่ายต่อการ debug
		return
	}

	// ตรวจสอบว่ามีข้อมูลในประวัติการเปลี่ยนแปลง
	if len(productChanges) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "ไม่พบข้อมูลประวัติการเปลี่ยนแปลง"})
		return
	}

	// ส่งข้อมูลประวัติการเปลี่ยนแปลงกลับไปในรูปแบบ JSON
	c.JSON(http.StatusOK, productChanges)
}

// ฟังก์ชันช่วยสำหรับจัดการ sql.NullString
func getStringValue(input sql.NullString) string {
	if input.Valid {
		return input.String
	}
	return "" // คืนค่าเริ่มต้นเมื่อเป็น NULL
}

// ฟังก์ชันช่วยสำหรับจัดการ sql.NullInt32
func getIntValue(input sql.NullInt32) int {
	if input.Valid {
		return int(input.Int32)
	}
	return 0 // คืนค่าเริ่มต้นเมื่อเป็น NULL
}

// ฟังก์ชันสำหรับการสแกนบาร์โค้ดเพื่อเพิ่มสินค้า
func (p *ProductController) HandleScanBarcode(c *gin.Context) {

	type Request struct {
		Barcode string `json:"barcode"`
	}

	var req Request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	barcode := req.Barcode
	var quantity int
	var productID int

	err := p.dbClient.QueryRow("SELECT product_id, quantity FROM products WHERE barcode = ?", barcode).Scan(&productID, &quantity)
	if err == sql.ErrNoRows {
		// สินค้าไม่พบในระบบ ไม่เก็บข้อมูลลงฐานข้อมูล
		c.JSON(http.StatusOK, gin.H{
			"status":  "not_found",
			"message": "Product not found, but it will be added temporarily",
		})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	newQuantity := quantity + 1
	_, err = p.dbClient.Exec("UPDATE products SET quantity = ? WHERE product_id = ?", newQuantity, productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update quantity"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":       "updated",
		"message":      "Quantity updated",
		"new_quantity": newQuantity,
	})
}
