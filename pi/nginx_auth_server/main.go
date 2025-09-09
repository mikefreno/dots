package main

import (
	"log"
	"net/http"
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
	logRequest(r)

	// Grab the token from the query string
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, "token missing", http.StatusUnauthorized)
		return
	}

}

func main() {
	http.HandleFunc("/", handler)

	addr := ":9000"
	log.Printf("Starting auth server on %s\n", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("ListenAndServe: %v", err)
	}
}
