package main

import (
	"fmt"
	"log"
	showproducts "newmos/newmos_api/Golistproduct"
	productProvider "newmos/newmos_api/golangProductProvider"

	db "newmos/newmos_api/db"
	login "newmos/newmos_api/golanglogin"
	products "newmos/newmos_api/golangnewproducts"
	register "newmos/newmos_api/golangregister"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

func Init() {

	r := gin.Default()
	db, err := db.InitDB()
	if err != nil {
		log.Fatalf("Error connecting to database: %v", err)
	}
	fmt.Println(db)
	NewRegister := register.NewRegister(db)
	r.POST("/register", NewRegister.Register)

	Newproduct := products.NewProduct(db)
	r.POST("/products", Newproduct.Product)
	r.PUT("/products/update", Newproduct.UpdateProduct)
	r.GET("/products", Newproduct.GetProduct)
	r.POST("/api/scan", Newproduct.HandleScanBarcode)
	r.POST("/products/delete", Newproduct.DeleteProduct)
	

	Newprovider := productProvider.NewProvider(db)
	r.GET("/ProductProvider/search", Newprovider.SearchProducts)
	r.POST("/ProductProvider/reserve", Newprovider.ReserveProduct)
	r.POST("/ProductProvider/confirm", Newprovider.ConfirmReservation)
	r.GET("/ProductProvider/reservations", Newprovider.GetReservations)

	Newlogin := login.Newlogin(db)
	r.POST("/login", Newlogin.Login)

	Newshowproducts := showproducts.Newlogin(db)
	r.GET("/showproducts", Newshowproducts.Showproducts)

	r.Static("/uploads", "./uploads")
	r.Run(":7070")

}

func main() {

	Init()

}
