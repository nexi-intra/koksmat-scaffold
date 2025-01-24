package utils

import "strconv"

func StrToInt(s string) int64 {
	i, _ := strconv.ParseInt(s, 0, 64)
	return i
}
