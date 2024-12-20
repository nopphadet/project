package main

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
	"gopkg.in/gomail.v2"
)

// Secret Key
const jwtSecretKey = "your_secret_key"

// User Struct
type User struct {
	Username string `json:"username" binding:"required,alpha"`
	Email    string `json:"email" binding:"required,email"`
	Phone    string `json:"phone" binding:"required,min=9,max=10"`
	Password string `json:"password" binding:"required,min=6"`
}

// ฟังก์ชันสร้าง JWT Token
func createToken(username string, duration time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"username": username,
		"exp":      time.Now().Add(duration).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecretKey))
}

// ฟังก์ชันส่งอีเมล
func sendEmail(to, subject, body string) error {
	m := gomail.NewMessage()
	m.SetHeader("From", "your_email@gmail.com") // เปลี่ยนเป็นอีเมลของคุณ
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/html", body)

	d := gomail.NewDialer("smtp.gmail.com", 587, "your_email@gmail.com", "your_app_password") // ใช้ App Password

	return d.DialAndSend(m)
}

func main() {
	// เชื่อมต่อฐานข้อมูล
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

	// ลืมรหัสผ่าน
	r.POST("/forgot_password", func(c *gin.Context) {
		var data struct {
			Email string `json:"email" binding:"required,email"`
		}

		if err := c.ShouldBindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		// ตรวจสอบว่าอีเมลมีอยู่ในระบบหรือไม่
		var username string
		err := db.QueryRow("SELECT username FROM users WHERE email = ?", data.Email).Scan(&username)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "อีเมลไม่ถูกต้อง"})
			return
		}

		// สร้าง Token สำหรับรีเซ็ตรหัสผ่าน
		token, err := createToken(username, time.Minute*15)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้าง Token ได้"})
			return
		}

		// ส่งอีเมล
		body := `<p>คุณได้รับคำขอรีเซ็ตรหัสผ่าน</p>
		         <p>โปรดคลิกลิงก์ด้านล่างเพื่อรีเซ็ตรหัสผ่านของคุณ:</p>
		         <a href="https://yourapp.com/reset-password?token=` + token + `">รีเซ็ตรหัสผ่าน</a>`
		err = sendEmail(data.Email, "คำขอรีเซ็ตรหัสผ่าน", body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถส่งอีเมลได้"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "ส่งคำขอรีเซ็ตรหัสผ่านสำเร็จ"})
	})

	// รีเซ็ตรหัสผ่าน
	r.POST("/reset_password", func(c *gin.Context) {
		var data struct {
			Token    string `json:"token" binding:"required"`
			Password string `json:"password" binding:"required,min=6"`
		}

		if err := c.ShouldBindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		// ตรวจสอบ Token
		token, err := jwt.Parse(data.Token, func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtSecretKey), nil
		})
		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ไม่ถูกต้อง"})
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok || claims["username"] == nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ไม่ถูกต้อง"})
			return
		}

		username := claims["username"].(string)

		// อัปเดตรหัสผ่านในฐานข้อมูล
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(data.Password), bcrypt.DefaultCost)
		_, err = db.Exec("UPDATE users SET password = ? WHERE username = ?", string(hashedPassword), username)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถรีเซ็ตรหัสผ่านได้"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "รีเซ็ตรหัสผ่านสำเร็จ"})
	})

	r.Run(":7070")
}
