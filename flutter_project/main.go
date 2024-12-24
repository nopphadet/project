package main

import (
	"database/sql"
	"log"
	"net/http"
	"regexp"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"

	// "github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
)

// User Struct
type User struct {
	Username string `json:"username" binding:"required,alpha"`
	Email    string `json:"email" binding:"required,email"`
	Phone    string `json:"phone" binding:"required,min=9,max=10"`
	Password string `json:"password" binding:"required,min=6"`
}

func main() {

	token.AuthMiddleware
	token.CreateToken

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

		// Validation
		emailRegex := regexp.MustCompile("^[a-zA-Z0-9._%+-]+@gmail\\.com$")
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

		token, err := createToken(loginData.Username, time.Hour*24)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้าง Token ได้"})
			return
		}

		// ปรับการตั้งคุกกี้ให้ทำงานใน HTTP หรือ HTTPS
		c.SetCookie("auth_token", token, 3600, "/", "", false, true)
		c.JSON(http.StatusOK, gin.H{"message": "เข้าสู่ระบบสำเร็จ", "token": token})
	})

	r.Run(":7070")
}
