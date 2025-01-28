## install
https://community.cloudflare.com/t/installing-cloudflare-tunnel-on-ubuntu-server/552018 -> https://pkg.cloudflare.com/index.html

## create tunnel
`cloudflared tunnel create`

## provide secret
`kubectl create secret generic tunnel-credentials \
--from-file=credentials.json=/mysecretLocation.json`

## tunnel DNS
`cloudflared tunnel route dns <tunnel> <hostname>`

