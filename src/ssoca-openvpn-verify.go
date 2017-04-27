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
		// don't pay attention to chained certificates
		return
	}

	trustedIP, trustedPort := os.Getenv("trusted_ip"), os.Getenv("trusted_port")
	untrustedIP, untrustedPort := os.Getenv("untrusted_ip"), os.Getenv("untrusted_port")

	if trustedIP == untrustedIP && trustedPort == untrustedPort {
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

	actual := peerCert.NotBefore.Add(validity)
	now := time.Now()

	if actual.Unix() > now.Unix() {
		// freshly signed
		return
	}

	diff := now.Sub(actual)
	fmt.Println(fmt.Sprintf("tls-verify: failed validity check: certificate '%s' was issued at '%s' (%s ago)", peerCert.Subject.CommonName, peerCert.NotBefore, diff))

	os.Exit(1)
}
