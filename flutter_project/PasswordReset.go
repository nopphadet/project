package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"log"
	"net/http"
	"net/smtp"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

//  const jwtSecretKey = "your_secret_key"

func generateToken() (string, error) {
	token := make([]byte, 16)
	_, err := rand.Read(token)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(token), nil
}

func sendResetEmail(email, resetToken string) error {
	smtpHost := "smtp.gmail.com"
	smtpPort := "587"
	senderEmail := "your-email@gmail.com"
	senderPassword := "your-email-password"

	auth := smtp.PlainAuth("", senderEmail, senderPassword, smtpHost)
	subject := "Password Reset Request"
	body := "Click the following link to reset your password: http://localhost:7070/reset-password?token=" + resetToken
	message := "Subject: " + subject + "\r\n\r\n" + body

	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, senderEmail, []string{email}, []byte(message))
	if err != nil {
		return err
	}
	return nil
}

func PasswordReset() {
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

	// Request Password Reset
	r.POST("/request-reset-password", func(c *gin.Context) {
		var request struct {
			Email string `json:"email" binding:"required,email"`
		}
		if err := c.ShouldBindJSON(&request); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		var userID int
		query := "SELECT id FROM users WHERE email = ?"
		err := db.QueryRow(query, request.Email).Scan(&userID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "ไม่พบผู้ใช้งานที่มีอีเมลนี้"})
			return
		}

		resetToken, err := generateToken()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้าง token ได้"})
			return
		}

		expiry := time.Now().Add(1 * time.Hour)
		query = "INSERT INTO password_resets (user_id, token, expiry) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE token = ?, expiry = ?"
		_, err = db.Exec(query, userID, resetToken, expiry, resetToken, expiry)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถบันทึกข้อมูลได้"})
			return
		}

		err = sendResetEmail(request.Email, resetToken)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถส่งอีเมลได้"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "ส่งคำขอเปลี่ยนรหัสผ่านสำเร็จ"})
	})

	// Reset Password
	r.POST("/reset-password", func(c *gin.Context) {
		var resetData struct {
			Token    string `json:"token" binding:"required"`
			Password string `json:"password" binding:"required,min=6"`
		}
		if err := c.ShouldBindJSON(&resetData); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
			return
		}

		var userID int
		var expiry time.Time
		query := "SELECT user_id, expiry FROM password_resets WHERE token = ?"
		err := db.QueryRow(query, resetData.Token).Scan(&userID, &expiry)
		if err != nil || time.Now().After(expiry) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Token ไม่ถูกต้องหรือหมดอายุ"})
			return
		}

		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(resetData.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "เกิดข้อผิดพลาดในการเข้ารหัสรหัสผ่าน"})
			return
		}

		query = "UPDATE users SET password = ? WHERE id = ?"
		_, err = db.Exec(query, string(hashedPassword), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเปลี่ยนรหัสผ่านได้"})
			return
		}

		query = "DELETE FROM password_resets WHERE token = ?"
		_, _ = db.Exec(query, resetData.Token) // ลบ token หลังเปลี่ยนรหัสผ่าน

		c.JSON(http.StatusOK, gin.H{"message": "เปลี่ยนรหัสผ่านสำเร็จ"})
	})

	r.Run(":7070")
}
