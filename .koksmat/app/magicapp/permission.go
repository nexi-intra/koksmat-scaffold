package magicapp

import (
	"strings"

	"github.com/gobwas/glob"
)

func HasPermission(mask string, databaseName string) bool {
	var g glob.Glob

	if mask == "*" {
		return true
	}

	tags := strings.Split(mask, " ")

	for _, tag := range tags {
		subtags := strings.Split(tag, ":")
		if len(subtags) == 2 {
			values := strings.Split(subtags[1], ";")
			for _, value := range values {

				switch subtags[0] {
				case "database":
					g = glob.MustCompile(value, '.')
					return g.Match(databaseName)

				default:
					return false
				}

			}

		}
	}
	return false

}
