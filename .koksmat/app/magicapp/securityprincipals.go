package magicapp

import (
	"log"

	mgm "github.com/kamva/mgm/v3"
	"github.com/sethvargo/go-password/password"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

type Authorization struct {
	AppId       string `json:"appid"`
	Permissions string `json:"permissions"`
}

func HashPassword(password string) (string, error) {
	//log.Println("Password", password)
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	return string(bytes), err
}

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

type AccessControl struct {
	mgm.DefaultModel `bson:",inline"`
	Identity         string `json:"identity"`
	SecurityKey      string `json:"key"`
	Permissions      string `json:"permissions"`
}

func (accessControl *AccessControl) Collection() *mgm.Collection {
	// Create new client

	client, err := mgm.NewClient(options.Client().ApplyURI(MongoConnectionString()))

	if err != nil {
		panic(err)
	}

	// Get the model's db
	db := client.Database("magicbox")

	// return the model's custom collection
	return mgm.NewCollection(db, "access_control")
}

func Authenticate(identity string, key string) (ok bool, permissions string) {

	//log.Println(tester)
	log.Println("Looking for", identity)
	filter := bson.D{{"identity", identity}}

	record, err := FindOne[*AccessControl](&AccessControl{}, filter)

	if err != nil {
		log.Println("Not found")
		return false, ""
	}
	hash, _ := HashPassword(identity + key)
	if !CheckPasswordHash(identity+key, hash) {
		log.Println("Hash doesn't match")
		return false, ""
	}
	log.Println("Matched")
	return true, record.Permissions

}

func IssueAccessKey(identity string) (key string, hash string, err error) {
	// Generate a password that is 64 characters long with 10 digits, 10 symbols,
	// allowing upper and lower case letters, disallowing repeat characters.
	key, err = password.Generate(32, 10, 10, false, false)
	if err != nil {
		return key, hash, err
	}
	hash, err = HashPassword(identity + key)
	if err != nil {
		return key, hash, err
	}

	filter := bson.D{{"identity", identity}}
	record, err := FindOne[*AccessControl](&AccessControl{}, filter)

	if err == nil {

		record.SecurityKey = hash
		mgm.Coll(record).Update(record)

	} else {
		newRecord := &AccessControl{

			Identity:    identity,
			SecurityKey: hash,
		}

		mgm.Coll(newRecord).Create(newRecord)

	}
	return key, hash, err

}
