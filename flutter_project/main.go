package main

import (
	"database/sql"
	"log"
	"net/http"
	"regexp"
	"strconv" // Import strconv for converting string to int

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

type User struct {
	Username string `json:"username" binding:"required,alpha"`
	Email    string `json:"email" binding:"required,email"`
	Phone    string `json:"phone" binding:"required,len=10"`
	Password string `json:"password" binding:"required,min=6"`
}

func main() {
	// เชื่อมต่อกับฐานข้อมูล MySQL
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	// ทดสอบการเชื่อมต่อ
	if err := db.Ping(); err != nil {
		log.Fatalf("การเชื่อมต่อฐานข้อมูลล้มเหลว: %v", err)
	}

	// สร้าง Router สำหรับ Gin
	r := gin.Default()

	// API สมัครสมาชิก
	r.POST("/register", func(c *gin.Context) {
		var user User
		if err := c.ShouldBindJSON(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		// ตรวจสอบอีเมลและเบอร์โทร
		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@gmail.com$`)
		if !emailRegex.MatchString(user.Email) {
			c.JSON(http.StatusBadRequest, gin.H{"message": "อีเมลต้องเป็น @Gmail เท่านั้น"})
			return
		}

		phoneRegex := regexp.MustCompile("^0[0-9]{9}$")
		if !phoneRegex.MatchString(user.Phone) {
			c.JSON(http.StatusBadRequest, gin.H{"message": "เบอร์โทรศัพท์ต้องเริ่มต้นด้วย 0 และมี 10 หลัก"})
			return
		}

		// เข้ารหัสรหัสผ่าน
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการเข้ารหัสรหัสผ่าน"})
			return
		}

		// SQL สำหรับบันทึกผู้ใช้งาน
		query := "INSERT INTO users (username, email, phone, password) VALUES (?, ?, ?, ?)"
		if _, err := db.Exec(query, user.Username, user.Email, user.Phone, string(hashedPassword)); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกข้อมูลได้: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "สมัครสมาชิกสำเร็จ"})
	})

	// API เข้าสู่ระบบ
	r.POST("/login", func(c *gin.Context) {
		var loginData struct {
			Username string `json:"username" binding:"required"`
			Password string `json:"password" binding:"required"`
		}
		if err := c.ShouldBindJSON(&loginData); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		var hashedPassword string
		query := "SELECT password FROM users WHERE username = ?"
		if err := db.QueryRow(query, loginData.Username).Scan(&hashedPassword); err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
			return
		}

		if bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(loginData.Password)) != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "เข้าสู่ระบบสำเร็จ"})
	})

	// API เพิ่มสินค้า
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

	// รันเซิร์ฟเวอร์ที่พอร์ต 7070
	r.Run(":7070")
}
