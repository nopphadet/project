package login

import (
	//"crypto/sha1"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	//"encoding/hex"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
)

type ProductController struct {
	dbClient *sql.DB
}

func Newlogin(dbClient *sql.DB) *ProductController {
	return &ProductController{
		dbClient: dbClient,
	}
}


//ฟังก์ชันสำหรับแปลง Token ให้เป็น SHA1
/*func (p *ProductController) convertTokentosha1(token string) string {

	hasher := sha1.New()
	hasher.Write([]byte(token))
	return hex.EncodeToString(hasher.Sum(nil))
}
func (p *ProductController) converttosha1 (c *gin.Context) {
	 var token string
	 err:= p.dbClient.QueryRow("SELECT token FROM users WHERE user_id=? ",1).Scan(&token)
	 if err != nil {
		 log.Fatal(err)
	 }
	 sha1token := p.convertTokentosha1(token)

	 _, err = p.dbClient.Exec("UPDATE users SET token=? WHERE user_id=?", sha1token, 1)
	 if err != nil {
		 log.Fatal(err)
	 }
	 fmt.Println("Token updated to sha1", sha1token)
	}
// func inValidToken (inputToken, storedHash string) bool {
// 		return convertTokentosha1(inputToken) == storedHash
// }*/


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
func (p *ProductController) Login(c *gin.Context) {

	// ตรวจสอบการเชื่อมต่อฐานข้อมูล
	if err := p.dbClient.Ping(); err != nil {
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
		username       string
		role           string
		userID         int
	)

	// ดึงข้อมูล hashed password และ role จากฐานข้อมูล
	query := "SELECT password, role,user_id, username FROM users WHERE BINARY username = ?"
	err := p.dbClient.QueryRow(query, loginData.Username).Scan(&hashedPassword, &role, &userID, &username)
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
		"message":  "เข้าสู่ระบบสำเร็จ",
		"role":     role,
		"token":    token,
		"userID":   userID,
		"username": username,
	})

	fmt.Printf("ผู้ใช้ %s เข้าสู่ระบบด้วยสิทธิ์: %s\n", loginData.Username, role)
}
