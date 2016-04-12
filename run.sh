#!/bin/bash

if ! [ -f $DIR_NGROK/.built ]; then
	# generate certification
	pushd $DIR_NGROK
	openssl genrsa -out base.key 2048
	openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
	openssl genrsa -out server.key 2048
	openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
	openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt
	cp base.pem assets/client/tls/ngrokroot.crt

	# build ngrok daemon
	make release-server

	cp bin/ngrokd /usr/local/bin/
	cp server.key server.crt /root

	# build ngrok client
	GOOS="linux" GOARCH="amd64" make release-client
	GOOS="darwin" GOARCH="amd64" make release-client

	cp bin/ngrok /usr/local/bin/ngrok-linux
	cp bin/darwin_amd64/ngrok /usr/local/bin/ngrok-darwin

	touch $DIR_NGROK/.built
fi

if [ -d /ngrok ]; then
	cp /usr/local/bin/ngrok-linux /ngrok/ngrok-linux
	cp /usr/local/bin/ngrok-darwin /ngrok/ngrok-darwin
fi

/usr/local/bin/ngrokd -tlsKey=/root/server.key -tlsCrt=/root/server.crt -domain="$NGROK_DOMAIN" -tunnelAddr=":$NGROK_DAEMON_PORT" -httpAddr=":$NGROK_HTTP_PORT" -httpsAddr=":$NGROK_HTTPS_PORT"
