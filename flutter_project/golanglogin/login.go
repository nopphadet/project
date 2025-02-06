package login

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
)

// ฟังก์ชันสำหรับสร้าง JWT Token
func generateToken(username, role string) (string, error) {
	secretKey := os.Getenv("JWT_SECRET") // ใช้ environment variable สำหรับความปลอดภัย
	if secretKey == "" {
		secretKey = "default_secret_key"
	}

	claims := jwt.MapClaims{
		"username": username,
		"role":     role,
		"exp":      time.Now().Add(24 * time.Hour).Unix(), // Token มีอายุ 24 ชั่วโมง
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secretKey))
}

// ฟังก์ชัน Login
func Login(c *gin.Context) {
	// เปิดการเชื่อมต่อฐานข้อมูล
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Printf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "การเชื่อมต่อฐานข้อมูลล้มเหลว"})
		return
	}
	defer db.Close()

	// ตรวจสอบการเชื่อมต่อฐานข้อมูล
	if err := db.Ping(); err != nil {
		log.Printf("การเชื่อมต่อฐานข้อมูลล้มเหลว: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "การเชื่อมต่อฐานข้อมูลล้มเหลว"})
		return
	}

	// โครงสร้างข้อมูลล็อกอิน
	var loginData struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	// ตรวจสอบข้อมูล JSON
	if err := c.ShouldBindJSON(&loginData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "กรุณากรอกข้อมูลให้ครบถ้วน"})
		return
	}

	// ทำการ trim ข้อมูลที่ไม่จำเป็น
	loginData.Username = strings.TrimSpace(loginData.Username)
	loginData.Password = strings.TrimSpace(loginData.Password)

	if loginData.Username == "" || loginData.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
		return
	}

	var (
		hashedPassword string
		role           string
		userID         int
	)

	// ดึงข้อมูล hashed password และ role จากฐานข้อมูล
	query := "SELECT password, role,user_id FROM users WHERE BINARY username = ?"
	err = db.QueryRow(query, loginData.Username).Scan(&hashedPassword, &role, &userID)
	if err != nil {
		log.Printf("ไม่พบชื่อผู้ใช้: %s - %v", loginData.Username, err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
		return
	}

	// ตรวจสอบรหัสผ่าน
	if err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(loginData.Password)); err != nil {
		log.Printf("รหัสผ่านไม่ถูกต้องสำหรับผู้ใช้: %s", loginData.Username)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"})
		return
	}

	// สร้าง Token
	token, err := generateToken(loginData.Username, role)
	if err != nil {
		log.Printf("ไม่สามารถสร้าง Token: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการสร้าง Token"})
		return
	}

	// ส่งผลลัพธ์กลับไป
	c.JSON(http.StatusOK, gin.H{
		"message": "เข้าสู่ระบบสำเร็จ",
		"role":    role,
		"token":   token,
		"userID":  userID,
	})

	fmt.Printf("ผู้ใช้ %s เข้าสู่ระบบด้วยสิทธิ์: %s\n", loginData.Username, role)
}
