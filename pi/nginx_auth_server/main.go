package main

import (
	"crypto/ed25519"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v4"
)

var (
	pubKey ed25519.PublicKey
	logger *log.Logger
)

func loadPublicKey(path string) (ed25519.PublicKey, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	block, _ := pem.Decode(raw)
	if block == nil { // maybe raw DER
		if len(raw) == ed25519.PublicKeySize {
			return ed25519.PublicKey(raw), nil
		}
		return nil, fmt.Errorf("key is not PEM-encoded and is not 32 bytes")
	}
	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse PKIX: %w", err)
	}
	edPub, ok := pub.(ed25519.PublicKey)
	if !ok {
		return nil, fmt.Errorf("not an Ed25519 key")
	}
	return edPub, nil
}

func parseAndValidate(jwtString string) (map[string]interface{}, error) {
	parsed, err := jwt.Parse(jwtString, func(t *jwt.Token) (interface{}, error) {
		if t.Method.Alg() != "EdDSA" {
			return nil, errors.New("wrong alg")
		}
		return pubKey, nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := parsed.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("claims are not MapClaims")
	}
	return map[string]interface{}(claims), nil
}

func handler(w http.ResponseWriter, r *http.Request) {
	// logRequest(r) // Commented out
	auth := r.Header.Get("Authorization")
	if auth == "" {
		// logger.Printf("⚠️  no token received") // Commented out
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}
	tokenStr := strings.TrimSpace(auth[len("Bearer "):])
	claims, err := parseAndValidate(tokenStr)
	if err != nil {
		// logger.Printf("⚠️  token rejected: %v", err) // Commented out
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}
	// logger.Printf("Claims: %+v", claims) // Commented out
	w.WriteHeader(http.StatusOK)
}

func main() {
	f, err := os.OpenFile(
		"auth_server.log",
		os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0640)
	if err != nil {
		log.Fatalf("could not open audit log file: %v", err)
	}
	defer f.Close()

	logger = log.New(f, "", log.LstdFlags|log.Lshortfile)

	var errLoad error
	pubKey, errLoad = loadPublicKey("/etc/auth/client_public.pem")
	if errLoad != nil {
		logger.Fatalf("could not load public key: %v", errLoad)
	}

	http.HandleFunc("/", handler)
	addr := ":9000"
	logger.Printf("Starting auth server on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Fatalf("ListenAndServe: %v", err)
	}
}
