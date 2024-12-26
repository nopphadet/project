package main

import (
	"database/sql"
	"log"
	"net/http"
	"regexp"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

const jwtSecretKey = "your_secret_key"

type User struct {
	Username string `json:"username" binding:"required,alpha"`
	Email    string `json:"email" binding:"required,email"`
	Phone    string `json:"phone" binding:"required,len=10"`
	Password string `json:"password" binding:"required,min=6"`
}

type Product struct {
	ProductNumber string `json:"product_number"`
	ProductName   string `json:"product_name"`
	Category      string `json:"category"`
	Quantity      int    `json:"quantity"`
	Barcode       string `json:"barcode"`
	StockStatus   string `json:"stock_status"`
	ImagePath     string `json:"image_path"`
}

func createToken(username string, duration time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"username": username,
		"exp":      time.Now().Add(duration).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecretKey))
}

func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// ดึง Token จาก Header
		tokenString := c.GetHeader("Authorization")
		if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
			tokenString = tokenString[7:] // เอา "Bearer " ออก
		} else {
			// ลองดึง Token จาก Cookie
			var err error
			tokenString, err = c.Cookie("auth_token")
			if err != nil {
				log.Println("Token ไม่พบใน Header และ Cookie:", err)
				c.JSON(http.StatusUnauthorized, gin.H{"error": "ไม่ได้เข้าสู่ระบบ, ไม่พบ Token"})
				c.Abort()
				return
			}
		}

		// Debug Token ที่ได้รับ
		log.Println("Token ที่ได้รับ:", tokenString)

		// ตรวจสอบความถูกต้องของ Token
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				log.Println("รูปแบบ Token ไม่ถูกต้อง:", token.Header["alg"])
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(jwtSecretKey), nil
		})
		if err != nil || !token.Valid {
			log.Println("Token ไม่ถูกต้องหรือหมดอายุ:", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ไม่ถูกต้องหรือหมดอายุ"})
			c.Abort()
			return
		}

		// ดึงข้อมูล Claims
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok || !token.Valid {
			log.Println("ดึง Claims จาก Token ไม่สำเร็จ")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ไม่ถูกต้อง"})
			c.Abort()
			return
		}

		// Debug ข้อมูล Claims
		log.Println("Claims ที่ดึงได้:", claims)

		// ตั้งค่า Context เพื่อใช้ใน Endpoint อื่น
		c.Set("username", claims["username"])
		c.Next()
	}
}

func main() {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatal("ไม่สามารถเชื่อมต่อฐานข้อมูล: ", err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatal("การเชื่อมต่อฐานข้อมูลล้มเหลว: ", err)
	}

	r := gin.Default()

	// สมัครสมาชิก
	r.POST("/register", func(c *gin.Context) {
		var user User
		if err := c.ShouldBindJSON(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

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

		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการเข้ารหัสรหัสผ่าน"})
			return
		}

		query := "INSERT INTO users (username, email, phone, password) VALUES (?, ?, ?, ?)"
		_, err = db.Exec(query, user.Username, user.Email, user.Phone, string(hashedPassword))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกข้อมูลได้: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "สมัครสมาชิกสำเร็จ"})
	})

	// เข้าสู่ระบบ
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
		err := db.QueryRow(query, loginData.Username).Scan(&hashedPassword)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
			return
		}

		if bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(loginData.Password)) != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
			return
		}

		// Generate JWT token
		token, err := createToken(loginData.Username, time.Hour*24)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้าง Token ได้"})
			return
		}

		// Set token in cookie
		c.SetCookie("auth_token", token, 3600, "/", "", false, true)
		c.JSON(http.StatusOK, gin.H{"message": "เข้าสู่ระบบสำเร็จ", "token": token})
	})

	// จัดการสินค้า
	r.POST("/products", authMiddleware(), func(c *gin.Context) {
		var product Product
		if err := c.ShouldBindJSON(&product); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลสินค้าไม่ถูกต้อง"})
			return
		}

		query := `INSERT INTO products (product_number, product_name, category, quantity, barcode, stock_status, image_path, created_at) 
				  VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`

		_, err := db.Exec(query, product.ProductNumber, product.ProductName, product.Category, product.Quantity, product.Barcode, product.StockStatus, product.ImagePath)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเพิ่มสินค้าได้: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "เพิ่มสินค้าสำเร็จ"})
	})

	r.Run(":7070")
}
