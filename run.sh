#!/bin/bash

set -e

rm ./ssh/* || true

# Generate SSH keys, host and user certificates
ssh-keygen -t rsa -b 4096 -f ./ssh/host_ca -N "" -C host_ca
ssh-keygen -t rsa -b 4096 -f ./ssh/user_ca -N "" -C user_ca
ssh-keygen -s ./ssh/host_ca -I localhost -h -n localhost -V +52w ./ssh/host_ca.pub
ssh-keygen -s ./ssh/user_ca -I bob@example.com -n root -V +1d ./ssh/user_ca.pub

# Build the Docker images
docker build -t ubuntu2204-ssh -f Dockerfile-ubuntu-2204 .
docker build -t centos7-ssh -f Dockerfile-centos7 .

# Run Go SSH server in the background
go run main.go &

# Run the Ubuntu container with OpenSSH 8.9 - no issue here
docker run -it --rm --network=host -v $(pwd):/app ubuntu2204-ssh ssh -vvv -p2222 -o IdentityFile="/app/ssh/user_ca" -o CertificateFile="/app/ssh/user_ca-cert.pub" root@localhost || true

go run main.go &

# Run the CentOS container with OpenSSH 7.4 - older client fails
docker run -it --rm --network=host -v $(pwd):/app centos7-ssh ssh -vvv -p2222 -o IdentityFile="/app/ssh/user_ca" -o CertificateFile="/app/ssh/user_ca-cert.pub" root@localhost || true

