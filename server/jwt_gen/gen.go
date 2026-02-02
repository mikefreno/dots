package main

import (
	"crypto/ed25519"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
)

// loadEd25519PrivateKey reads a PEM file that contains an Ed25519 private key.
func loadEd25519PrivateKey(path string) (ed25519.PrivateKey, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read key file: %w", err)
	}

	block, _ := pem.Decode(b)
	if block == nil {
		return nil, fmt.Errorf("failed to PEM‑decode key")
	}

	// The key can be PKCS#8 or just raw 32‑byte Ed25519
	// x509.ParsePKCS8PrivateKey will handle the most common format
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		// try raw 32‑byte format
		if len(block.Bytes) == ed25519.PrivateKeySize {
			return ed25519.PrivateKey(block.Bytes), nil
		}
		return nil, fmt.Errorf("parse PKCS#8 key: %w", err)
	}

	priv, ok := key.(ed25519.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("key is not Ed25519")
	}
	return priv, nil
}

func main() {
	priv, err := loadEd25519PrivateKey("client_private.pem")
	if err != nil {
		log.Fatalf("could not load private key: %v", err)
	}

	// Build a JWT with whatever claims you want.
	// NOTE: no "exp" claim – the token will never expire.
	claims := jwt.MapClaims{
		"iss":  "ollama-direct",   // e.g. your service name
		"sub":  "mike",            // subject / principal
		"role": "admin",           // arbitrary data
		"iat":  time.Now().Unix(), // issued at (optional)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodEdDSA, claims)

	// Sign the token with the private key
	signed, err := token.SignedString(priv)
	if err != nil {
		log.Fatalf("could not sign token: %v", err)
	}

	fmt.Println(signed)
}
