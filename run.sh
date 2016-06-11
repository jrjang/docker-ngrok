#!/bin/bash

pushd $DIR_NGROK

if ! [ -f .ca_done ]; then
	# generate certification
	openssl genrsa -out base.key 2048
	openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
	openssl genrsa -out server.key 2048
	openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
	openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt
	cp base.pem assets/client/tls/ngrokroot.crt
	cp server.key server.crt /root

	touch .ca_done
fi

old=

if [ -f .head ]; then
	old=`cat .head`
fi

# update code base
cp /tmp/gitconfig ~/.gitconfig
git stash
git pull --rebase
git stash pop
new=`git log -1 | grep commit | cut -d' ' -f 2`

if [ "x"$old != "x"$new ]; then
	# build ngrok daemon
	make release-server

	# build ngrok client
	GOOS="linux" GOARCH="amd64" make release-client
	GOOS="darwin" GOARCH="amd64" make release-client

	cp bin/ngrokd /usr/local/bin/
	cp bin/ngrok /usr/local/bin/ngrok-linux
	cp bin/darwin_amd64/ngrok /usr/local/bin/ngrok-darwin

	if [ -d /ngrok ]; then
		cp /usr/local/bin/ngrok-linux /ngrok/ngrok-linux
		cp /usr/local/bin/ngrok-darwin /ngrok/ngrok-darwin
	fi

	echo $new > .head
fi

/usr/local/bin/ngrokd -tlsKey=/root/server.key -tlsCrt=/root/server.crt -domain="$NGROK_DOMAIN" -tunnelAddr=":$NGROK_DAEMON_PORT" -httpAddr=":$NGROK_HTTP_PORT" -httpsAddr=":$NGROK_HTTPS_PORT"
