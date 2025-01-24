package magicapp

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSuperAccess(t *testing.T) {
	hasAccess := HasPermission("*", "whateverdatabase")
	assert.True(t, hasAccess, "* should have access to everything")

	hasAccess = HasPermission("database:whateverdatabase", "whateverdatabase")
	assert.True(t, hasAccess, "database:whateverdatabase should have access to whateverdatabase")

	hasAccess = HasPermission("database:whateverdatabase", "whateverdatabase2")
	assert.False(t, hasAccess, "database:whateverdatabase should not have access to whateverdatabase2")

	hasAccess = HasPermission("database:m365*", "m365x65867376")
	assert.True(t, hasAccess, "database:m365* should have access to m365x65867376")

	hasAccess = HasPermission("database:christianiabpos", "m365x65867376")
	assert.False(t, hasAccess, "database:christianiabpos should not have access to m365x65867376")

}
