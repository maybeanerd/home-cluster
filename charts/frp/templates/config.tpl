{{- define "frpcConfig" -}}
serverAddr = "{{ .Values.serverAddr }}"
serverPort = {{ .Values.serverPort }}

auth.token = "{{ "{{" }} .Envs.FRP_AUTH_TOKEN {{ "}}" }}"

[webServer]
addr = "127.0.0.1"
port = 7400

[[proxies]]
name = "traefik-http"
type = "tcp"
localIP = "{{ .Values.reverseProxyIp }}"
localPort = 80
remotePort = 80

[[proxies]]
name = "traefik-https"
type = "tcp"
localIP = "{{ .Values.reverseProxyIp }}"
localPort = 443
remotePort = 443
{{- end }}
