package main

import (
	"fmt"
	"log"
	"net/http"
	"net/url"
)

func logRequest(r *http.Request) {
	log.Printf("%s %s %s", r.Method, r.URL.RequestURI(), r.Proto)

	// Headers
	for k, v := range r.Header {
		for _, h := range v {
			log.Printf("%s: %s", k, h)
		}
	}

}

// handler runs for every request; it logs the request and does the auth check.
func handler(w http.ResponseWriter, r *http.Request) {
	//logRequest(r)

	// 1️⃣  Pull the token – you can also pull it from a header
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

	// 3️⃣  (Optional)  Use the claims in your business logic
	//    e.g. user ID is claims.Sub, roles are claims.Roles
	fmt.Fprintf(w, "✅  Auth OK – user=%s, roles=%v\n", claims.Sub, claims.Roles)
}

func main() {
	http.HandleFunc("/", handler)

	addr := ":9000"
	log.Printf("Starting auth server on %s\n", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("ListenAndServe: %v", err)
	}
}
