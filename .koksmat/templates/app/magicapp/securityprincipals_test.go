package magicapp

import (
	"log"
	"testing"
)

func TestHelloName(t *testing.T) {

	key, hash, _ := IssueAccessKey("tester")
	log.Println(key)
	log.Println(hash)
	valid, newHash := Authenticate("tester", key)
	log.Println(newHash)
	if !valid {
		t.Fatalf("Didn't work")
	}
}
