package magicapp

import (
	"context"

	"github.com/spf13/viper"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func Connect() *mongo.Client {
	connectionString := viper.GetString("DATABASEURL")

	credential := options.Credential{
		Username: viper.GetString("DATABASEADMIN"),
		Password: viper.GetString("DATABASEPASSWORD"),
	}
	clientOpts := options.Client().ApplyURI(connectionString).SetAuth(credential).SetDirect(true)

	client, err := mongo.Connect(context.TODO(), clientOpts)
	if err != nil {
		panic(err)
	}
	return client

}
