{{- define "cloudflared.configYaml" -}}
tunnel: cluster.diluz.io
credentials-file: /etc/cloudflared/creds/credentials.json
metrics: 0.0.0.0:2000
# Autoupdates applied in a k8s pod will be lost when the pod is removed or restarted, so
# autoupdate doesn't make sense in Kubernetes. However, outside of Kubernetes, we strongly
# recommend using autoupdate.
no-autoupdate: true
# The `ingress` block tells cloudflared which local service to route incoming
# requests to. For more about ingress rules, see
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/ingress
ingress:
{{- range .Values.regions }}
{{- $basePath := .basePath }}
{{- range .services }}
- hostname: {{ .subdomain }}.{{ $basePath }}
  service: http://{{ .servicename }}.{{ .namespace }}.svc.cluster.local:{{ .serviceport }}
{{- end }}
{{- end }}
# This rule matches any traffic which didn't match a previous rule and responds with a 404 errorpage.
- service: http://error-pages.error-pages.svc.cluster.local:8080
{{- end }}