package main

import (
	"crypto/ed25519"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v4"
)

var (
	pubKey ed25519.PublicKey
	logger *log.Logger
)

// logRequest logs the request line and every header.
func logRequest(r *http.Request) {
	logger.Printf("=== REQUEST ===")
	logger.Printf("%s %s %s", r.Method, r.RequestURI, r.Proto)
	for k, v := range r.Header {
		for _, h := range v {
			logger.Printf("Header: %s=%s", k, h)
		}
	}
}

// loadPublicKey reads an Ed25519 public key from a PEM file.
func loadPublicKey(path string) (ed25519.PublicKey, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	block, _ := pem.Decode(raw)
	if block == nil {
		// maybe it's already raw DER
		if len(raw) == ed25519.PublicKeySize {
			return ed25519.PublicKey(raw), nil
		}
		return nil, fmt.Errorf("key is not PEM‑encoded and is not 32 bytes")
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

// parseAndValidate verifies the token against the public key
// and returns the claims map.
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

// tokenFromRequest looks for a JWT in either
//
//	a) Authorization: Bearer <jwt>
//	b) X‑Original‑Uri → …?token=<jwt>
//
// It returns the raw token string and the *source* (header/query).
func tokenFromRequest(r *http.Request) (string, string, error) {
	// 1️⃣  Try Authorization header first
	if auth := r.Header.Get("Authorization"); auth != "" {
		const bearer = "Bearer "
		if !strings.HasPrefix(auth, bearer) {
			return "", "", errors.New("Authorization header is not a Bearer token")
		}
		return strings.TrimSpace(auth[len(bearer):]), "header", nil
	}

	// 2️⃣  Fall back to the old X‑Original‑Uri path
	origURI := r.Header.Get("X-Original-Uri")
	if origURI == "" {
		return "", "", errors.New("no token found in header or X-Original-Uri")
	}
	u, err := url.Parse(origURI)
	if err != nil {
		return "", "", fmt.Errorf("invalid X-Original-Uri: %w", err)
	}
	tokenStr := u.Query().Get("token")
	if tokenStr == "" {
		return "", "", errors.New("token missing in X-Original-Uri")
	}
	return tokenStr, "query", nil
}

// handler validates the JWT and writes the proper response.
func handler(w http.ResponseWriter, r *http.Request) {
	logRequest(r)

	token, src, err := tokenFromRequest(r)
	if err != nil {
		logger.Printf("⚠️  token missing / malformed (%s): %v", src, err)
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	claims, err := parseAndValidate(token)
	if err != nil {
		logger.Printf("⚠️  token rejected (%s): %v", src, err)
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	logger.Printf("✅  Token used (%s): %s", src, token)
	logger.Printf("Claims: %+v", claims)

	w.WriteHeader(http.StatusOK)
}

// main opens the audit log, loads the key, and starts the HTTP server.
func main() {
	// 1️⃣  Open the audit‑log file (create it if it does not exist)
	f, err := os.OpenFile(
		"auth_server.log",
		os.O_CREATE|os.O_WRONLY|os.O_APPEND,
		0640,
	)
	if err != nil {
		log.Fatalf("could not open audit log file: %v", err)
	}
	defer f.Close()

	// 2️⃣  Create a logger that writes to that file
	logger = log.New(f, "", log.LstdFlags|log.Lshortfile)

	// 3️⃣  Load the public key used for validation
	pubKey, err = loadPublicKey("/etc/auth/client_public.pem")
	if err != nil {
		logger.Fatalf("could not load public key: %v", err)
	}

	// 4️⃣  Wire the handler and start listening
	http.HandleFunc("/", handler)
	addr := ":9000"
	logger.Printf("Starting auth server on %s", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Fatalf("ListenAndServe: %v", err)
	}
}
