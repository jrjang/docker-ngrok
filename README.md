# docker-ngrok

Secure tunnels to localhost

[ngrok](https://ngrok.com) is expose a local server behind a NAT or firewall to the internet.

The source of ngrok 1.x is provided from https://github.com/inconshreveable/ngrok .

## Usage

To start the ngrok daemon, simply run:

```sh
docker run -d -v /PATH/NGROK/CLIENT:/ngrok -e NGROK_DOMAIN="YOUR_DOMAIN_NAME" -p HTTP_PORT:80 -p HTTPS_PORT:443 -p NGROK_DAEMON_PORT:4443 jrjang/docker-ngrok
```

The 64-bit client binaries for OSX and Linux will be put under /PATH/NGROK/CLIENT on host.
