#!/bin/bash
set -e

OUTPUT_DIR=/cert

openssl genrsa -out "${OUTPUT_DIR}/ca-key.pem" 2048

openssl req -new -x509 -nodes -days 3650 \
  -key "${OUTPUT_DIR}/ca-key.pem" \
  -subj "/C=XX/ST=State/L=City/O=Organization/CN=RootCA" \
  -out "${OUTPUT_DIR}/ca.pem"

openssl req -newkey rsa:2048 -nodes \
  -keyout "${OUTPUT_DIR}/server-key.pem" \
  -subj "/C=XX/ST=State/L=City/O=Organization/CN=pxc-node" \
  -out "${OUTPUT_DIR}/server-req.pem"

openssl x509 -req -in "${OUTPUT_DIR}/server-req.pem" -days 3650 \
  -CA "${OUTPUT_DIR}/ca.pem" \
  -CAkey "${OUTPUT_DIR}/ca-key.pem" \
  -set_serial 01 \
  -out "${OUTPUT_DIR}/server-cert.pem"

openssl req -newkey rsa:2048 -nodes \
  -keyout "${OUTPUT_DIR}/client-key.pem" \
  -subj "/C=XX/ST=State/L=City/O=Organization/CN=pxc-client" \
  -out "${OUTPUT_DIR}/client-req.pem"

openssl x509 -req -in "${OUTPUT_DIR}/client-req.pem" -days 3650 \
  -CA "${OUTPUT_DIR}/ca.pem" \
  -CAkey "${OUTPUT_DIR}/ca-key.pem" \
  -set_serial 02 \
  -out "${OUTPUT_DIR}/client-cert.pem"

chmod 600 "${OUTPUT_DIR}"/*.pem

openssl verify -CAfile "${OUTPUT_DIR}/ca.pem" \
  "${OUTPUT_DIR}/server-cert.pem" \
  "${OUTPUT_DIR}/client-cert.pem"
