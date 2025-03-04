package productProvider // จองสินค้า และยืนยันการจองสินค้า

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	// "time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

type Product struct {
	ProductId   int    `json:"product_id"`
	ProductName string `json:"product_name"`
	Category    string `json:"category"`
	Quantity    int    `json:"quantity"`
	Barcode     string `json:"barcode"`
	StockStatus string `json:"stock_status"`
	ImagePath   string `json:"image_path"`
	ImageUrl    string `json:"image_url"`
	CreatedAt   string `json:"created_at"`
}
type ProductProviderController struct {
	dbClient *sql.DB
}

func NewProvider(dbClient *sql.DB) *ProductProviderController {
	return &ProductProviderController{
		dbClient: dbClient,
	}
}

func (p *ProductProviderController) SearchProducts(c *gin.Context) {

	productName := c.DefaultQuery("name", "")
	category := c.DefaultQuery("category", "")

	query := `
		SELECT product_id, product_name, category, quantity, barcode, stock_status, image_path, created_at
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

	query += " ORDER BY created_at DESC" //ดึงสินค้าล่าสุดก่อน

	log.Printf("Executing query: %s, args: %v", query, args)
	rows, err := p.dbClient.Query(query, args...)
	if err != nil {
		log.Printf("Error fetching products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถค้นหาสินค้าได้"})
		return
	}
	defer rows.Close()

	products := []Product{}

	for rows.Next() {
		var product Product
		err := rows.Scan(&product.ProductId, &product.ProductName, &product.Category, &product.Quantity, &product.Barcode, &product.StockStatus, &product.ImagePath, &product.CreatedAt)
		if err != nil {
			log.Printf("Error scanning product: %v", err)
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

func (p *ProductProviderController) ReserveProduct(c *gin.Context) {

	var req struct {
		UserID    string `json:"user_id"`
		ProductID int    `json:"product_id"`
		Quantity  int    `json:"quantity"`
	}

	// ตรวจสอบว่า JSON request ถูกต้องหรือไม่
	if err := c.ShouldBindJSON(&req); err != nil {
		fmt.Printf("Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "รูปแบบคำขอไม่ถูกต้อง"})
		return
	}

	// ตรวจสอบว่าผู้ใช้มีอยู่หรือไม่
	fmt.Println(req.UserID)
	var userExists int
	err := p.dbClient.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE user_id = ?)", req.UserID).Scan(&userExists)
	if err != nil {
		log.Printf("Error checking user existence: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการตรวจสอบข้อมูลผู้ใช้"})
		return
	}
	fmt.Println(userExists)
	if userExists == 0 {
		fmt.Println("User not found")
		c.JSON(http.StatusBadRequest, gin.H{"error": "ไม่พบข้อมูลผู้ใช้ที่ระบุ"})
		return
	}

	// ตรวจสอบว่าผลิตภัณฑ์มีอยู่หรือไม่
	var productExists bool
	err = p.dbClient.QueryRow("SELECT EXISTS(SELECT 1 FROM products WHERE product_id = ?)", req.ProductID).Scan(&productExists)
	if err != nil {
		log.Printf("Error checking product existence: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการตรวจสอบข้อมูลสินค้า"})
		return
	}

	if !productExists {
		fmt.Println("Product not found")
		c.JSON(http.StatusBadRequest, gin.H{"error": "ไม่พบข้อมูลสินค้าที่ระบุ"})
		return
	}

	// ตรวจสอบว่าสินค้ามีพอให้จองหรือไม่
	var availableStock int
	err = p.dbClient.QueryRow("SELECT quantity FROM products WHERE product_id = ?", req.ProductID).Scan(&availableStock)
	if err == sql.ErrNoRows {
		log.Printf("Product not found: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบสินค้าในระบบ"})
		return
	} else if err != nil {
		log.Printf("Error checking stock: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการตรวจสอบสต็อก"})
		return
	}

	// ตรวจสอบว่ามีสต็อกเพียงพอหรือไม่
	if availableStock < req.Quantity {
		log.Printf("Not enough stock: requested %d, available %d", req.Quantity, availableStock)
		c.JSON(http.StatusBadRequest, gin.H{"error": "จำนวนสินค้าไม่เพียงพอ"})
		return
	}

	// บันทึกการจอง
	_, err = p.dbClient.Exec(`
    INSERT INTO reservations (user_id, product_id, quantity, status, expires_at) 
    VALUES (?, ?, ?, 'pending', DATE_ADD(NOW(), INTERVAL 30 MINUTE))`,
		req.UserID, req.ProductID, req.Quantity)

	if err != nil {
		log.Printf("Failed to reserve product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถจองสินค้าได้"})
		return
	}
	log.Printf("UserID: %d, ProductID: %d, Quantity: %d", req.UserID, req.ProductID, req.Quantity)

	log.Printf("จองสินค้าเรียบร้อยแล้ว")

	// ลดจำนวนสินค้าในคลังหลังจากจอง
	// _, err = p.dbClient.Exec("UPDATE products SET quantity = quantity - ? WHERE product_id = ?", req.Quantity, req.ProductID)
	// if err != nil {
	// 	log.Printf("Failed to update product quantity: %v", err)
	// 	c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถอัปเดตจำนวนสินค้าได้"})
	// 	return
	// }

}

func (p *ProductProviderController) ConfirmReservation(c *gin.Context) {

	var req struct {
		ReservationID int `json:"reservation_id"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// ตรวจสอบว่าการจองมีอยู่และยังไม่หมดอายุ
	var status string
	var productID, quantity int
	err := p.dbClient.QueryRow("SELECT product_id, quantity, status FROM reservations WHERE id = ? AND expires_at > NOW()", req.ReservationID).
		Scan(&productID, &quantity, &status)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Reservation not found or expired"})
		return
	}

	if status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Reservation is not pending"})
		return
	}

	// อัปเดตสถานะเป็น "confirmed" และลด stock สินค้า
	_, err = p.dbClient.Exec("UPDATE reservations SET status = 'confirmed' WHERE reserve_id = ?", req.ReservationID)
	_, err = p.dbClient.Exec("UPDATE products SET quantity = quantity - ? WHERE product_id = ?", quantity, productID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to confirm reservation"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Reservation confirmed successfully"})
}

