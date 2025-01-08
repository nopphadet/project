package UpdateProduct
import (
	// "database/sql"
	"database/sql"
	"log"
	"net/http"
	"strconv"
	"time"

	// "strconv"

	// "strconv" // Import strconv for converting string to int

	"github.com/gin-gonic/gin"
	// "golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

type GoodsReceipt struct {
	ReceiptID     int    `json:"receipt_id"`
	RecipientName string `json:"recipient_name" binding:"required"`
	ReceiptDate   string `json:"receipt_date" binding:"required"`
	Notes         string `json:"notes"`
}

func UpdateProductQuantity(c *gin.Context) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	barcode := c.Param("barcode")
	quantityStr := c.PostForm("quantity")

	quantity, err := strconv.Atoi(quantityStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "จำนวนสินค้าไม่ถูกต้อง"})
		return
	}

	query := `UPDATE products SET quantity = ? WHERE barcode = ?`
	result, err := db.Exec(query, quantity, barcode)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการอัปเดตจำนวนสินค้า"})
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบสินค้าเพื่อแก้ไข"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "อัปเดตจำนวนสินค้าสำเร็จ"})
}

func CreateGoodsReceipt(c *gin.Context) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	var receipt GoodsReceipt
	if err := c.ShouldBindJSON(&receipt); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}

	query := `INSERT INTO GoodsReceipt (RecipientName, ReceiptDate, Notes) VALUES (?, ?, ?)`
	receiptDate, err := time.Parse("2006-01-02", receipt.ReceiptDate) // แปลงวันที่เป็นฟอร์แมตที่ถูกต้อง
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "รูปแบบวันที่ไม่ถูกต้อง"})
		return
	}

	result, err := db.Exec(query, receipt.RecipientName, receiptDate, receipt.Notes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการเพิ่มใบรับสินค้า"})
		return
	}

	id, _ := result.LastInsertId()
	c.JSON(http.StatusOK, gin.H{
		"message":    "เพิ่มใบรับสินค้าสำเร็จ",
		"receipt_id": id,
	})
}

// ดึงข้อมูลใบรับสินค้าทั้งหมด
func GetAllGoodsReceipts(c *gin.Context) {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	query := `SELECT ReceiptID, RecipientName, ReceiptDate, Notes FROM GoodsReceipt`
	rows, err := db.Query(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการดึงข้อมูล"})
		return
	}
	defer rows.Close()

	var receipts []GoodsReceipt
	for rows.Next() {
		var receipt GoodsReceipt
		var receiptDate time.Time
		if err := rows.Scan(&receipt.ReceiptID, &receipt.RecipientName, &receiptDate, &receipt.Notes); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถอ่านข้อมูลจากฐานข้อมูลได้"})
			return
		}
		receipt.ReceiptDate = receiptDate.Format("2006-01-02")
		receipts = append(receipts, receipt)
	}

	c.JSON(http.StatusOK, receipts)
}
