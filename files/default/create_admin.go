
package main

import (
	"log"
	"os"
	"strconv"

	"github.com/go-xorm/xorm"
	"github.com/gogits/gogs/models"
	"github.com/gogits/gogs/modules/setting"
	"github.com/gogits/gogs/routers"

	_ "github.com/lib/pq"
)

func main() {
	log.Println("Creating admin user: ", os.Getenv("ADMIN_USER_CREATE"))

	if val, err := strconv.ParseBool(os.Getenv("ADMIN_USER_CREATE")); err == nil && val {
		setting.CustomConf = os.Getenv("GOGS_CONFIG")
		routers.GlobalInit()
		log.Printf("Custom path: %s\n", setting.CustomPath)

		// Set test engine.
		var x *xorm.Engine
		if err := models.NewTestEngine(x); err != nil {
			log.Fatal("err: ", err)
		}

		models.LoadConfigs()
		models.SetEngine()

		// Create admin account.
		if err := models.CreateUser(&models.User{
			Name:     os.Getenv("ADMIN_USER_NAME"),
			Email:    os.Getenv("ADMIN_USER_EMAIL"),
			Passwd:   os.Getenv("ADMIN_USER_PASSWORD"),
			IsAdmin:  true,
			IsActive: true,
		}); err != nil {
			if models.IsErrUserAlreadyExist(err) {
				log.Println("Admin account already exist")
			} else {
				log.Fatalf("error: %v", err)
			}
		} else {
			log.Println("Admin account created: ", os.Getenv("ADMIN_USER_NAME"))
		}
	}
}

