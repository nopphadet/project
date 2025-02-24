package register // สำหรับการสมัครสมาชิก

import (
	"database/sql"
	"net/http"
	"newmos/newmos_api/db"
	"regexp"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"
)

type RegisterController struct {
	dbClient *sql.DB
}

func NewRegister(dbClient *sql.DB) *RegisterController {
	return &RegisterController{
		dbClient: dbClient,
	}
}

func (r *RegisterController) Register(c *gin.Context) {
	type User struct {
		Username string `json:"username" binding:"required,alpha"`
		Email    string `json:"email" binding:"required,email"`
		Phone    string `json:"phone" binding:"required,len=10"`
		Password string `json:"password" binding:"required,min=6"`
	}

	var user User
	if err := c.ShouldBindJSON(&user); err != nil {

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
	if _, err := r.dbClient.Exec(query, user.Username, user.Email, user.Phone, string(hashedPassword)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกข้อมูลได้: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "สมัครสมาชิกสำเร็จ"})

}

func Register(c *gin.Context) {
	type User struct {
		Username string `json:"username" binding:"required,alpha"`
		Email    string `json:"email" binding:"required,email"`
		Phone    string `json:"phone" binding:"required,len=10"`
		Password string `json:"password" binding:"required,min=6"`
	}

	db, err := db.InitDB()

	var user User
	if err := c.ShouldBindJSON(&user); err != nil {

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

}
