package main

import (
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v4"
)

// ----- 1️⃣  Load the secret ------------------------------------
var jwtSecret []byte

func init() {
	// Read once at start‑up.  Change the path if you moved the file.
	const secretFile = "/etc/auth/secret.key"

	b, err := os.ReadFile(secretFile)
	if err != nil {
		log.Fatalf("❌  cannot read secret file %s: %v", secretFile, err)
	}
	jwtSecret = []byte(strings.TrimSpace(string(b)))
}

// ----- 2️⃣  Custom claims structure (if you need them) ------------
type CustomClaims struct {
	Sub   string   `json:"sub"`
	Roles []string `json:"roles,omitempty"`
	jwt.RegisteredClaims
}

// ----- 3️⃣  Verify the token & extract the claims ---------------
func parseAndValidate(tokenString string) (*CustomClaims, error) {
	if tokenString == "" {
		return nil, fmt.Errorf("token string is empty")
	}

	// Parse the JWT – we explicitly say “expect HS256”
	token, err := jwt.ParseWithClaims(
		tokenString,
		&CustomClaims{}, // the claims struct you want
		func(token *jwt.Token) (interface{}, error) {
			// 1️⃣  Make sure the signing method is what you expect
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			// 2️⃣  Return the secret for the validator to use
			return jwtSecret, nil
		},
	)

	if err != nil {
		return nil, fmt.Errorf("token parse error: %w", err)
	}

	// 4️⃣  The token is now verified; cast the claims
	if claims, ok := token.Claims.(*CustomClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token (claims could not be parsed)")
}
