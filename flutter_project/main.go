package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"
)

type User struct {
	Username        string `json:"username" binding:"required"`
	Email           string `json:"email" binding:"required,email"`
	Phone           string `json:"phone" binding:"required"`
	Password        string `json:"password" binding:"required,min=6"`
	ConfirmPassword string `json:"confirm_password" binding:"required,min=6"`
}

// ฟังก์ชันเพื่อเข้ารหัสรหัสผ่าน
func hashPassword(password string) (string, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hashedPassword), nil
}

func main() {
	// เชื่อมต่อฐานข้อมูล MySQL
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatal("ไม่สามารถเชื่อมต่อฐานข้อมูล: ", err) // แก้ไขข้อความผิดพลาด
	}
	defer db.Close()

	// ตรวจสอบการเชื่อมต่อฐานข้อมูล
	err = db.Ping()
	if err != nil {
		log.Fatal("การเชื่อมต่อฐานข้อมูลล้มเหลว: ", err)
	}

	r := gin.Default()

	// Route สำหรับสมัครสมาชิก
	r.POST("/register", func(c *gin.Context) {
		var user User
		// รับข้อมูลจาก Flutter
		if err := c.ShouldBindJSON(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		// ตรวจสอบว่ารหัสผ่านและยืนยันรหัสผ่านตรงกัน
		if user.Password != user.ConfirmPassword {
			c.JSON(http.StatusBadRequest, gin.H{"error": "รหัสผ่านไม่ตรงกัน"})
			return
		}

		// เข้ารหัสรหัสผ่าน
		hashedPassword, err := hashPassword(user.Password)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการเข้ารหัสรหัสผ่าน"})
			return
		}

		// บันทึกข้อมูลลงฐานข้อมูล
		query := `INSERT INTO users (username, email, phone, password) VALUES (?, ?, ?, ?)`
		_, err = db.Exec(query, user.Username, user.Email, user.Phone, hashedPassword)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกข้อมูลได้: " + err.Error()})
			return
		}

		// ส่งข้อความตอบกลับ
		c.JSON(http.StatusOK, gin.H{"message": "สมัครสมาชิกสำเร็จ"})
	})

	// Route สำหรับเข้าสู่ระบบ
	r.POST("/login", func(c *gin.Context) {
		var loginData struct {
			Username string `json:"username" binding:"required"`
			Password string `json:"password" binding:"required"`
		}

		// รับข้อมูลจาก Flutter
		if err := c.ShouldBindJSON(&loginData); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		// ค้นหาผู้ใช้ในฐานข้อมูล
		var hashedPassword string
		query := "SELECT password FROM users WHERE username = ?"
		err := db.QueryRow(query, loginData.Username).Scan(&hashedPassword)
		if err != nil {
			if err == sql.ErrNoRows {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในระบบ"})
			}
			return
		}

		// ตรวจสอบรหัสผ่าน
		if bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(loginData.Password)) != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
			return
		}

		// ส่งข้อความตอบกลับเมื่อเข้าสู่ระบบสำเร็จ
		c.JSON(http.StatusOK, gin.H{"message": "เข้าสู่ระบบสำเร็จ"})
	})

	// เริ่มเซิร์ฟเวอร์
	r.Run(":7070")
}
