{{- define "frpcConfig" -}}
serverAddr = "frp.diluz.io"
serverPort = 7000

auth.token = "{{ "{{" }} .Envs.FRP_AUTH_TOKEN {{ "}}" }}"

[[proxies]]
name = "https"
type = "https"
localIP = "traefik.traefik.svc.cluster.local"
localPort = 443
customDomains = [{{ range $index, $domain := .Values.domains }}{{ if $index }},{{ end }}{{ printf "%q" $domain }}{{ end }}]

[[proxies]]
name = "http"
type = "http"
localIP = "traefik.traefik.svc.cluster.local"
localPort = 80
customDomains = [{{ range $index, $domain := .Values.domains }}{{ if $index }},{{ end }}{{ printf "%q" $domain }}{{ end }}]
{{- end }}
