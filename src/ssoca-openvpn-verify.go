package main

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"os"
	"time"
)

func main() {
	if len(os.Args) != 4 {
		panic("missing arguments")
	}

	if os.Args[2] != "0" {
		// don't pay attention to chain certificates
		return
	} else if os.Getenv("trusted_ip") == os.Getenv("untrusted_ip") && os.Getenv("trusted_port") == os.Getenv("untrusted_port") {
		// renegotiation of existing connection
		return
	}

	validity, err := time.ParseDuration(os.Args[1])
	if err != nil {
		panic(err)
	}

	peerCertPath := os.Getenv("peer_cert")
	if peerCertPath == "" {
		panic("missing peer_cert environment variable")
	}

	peerCertBytes, err := ioutil.ReadFile(peerCertPath)
	if err != nil {
		panic(err)
	}

	peerCertPEM, _ := pem.Decode(peerCertBytes)
	if peerCertPEM == nil {
		panic("failed decoding certificate")
	}

	peerCert, err := x509.ParseCertificate(peerCertPEM.Bytes)
	if err != nil {
		panic(err)
	}

	expiration := peerCert.NotBefore.Add(validity)
	now := time.Now()

	if expiration.Unix() > now.Unix() {
		// freshly signed
		return
	}

	diff := now.Sub(expiration)
	fmt.Println(fmt.Sprintf("tls-verify: failed validity check: certificate '%s' was issued at '%s' (invalid %s ago)", peerCert.Subject.CommonName, peerCert.NotBefore, diff))

	os.Exit(1)
}
