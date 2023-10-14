# misskey

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 12.110.1](https://img.shields.io/badge/AppVersion-12.110.1-informational?style=flat-square)

Misskey is a decentralized microblogging platform born on Earth.
Since it exists within the Fediverse (a universe where various social media platforms are organized),
it is mutually linked with other social media platforms.

**This chart is not maintained by the upstream project and any issues with the chart should be raised [here](https://github.com/alyti/charts/issues/new/choose)**

## Source Code

* <https://github.com/misskey-dev/misskey>

## Requirements

Kubernetes: `>=1.16.0-0`

## Dependencies

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | elasticsearch | 18.0.2 |
| https://charts.bitnami.com/bitnami | postgresql | 10.5.3 |
| https://charts.bitnami.com/bitnami | redis | 16.9.2 |
| https://library-charts.k8s-at-home.com | common | 4.4.2 |

## TL;DR

```console
helm repo add alyti https://alyti.github.io/charts/
helm repo update
helm install misskey alyti/misskey
```

## Installing the Chart

To install the chart with the release name `misskey`

```console
helm install misskey alyti/misskey
```

## Uninstalling the Chart

To uninstall the `misskey` deployment

```console
helm uninstall misskey
```

The command removes all the Kubernetes components associated with the chart **including persistent volumes** and deletes the release.

## Configuration

Read through the [values.yaml](./values.yaml) file. It has several commented out suggested values.
Other values may be used from the [values.yaml](https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common/values.yaml) from the [common library](https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common).

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

```console
helm install misskey \
    alyti/misskey
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart.

```console
helm install misskey alyti/misskey -f values.yaml
```

## Values

**Important**: When deploying an application Helm chart you can add more values from our common library chart [here](https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config | object | See below | Configures misskey settings. See [app docs](https://github.com/misskey-dev/misskey/blob/develop/.config/example.yml) for more details. |
| config.db | object | See values.yaml | Postgres database connection.    Either use provided subchart or overwrite below values. |
| config.port | int | `3000` | The port that your Misskey server should listen on. |
| config.redis | object | See values.yaml | Redis connection.    Either use provided subchart or overwrite below values. |
| config.url | string | `"https://misskey.example.tld/"` | Final accessible URL seen by a user.    ONCE YOU HAVE STARTED THE INSTANCE, DO NOT CHANGE THE URL SETTINGS AFTER THAT! |
| elasticsearch | object | See values.yaml | Enable and configure elasticsearch subchart under this key.    For more options see [redis chart documentation](https://github.com/bitnami/charts/tree/master/bitnami/elasticsearch) |
| image.pullPolicy | string | `"IfNotPresent"` | image pull policy |
| image.repository | string | `"misskey/misskey"` | image repository |
| image.tag | string | `"12.110.1"` | image tag |
| ingress.main | object | See values.yaml | Enable and configure ingress settings for the chart under this key. |
| persistence | object | See values.yaml | Configure persistence settings for the chart under this key. |
| postgresql | object | See values.yaml | Enable and configure postgresql database subchart under this key.    For more options see [postgresql chart documentation](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) |
| redis | object | See values.yaml | Enable and configure redis subchart under this key.    For more options see [redis chart documentation](https://github.com/bitnami/charts/tree/master/bitnami/redis) |
| service | object | See values.yaml | Configures service settings for the chart. |

## Support

- See the [Docs](https://docs.k8s-at-home.com/our-helm-charts/getting-started/)
- Open an [issue](https://github.com/alyti/charts/issues/new/choose)
- Join our [Discord](https://discord.gg/sTMX7Vh) community

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.10.0](https://github.com/norwoodj/helm-docs/releases/v1.10.0)
