package login

import (
	// "database/sql"
	// "log"
	"database/sql"
	"log"
	"net/http"

	// "regexp"

	// "strconv" // Import strconv for converting string to int

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	_ "github.com/go-sql-driver/mysql"
)

func Login() {
	db, err := sql.Open("mysql", "root:@tcp(localhost:3306)/myapp")
	if err != nil {
		log.Fatalf("ไม่สามารถเชื่อมต่อฐานข้อมูล: %v", err)
	}
	defer db.Close()

	// ทดสอบการเชื่อมต่อ
	if err := db.Ping(); err != nil {
		log.Fatalf("การเชื่อมต่อฐานข้อมูลล้มเหลว: %v", err)
	}
	r := gin.Default()
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
}
