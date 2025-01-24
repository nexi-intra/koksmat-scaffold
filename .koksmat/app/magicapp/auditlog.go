package magicapp

import (
	"context"

	mgm "github.com/kamva/mgm/v3"
	"go.mongodb.org/mongo-driver/event"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const AuditlogCollectionName = "audit_log"

type AuditLog struct {
	mgm.DefaultModel `bson:",inline"`
	Database         string `json:"database"`
	AppId            string `json:"appid"`
	Subject          string `json:"subject"`
}

type AuditLogSum struct {
	mgm.DefaultModel `bson:",inline"`
	Date             string `json:"date"`
	Subject          string `json:"subject"`
	Hour             string `json:"hour"`
	Count            int    `json:"count"`
}

type PowerShellLog struct {
	mgm.DefaultModel `bson:",inline"`
	Database         string `json:"database"`
	AppId            string `json:"appid"`
	Subject          string `json:"subject"`
	ScriptName       string `json:"scriptname"`
	ScriptSrc        string `json:"scriptsrc"`
	Input            string `json:"input"`
	Output           string `json:"result"`
	HasError         bool   `json:"haserror"`
	Console          string `json:"console"`
}

type PowerShellLogMetadata struct {
	mgm.DefaultModel `bson:",inline"`
	Database         string `json:"database"`
	AppId            string `json:"appid"`
	Subject          string `json:"subject"`
	ScriptName       string `json:"scriptname"`

	HasError bool `json:"haserror"`
}

// func (model *PowerShellLog) CollectionName() string {
// 	return AuditlogCollectionName

// }
func (auditLog *PowerShellLog) Collection() *mgm.Collection {
	// Create new client

	client, err := mgm.NewClient(options.Client().ApplyURI(MongoConnectionString()))
	if err != nil {
		panic(err)
	}
	// Get the model's db
	db := client.Database("magicbox")
	// return the model's custom collection
	return mgm.NewCollection(db, "audit_log")
}

func (auditLog *AuditLogSum) Collection() *mgm.Collection {
	// Create new client

	cmdMonitor := &event.CommandMonitor{
		Started: func(_ context.Context, evt *event.CommandStartedEvent) {
			// log.Print(evt.Command)
		},
	}

	client, err := mgm.NewClient(options.Client().ApplyURI(MongoConnectionString()).SetMonitor(cmdMonitor))
	if err != nil {
		panic(err)
	}
	// Get the model's db
	db := client.Database("magicbox")
	// return the model's custom collection
	return mgm.NewCollection(db, "audit_log_sums")
}

func (auditLog *AuditLog) Collection() *mgm.Collection {
	// Create new client

	client, err := mgm.NewClient(options.Client().ApplyURI(MongoConnectionString()))
	if err != nil {
		panic(err)
	}
	// Get the model's db
	db := client.Database("magicbox")
	// return the model's custom collection
	return mgm.NewCollection(db, "audit_log")
}

func LogAudit(app string, subject string) {

	newRecord := &AuditLog{
		Database: DatabaseName(),
		AppId:    app,
		Subject:  subject,
	}

	mgm.Coll(newRecord).Create(newRecord)

}

func LogPowerShell(app string, scriptName string, scriptSrc string, input string, output string, hasError bool, console string) {

	newRecord := &PowerShellLog{
		DefaultModel: mgm.DefaultModel{},
		Database:     DatabaseName(),
		AppId:        app,
		Subject:      "powershell",
		ScriptName:   scriptName,
		ScriptSrc:    scriptSrc,
		Input:        input,
		Output:       output,
		HasError:     hasError,
		Console:      console,
	}

	err := mgm.Coll(newRecord).Create(newRecord)
	if err != nil {
		panic(err)
	}

}

// func GetAuditLogs(dateString string, hourString string) ([]*PowerShellLogMetadata, error) {
// 	ar := strings.Split(dateString, "-")
// 	year, _ := strconv.Atoi(ar[0])
// 	month, _ := strconv.Atoi(ar[1])
// 	day, _ := strconv.Atoi(ar[2])
// 	hour, _ := strconv.Atoi(hourString)

// 	from := time.Date(year, time.Month(month), day, hour, 0, 0, 0, time.UTC)
// 	to := from.Add(time.Hour * 1)
// 	filter := bson.D{
// 		{"$and",
// 			bson.A{
// 				bson.D{{"subject", "powershell"}},
// 				bson.D{
// 					{"created_at",
// 						bson.D{
// 							{"$gte", from},
// 							{"$lt", to},
// 						},
// 					},
// 				},
// 			},
// 		},
// 	}

// 	data, err := GetFiltered[*PowerShellLog](&PowerShellLog{}, filter)
// 	if err != nil {
// 		return nil, err
// 	}
// 	records := []*PowerShellLogMetadata{}
// 	for _, item := range data {
// 		metaData := PowerShellLogMetadata{
// 			DefaultModel: item.DefaultModel,
// 			Database:     item.Database,
// 			AppId:        item.AppId,
// 			Subject:      item.Subject,
// 			ScriptName:   item.ScriptName,
// 			HasError:     item.HasError,
// 		}

// 		records = append(records, &metaData)
// 	}
// 	return records, nil
// }

// func GetAuditLogSummarys() ([]*AuditLogSum, error) {
// 	return GetAll[*AuditLogSum](&AuditLogSum{})
// }

// func GetPowerShellLog(id string) (*PowerShellLog, error) {
// 	return FindOneById[*PowerShellLog](&PowerShellLog{}, id)
// }

// func Aggregate() error {
// 	ctx := context.TODO()
// 	pipeline := bson.A{
// 		bson.D{
// 			{"$addFields",
// 				bson.D{
// 					{"datepart",
// 						bson.D{
// 							{"$substr",
// 								bson.A{
// 									"$created_at",
// 									0,
// 									10,
// 								},
// 							},
// 						},
// 					},
// 					{"hour",
// 						bson.D{
// 							{"$substr",
// 								bson.A{
// 									"$created_at",
// 									11,
// 									2,
// 								},
// 							},
// 						},
// 					},
// 				},
// 			},
// 		},
// 		bson.D{
// 			{"$group",
// 				bson.D{
// 					{"_id",
// 						bson.A{
// 							"$datepart",
// 							"$subject",
// 							"$hour",
// 						},
// 					},
// 					{"subject", bson.D{{"$first", "$subject"}}},
// 					{"date", bson.D{{"$first", "$datepart"}}},
// 					{"hour", bson.D{{"$first", "$hour"}}},
// 					{"count", bson.D{{"$sum", 1}}},
// 				},
// 			},
// 		},
// 		bson.D{{"$project", bson.D{{"_id", 0}}}},
// 		bson.D{{"$out", "audit_log_sums"}},
// 	}

// 	_, err := mgm.Coll(&AuditLog{}).Aggregate(ctx, pipeline)
// 	return err

// }
