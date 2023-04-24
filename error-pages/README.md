# Better error pages

This deployments is based on: [error-pages container](https://github.com/tarampampam/error-pages)

## What id does
It uses priority in Traefik to display nice error page in case its not handled by targeted app. It can be also added into any service ingress if that service does not handle 404,500 etc errors in nice way.

## Themes

You can use pre build themes by changing the `TEMPLATE_NAME` variable in  `error-pages-deployment.yaml` 

```yaml
.
.
.
        env:
        - name: TEMPLATE_NAME
          value: "app-down"
        - name: SHOW_DETAILS
          value: "true"
        ports:
.
.
.
```

Theme demonstrations: [HERE](https://tarampampam.github.io/error-pages/)

## Prometheus

Container expose /metrics in prometheus format

## Limits

- Limited to 16MB RAM - Max 32MB
- CPU: 50m
- Image size: 4.66MB
- readOnlyRootFilesystem: true
- runAsNonRoot: true
- allowPrivilegeEscalation: false

