package showproducts // แสดงสินค้าทั้งหมด

import (
	"database/sql"
	"log"
	"net/http"
	// "time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)
type ProductController struct {
	dbClient *sql.DB
}

func Newlogin(dbClient *sql.DB) *ProductController {
	return &ProductController{
		dbClient: dbClient,
	}
}

// Product - โครงสร้างข้อมูลสินค้า
type Product struct {
	ProductId   string `json:"product_id"`
	ProductName string `json:"product_name"`
	Category    string `json:"category"`
	Quantity    int    `json:"quantity"`
	Barcode     string `json:"barcode"`
	StockStatus string `json:"stock_status"`
	ImagePath   string `json:"image_path"`
	ImageUrl    string `json:"image_url"`
	CreatedAt   string `json:"created_at"`
}

func (p *ProductController)Showproducts(c *gin.Context) {

	rows, err := p.dbClient.Query(`
		SELECT product_id, product_name, category, quantity, barcode, stock_status, image_path, created_at 
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
		err := rows.Scan(&product.ProductId, &product.ProductName, &product.Category, &product.Quantity, &product.Barcode, &product.StockStatus, &product.ImagePath, &product.CreatedAt)
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
