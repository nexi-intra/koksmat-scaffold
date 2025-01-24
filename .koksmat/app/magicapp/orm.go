package magicapp

import (
	"context"
	"errors"
	"log"
	"time"

	mgm "github.com/kamva/mgm/v3"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

const recordNotFound = "not found in database"

func FindOneById[M mgm.Model](record M,
	id string) (foundRecord M, err error) {
	objectId, err := primitive.ObjectIDFromHex(id)
	dbResult := mgm.Coll(record).FindOne(context.Background(), bson.M{"_id": objectId})
	dbErr := dbResult.Err()
	if dbErr != nil {

		return record, errors.New(recordNotFound)
	}
	dbResult.Decode(record)
	return record, nil

}

func FindOne[M mgm.Model](record M,
	filter bson.D) (foundRecord M, err error) {
	dbResult := mgm.Coll(record).FindOne(context.Background(), filter)
	dbErr := dbResult.Err()
	if dbErr != nil {

		return record, errors.New(recordNotFound)
	}
	dbResult.Decode(record)
	return record, nil

}

func DeleteOne[M mgm.Model](record M,
	filter bson.D) (err error) {
	dbResult := mgm.Coll(record).FindOne(context.Background(), filter)
	dbErr := dbResult.Err()
	if dbErr != nil {
		return errors.New(recordNotFound)
	}
	err = mgm.Coll(record).Delete(record)
	return nil

}

func UpdateOne[M mgm.Model](
	record M,
	filter bson.D,
	interact func(record M) error,

) (updateRecord M, err error) {

	dbResult := mgm.Coll(record).FindOne(context.Background(), filter)
	dbErr := dbResult.Err()
	if dbErr != nil {
		return record, errors.New(recordNotFound)
	}
	dbResult.Decode(record)

	err = interact(record)

	if err != nil {
		log.Println(err)
		return record, err
	}

	err = mgm.Coll(record).Update(record)
	if err != nil {
		log.Println(err)
		return record, err
	}

	return record, nil

}

func CreateOne[M mgm.Model](record M, interact func() (M, error)) (newR *M, err error) {

	newRecord, err := interact()
	if err != nil {
		return nil, err

	}

	err = mgm.Coll(record).Create(newRecord)
	if err != nil {
		log.Println(err)
		return nil, err
	}

	return &newRecord, nil
}

func CreateOrUpdate[M mgm.Model](
	record M,
	filter bson.D,
	create func() (M, error),
	update func(record M) error) (r *M, err error) {

	foundRecord, err := FindOne(record, filter)

	if err != nil {
		createdRecord, err := CreateOne[M](record, create)
		return createdRecord, err
	} else {

		err = update(foundRecord)
		if err != nil {
			return nil, err
		}

		err = mgm.Coll(record).Update(foundRecord)
		if err != nil {

			return nil, err
		}
		return &foundRecord, nil
	}

}

func GetAll[T mgm.Model](record T) (result []T, err error) {

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	records := []T{}
	defer cancel()

	results, err := mgm.Coll(record).Find(context.TODO(), bson.M{})
	if err != nil {

		return nil, err
	}
	defer results.Close(ctx)
	for results.Next(ctx) {
		var record T
		if err = results.Decode(&record); err != nil {
			return nil, err
		}

		records = append(records, record)
	}

	return records, nil
}

func GetFiltered[T mgm.Model](record T, filter interface{}) (result []T, err error) {

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	records := []T{}
	defer cancel()

	results, err := mgm.Coll(record).Find(context.TODO(), filter)
	if err != nil {

		return nil, err
	}
	defer results.Close(ctx)
	for results.Next(ctx) {
		var record T
		if err = results.Decode(&record); err != nil {
			return nil, err
		}

		records = append(records, record)
	}

	return records, nil
}