func (p *ProductProviderController) GetReservations(c *gin.Context) {

	type Reservation struct {
		ReserveID        int            `json:"reserve_id"`
		UserID           string         `json:"user_id"`
		ProductID        int            `json:"product_id"`
		Quantity         int            `json:"quantity"`
		ActualQuantity   int            `json:"actual_quantity"`
		ReturnedQuantity int            `json:"returned_quantity"`
		Status           string         `json:"status"`
		ExpiresAt        sql.NullString `json:"expires_at"`
		ProductName      string         `json:"product_name"`
		ImageUrl         string         `json:"image_url"`
		Createdat        string         `json:"created_at"`
	}
	rows, err := p.dbClient.Query(`
        SELECT r.reserve_id, r.user_id, r.product_id, r.quantity, r.actual_quantity, r.returned_quantity, r.status, r.expires_at,r.created_at,
               p.product_name, CONCAT('https://hfm99nd8-7070.asse.devtunnels.ms/', p.image_path) as image_url
        FROM reservations r
        LEFT JOIN products p ON r.product_id = p.product_id
        ORDER BY r.reserve_id DESC`)
	if err != nil {
		log.Printf("Error fetching reservations: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลการจองได้"})
		return
	}
	defer rows.Close()

	var reservations []Reservation
	for rows.Next() {
		var r Reservation
		var expiresAt sql.NullString // ตัวแปรชั่วคราวสำหรับ expires_at
		err := rows.Scan(&r.ReserveID, &r.UserID, &r.ProductID, &r.Quantity, &r.ActualQuantity, &r.ReturnedQuantity, &r.Status, &expiresAt,&r.Createdat, &r.ProductName, &r.ImageUrl, )
		if err != nil {
			log.Printf("Error scanning reservation: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการอ่านข้อมูล"})
			return
		}
		// แปลง sql.NullString เป็น string โดยใช้ค่าเริ่มต้นถ้า NULL
		if expiresAt.Valid {
			r.ExpiresAt = expiresAt
		} else {
			r.ExpiresAt = sql.NullString{String: "", Valid: false} // หรือกำหนดค่าเริ่มต้นที่ต้องการ
		}
		reservations = append(reservations, r)
	}

	if err := rows.Err(); err != nil {
		log.Printf("Rows error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการประมวลผลข้อมูล"})
		return
	}

	if len(reservations) == 0 {
		c.JSON(http.StatusOK, gin.H{"data": []Reservation{}, "message": "ไม่มีข้อมูลการจองในระบบ"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": reservations})
}
