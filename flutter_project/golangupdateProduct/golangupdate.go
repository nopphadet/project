package update

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

func Update(c *gin.Context) {
	InitializeDB()
	CloseDB()
	SearchProduct(c)
	UpdateQuantity(c)
	GetProducts(c)
	Outfoproduct(c)
}

var db *sql.DB

// InitializeDB - Initializing a shared database connection
func InitializeDB() {
	var err error
	db, err = sql.Open("mysql", "root:@tcp(localhost:3306)/myapp?timeout=30s")
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("Database connection initialized successfully")
}

// CloseDB - Close the shared database connection
func CloseDB() {
	if db != nil {
		if err := db.Close(); err != nil {
			log.Printf("Error closing database connection: %v", err)
		}
	}
}

// SearchProduct - API to search for a product by barcode
func SearchProduct(c *gin.Context) {
	barcode := c.Query("barcode")
	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "กรุณาระบุ Barcode"})
		c.Abort()
		return
	}

	var product struct {
		ProductNumber string `json:"product_number"`
		ProductName   string `json:"product_name"`
		Category      string `json:"category"`
		Quantity      int    `json:"quantity"`
		StockStatus   string `json:"stock_status"`
	}

	query := `SELECT product_number, product_name, category, quantity, stock_status FROM products WHERE barcode = ?`
	row := db.QueryRow(query, barcode)

	err := row.Scan(
		&product.ProductNumber,
		&product.ProductName,
		&product.Category,
		&product.Quantity,
		&product.StockStatus,
	)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"message": "ไม่พบสินค้า"})
		c.Abort()
		return
	} else if err != nil {
		log.Printf("Error retrieving product: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลสินค้าได้"})
		c.Abort()
		return
	}

	c.JSON(http.StatusOK, gin.H{"product": product})
}

// UpdateQuantity - API to update a product's quantity
func UpdateQuantity(c *gin.Context) {
	var request struct {
		Barcode  string `json:"barcode" binding:"required"`
		Quantity int    `json:"quantity" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ครบถ้วน"})
		c.Abort()
		return
	}

	var count int
	checkQuery := `SELECT COUNT(*) FROM products WHERE barcode = ?`
	err := db.QueryRow(checkQuery, request.Barcode).Scan(&count)
	if err != nil || count == 0 {
		log.Printf("Error checking product: %v", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบสินค้า"})
		c.Abort()
		return
	}

	query := "UPDATE products SET quantity = ? WHERE barcode = ?"
	result, err := db.Exec(query, request.Quantity, request.Barcode)
	if err != nil {
		log.Printf("Error updating quantity: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถอัปเดตข้อมูลได้"})
		c.Abort()
		return
	}

	rowsAffected, _ := result.RowsAffected()
	c.JSON(http.StatusOK, gin.H{"message": "อัปเดตข้อมูลสำเร็จ", "updated_rows": rowsAffected})
}

// GetProducts - API to retrieve all products
func GetProducts(c *gin.Context) {
	query := "SELECT product_number, product_name, category, quantity, barcode, stock_status FROM products"
	rows, err := db.Query(query)
	if err != nil {
		log.Printf("Error querying products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถดึงข้อมูลสินค้าได้"})
		return
	}
	defer rows.Close()

	var products []map[string]interface{}
	for rows.Next() {
		var product struct {
			ProductNumber string
			ProductName   string
			Category      string
			Quantity      int
			Barcode       string
			StockStatus   string
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

// Outfoproduct - Handler for outfoproduct page
func Outfoproduct(c *gin.Context) {
	rows, err := db.Query("SELECT * FROM products")
	if err != nil {
		log.Printf("Failed to query products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query products"})
		return
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var product Product
		if err := rows.Scan(&product.ID, &product.Name, &product.Price); err != nil {
			log.Printf("Failed to scan product: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan product"})
			return
		}
		products = append(products, product)
	}

	c.JSON(http.StatusOK, products)
}

type Product struct {
	ID    int
	Name  string
	Price float64
}
