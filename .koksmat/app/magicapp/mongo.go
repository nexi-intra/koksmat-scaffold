package magicapp

import (
	"context"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func MongoTest() error {
	// Requires the MongoDB Go Driver
	// https://go.mongodb.org/mongo-driver
	ctx := context.TODO()
	//uri := "mongodb://databaseAdmin:di1CsU4foBvBixjLtp@localhost:27017"

	clientOpts := options.Client().ApplyURI(MongoConnectionString())
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		return err
	}
	defer func() { _ = client.Disconnect(ctx) }()

	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err := client.Disconnect(ctx); err != nil {
			log.Fatal(err)
		}
	}()

	// Find data
	coll := client.Database("miller").Collection("profiles")
	_, err = coll.Find(ctx, bson.D{})
	if err != nil {
		log.Fatal(err)
	}

	return nil
}
