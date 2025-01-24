package magicapp

import (
	"context"
	"fmt"
	"log"
	"os"
	"path"
	"strings"

	mgm "github.com/kamva/mgm/v3"
	"github.com/spf13/viper"
	"go.mongodb.org/mongo-driver/event"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type environmentStack struct {
	environmentPath string
	tenantname      string
	environment     []string
}

func fileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}

func ReadEnvironmentVariables(filepath string) ([]string, error) {

	if !fileExists(filepath) {
		return nil, nil
	}
	fileContent, err := os.ReadFile(filepath)
	if err != nil {
		return nil, err
	}
	return strings.Split(string(fileContent), "\n"), nil
}

func getEnvironmentStack(endPath string, index int, stack []environmentStack) ([]environmentStack, error) {

	if endPath == "" {
		return nil, fmt.Errorf("You cannot start from the root")
	}

	elems := strings.Split(endPath, "/")
	startPath := "/"
	if index == len(elems) {
		startPath = endPath
	} else {
		if index > 0 {
			startPath = fmt.Sprintf("%s", strings.Join(elems[:index+1], "/"))
		}
	}
	envPath := path.Join(startPath, ".env")
	if fileExists(envPath) {
		env, err := ReadEnvironmentVariables(envPath)
		if err != nil {
			return nil, err
		}
		stack = append(stack, environmentStack{environmentPath: envPath, environment: env})

	}

	if startPath == endPath {
		return stack, nil
	}
	return getEnvironmentStack(endPath, index+1, stack)

}

func MakeEnvFile(cwd string) error {

	path := path.Join(cwd, ".env-test")
	stack, err := getEnvironmentStack(cwd, 0, []environmentStack{})
	if err != nil {
		return err
	}
	env := ""
	for _, item := range stack {
		env += fmt.Sprintf(`
#------------------------------------	
# %s
#------------------------------------	
%s	
		`, item.environmentPath, strings.Join(item.environment, "\n"))

	}
	err = os.WriteFile(path, []byte(env), 0644)
	return nil
}

func MongoConnectionString() string {
	s1 := viper.GetString("MONGODB")
	s2 := "mongodb://databaseAdmin:di1CsU4foBvBixjLtp@localhost:27017"
	if s1 != s2 {
		// log.Println("MONGODB DIFF")
	}
	return s2
	//return viper.GetString("MONGODB")
	// databaseUrl := strings.ReplaceAll(viper.GetString("DATABASEURL"), "mongodb://", "")
	// connectionString := "mongodb://" + viper.GetString("DATABASEADMIN") + ":" + viper.GetString("DATABASEPASSWORD") + "@" + databaseUrl
	// return connectionString
}

func DatabaseName() string {
	return viper.GetString("DATABASE")
}

func Setup(envPath string) {
	viper.SetConfigFile(envPath)
	viper.AutomaticEnv()
	viper.ReadInConfig()
	cmdMonitor := &event.CommandMonitor{
		Started: func(_ context.Context, evt *event.CommandStartedEvent) {
			// log.Print(evt.Command)
		},
	}
	db := DatabaseName()
	err := mgm.SetDefaultConfig(nil, db, options.Client().ApplyURI(MongoConnectionString()).SetMonitor(cmdMonitor))
	if err != nil {
		log.Println(err)
	}
}
