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

	"github.com/golang-jwt/jwt/v4"
)

var pubKey ed25519.PublicKey

func logRequest(r *http.Request) {
	log.Printf("%s %s %s", r.Method, r.URL.RequestURI(), r.Proto)

	// Headers
	for k, v := range r.Header {
		for _, h := range v {
			log.Printf("%s: %s", k, h)
		}
	}

}

func loadPublicKey(path string) (ed25519.PublicKey, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}

	// If the file is PEM‑encoded (most OpenSSL outputs are PEM)
	block, _ := pem.Decode(raw)
	if block == nil {
		// maybe it’s already the raw DER file – try to use it directly
		if len(raw) == ed25519.PublicKeySize {
			return ed25519.PublicKey(raw), nil
		}
		return nil, fmt.Errorf("key is not PEM‑encoded and is not 32 bytes")
	}

	// block.Bytes contains the DER‑encoded SubjectPublicKeyInfo
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
		// 1️⃣ Make sure the alg is EdDSA
		if t.Method.Alg() != "EdDSA" {
			return nil, errors.New("wrong alg")
		}
		// 2️⃣ Provide the public key that should be used for verification
		return pubKey, nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := parsed.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("claims are not a MapClaims")
	}

	return map[string]interface{}(claims), nil
}

func handler(w http.ResponseWriter, r *http.Request) {

	origURI := r.Header.Get("X-Original-Uri")
	if origURI == "" {
		http.Error(w, "token missing", http.StatusUnauthorized)
		return
	}

	u, err := url.Parse(origURI)
	if err != nil {
		http.Error(w, "token parse error", http.StatusUnauthorized)
		return
	}

	tokenStr := u.Query().Get("token")
	log.Printf(tokenStr)

	claims, err := parseAndValidate(tokenStr)
	if err != nil {
		log.Printf("⚠️  token rejected: %v", err)
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}
	log.Print(claims)
}

func main() {
	var err error
	pubKey, err = loadPublicKey("/etc/auth/client_public.pem")
	if err != nil {
		panic(err)
	}

	http.HandleFunc("/", handler)

	addr := ":9000"
	log.Printf("Starting auth server on %s\n", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("ListenAndServe: %v", err)
	}
}
