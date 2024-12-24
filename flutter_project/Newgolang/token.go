package token

import (
	// "database/sql"
	// "log"
	"net/http"
	// "regexp"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/golang-jwt/jwt/v4"
	// "golang.org/x/crypto/bcrypt"
)

const jwtSecretKey = "your_secret_key"

func CreateToken(username string, duration time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"username": username,
		"exp":      time.Now().Add(duration).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecretKey))
}

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString, err := c.Cookie("auth_token")
		if err != nil {
			// แสดงข้อความเมื่อไม่พบคุกกี้ auth_token
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ไม่ได้เข้าสู่ระบบ, ไม่พบ Token"})
			c.Abort()
			return
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtSecretKey), nil
		})
		if err != nil || !token.Valid {
			// แสดงข้อความเมื่อ Token ไม่ถูกต้อง
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ไม่ถูกต้อง หรือหมดอายุ"})
			c.Abort()
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			// แสดงข้อความหากไม่สามารถแยก Claims ได้
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ไม่ถูกต้อง"})
			c.Abort()
			return
		}

		c.Set("username", claims["username"]) // จัดเก็บข้อมูล username จาก Token
		c.Next()                              // ส่งต่อ request ไปยัง handler ถัดไป
	}
}
