package magicapp

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	jwtauth "github.com/go-chi/jwtauth/v5"
	jwt "github.com/golang-jwt/jwt/v5"
	"github.com/swaggest/usecase"
	"github.com/swaggest/usecase/status"
)

var authenticationTag = "Authentication"

var mySigningKey = []byte("AllYourBase")

func IssueIdToken(appName string, appSecret string) (tokenString string, err error) {

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"app": appName,
		"key": appSecret,
		"nbf": 234,
	})

	tokenString, err = token.SignedString(mySigningKey)

	return tokenString, err
}

func IssueAccessToken(idToken string) (tokenString string, err error) {

	app, secret, err := ParseIdToken(idToken)
	valid, permissions := Authenticate(app, secret)
	if !valid {
		return "", errors.New("you cannot get an access token with that app key")
	}
	t := time.Now()
	t = t.Add(time.Minute * 10)
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"app":         app,
		"permissions": permissions,
		"expireUC":    t.UTC(),
		"expire":      t.Unix(),
	})
	LogAudit(app, permissions)
	tokenString, err = token.SignedString(mySigningKey)
	return tokenString, nil
}

func signin() usecase.Interactor {
	type SigninRequest struct {
		AppKey string `json:"appkey" binding:"required"`
	}
	type SigninResponse struct {
		AccessToken string `json:"token" binding:"required"`
	}
	u := usecase.NewInteractor(func(ctx context.Context, input SigninRequest, output *SigninResponse) error {

		tokenString, err := IssueAccessToken(input.AppKey)
		*&output.AccessToken = tokenString
		return err

	})

	u.SetTitle("Authenticating app")
	u.SetDescription(`

You need an ´appkey´  to access the API. The ´appkey´  is issue by [niels.johansen@nexigroup.com](mailto:niels.johansen@nexigroup.com).

Use the ´appkey´  to get an access token through the /v1/authorize end point. The access token is valid for 10 minutes.

Pass the access token in the Authorization header as a Bearer token to access the API.


`)
	u.SetExpectedErrors(status.InvalidArgument)
	u.SetTags(authenticationTag)
	return u
}

func ParseIdToken(tokenString string) (appName string, appSecret string, err error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Don't forget to validate the alg is what you expect:
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}

		// hmacSampleSecret is a []byte containing your secret, e.g. []byte("my_secret_key")
		return mySigningKey, nil
	})
	if err != nil {

		return "", "", err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		app := fmt.Sprint(claims["app"])
		key := fmt.Sprint(claims["key"])
		return app, key, nil

	} else {

		return "", "", errors.New("Not implemented")
	}

}

func havePermissions(permissions string) bool {
	if permissions == "*" {
		return true
	}

	tags := strings.Split(permissions, " ")
	databaseName := DatabaseName()
	for _, tag := range tags {
		subtags := strings.Split(tag, ":")
		if len(subtags) == 2 {
			values := strings.Split(subtags[1], ",")
			for _, value := range values {

				switch subtags[0] {
				case "database":
					if value == databaseName {
						return true
					}

				default:
					return false
				}

			}

		}
	}
	return false
}

// Authenticator is a default authentication middleware to enforce access from the
// Verifier middleware request context values. The Authenticator sends a 401 Unauthorized
// response for any unverified tokens and passes the good ones through. It's just fine
// until you decide to write something similar and customize your client response.
func Authenticator(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		authorization := Authorization{AppId: "DEBUG", Permissions: "*"}
		ctx := context.WithValue(r.Context(), "auth", "*")
		next.ServeHTTP(w, r.WithContext(ctx))
		log.Println("DEBUG MODE", authorization.AppId, authorization.Permissions)
		return
		tokenString := jwtauth.TokenFromHeader(r)
		// Parse takes the token string and a function for looking up the key. The latter is especially
		// useful if you use multiple keys for your application.  The standard is to use 'kid' in the
		// head of the token to identify which key to use, but the parsed token (head and claims) is provided
		// to the callback, providing flexibility.
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			// Don't forget to validate the alg is what you expect:
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
			}

			// hmacSampleSecret is a []byte containing your secret, e.g. []byte("my_secret_key")
			return mySigningKey, nil
		})
		if err != nil {
			http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {

			app := fmt.Sprint(claims["app"])
			permissions := fmt.Sprint(claims["permissions"])
			expire, err := strconv.ParseFloat(fmt.Sprint(claims["expire"]), 0)
			now := float64(time.Now().Unix())

			if err != nil || expire < now {
				log.Println("Token expired")
				http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
				return
			}

			hasPermission := HasPermission(permissions, DatabaseName())

			if !hasPermission {
				log.Println("No permission")
				http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
				return
			}
			//log.Println("Permission granted")
			// Token is authenticated, pass it through
			authorization := Authorization{AppId: app, Permissions: permissions}
			ctx := context.WithValue(r.Context(), "auth", authorization)
			next.ServeHTTP(w, r.WithContext(ctx))
		} else {
			http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
			return
		}

	})
}
