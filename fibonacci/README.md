# Fibonacci

## TL;DR;

```console
$ helm install Fibonacci
```

## Introduction

This chart bootstraps a Fibonacci deployment on a [Kubernetes](http://kubernetes.io) or [OpenShift](https://www.openshift.com/) cluster using the [Helm](https://helm.sh) package manager.

## Namespace isolated tiller

For security purposes in a multi tenant environment, it is possible to specify a tiller and restrict it's namespace access. In these cases you will need to specify the `--tiller-namespace <tiller's_namespace>` for each helm command.

## Installing the Chart

To install the chart with the release name `<my-release>`:

```console
$ helm install Fibonacci --name <my-release> --tiller-namespace <tiller-namespace>
```

## Uninstalling the Chart

To uninstall/delete the `<my-release>` deployment:

```console
$ helm delete --purge <my-release> --tiller-namespace <tiller-namespace>
```

The command removes all components associated with the chart and deletes the release.

## Configuration

The following tables list the configurable parameters of the Fibonacci chart and their default values.

### Global Configuration

| Parameter                        | Description       | Default    |
| -------------------------------- | ----------------- | ---------- |
| global.environment               |                   | openshift  |
| global.domain                    | edge-ingress.yaml |            |
| global.route_url_name            | edge-ingress.yaml |            |
| global.remove_namespace_from_url | edge-ingress.yaml | ''         |
| global.exhibitor.replicas        |                   | 1          |
| global.xds.port                  |                   | 18000      |
| global.xds.cluster               |                   | greymatter |

### Fibonacci

#### Service Configuration

| Parameter                           | Description              | Default                                                                  |
| ----------------------------------- | ------------------------ | ------------------------------------------------------------------------ |
| fibonacci.name                      | Service Name             | fibonacci                                                                |
| fibonacci.image                     | Docker Image             | 'docker-greymatter.di2e.net/services/fibonacci:latest'                   |
| fibonacci.base_path                 |                          | /services/{{ $.Values.fibonacci.name }}/{{ $.Values.fibonacci.version }} |
| fibonacci.version                   | service version          | 1.0.0                                                                    |
| fibonacci.imagePullPolicy           |                          | Always                                                                   |
| fibonacci.resources.limits.cpu      | (optional resource spec) |                                                                          |
| fibonacci.resources.limits.memory   | (optional resource spec) |                                                                          |
| fibonacci.resources.requests.cpu    | (optional resource spec) |                                                                          |
| fibonacci.resources.requests.memory | (optional resource spec) |                                                                          |

#### Service Environment Variables

| Environment variable | Description | Default |
| -------------------- | ----------- | ------- |
|                      |             |         |

#### Sidecar Configuration

| Parameter                         | Description              | Default                                                                         |
| --------------------------------- | ------------------------ | ------------------------------------------------------------------------------- |
| sidecar.version                   | Proxy Version            | 0.8.0                                                                           |
| sidecar.image                     | Proxy Image              | 'docker-greymatter.di2e.net/greymatter/gm-proxy:{{ $.Values.sidecar.version }}' |
| sidecar.imagePullPolicy           | Image pull policy        | Always                                                                          |
| sidecar.create_sidecar_secret     | Create Certs             | false                                                                           |
| sidecar.certificates              |                          | {name:{ca: ... , cert: ... , key ...}}                                          |
| sidecar.resources.limits.cpu      | (optional resource spec) | 200m                                                                            |
| sidecar.resources.limits.memory   | (optional resource spec) | 500Mi                                                                           |
| sidecar.resources.requests.cpu    | (optional resource spec) | 100m                                                                            |
| sidecar.resources.requests.memory | (optional resource spec) | 129Mi                                                                           |

#### Sidecar Environment Variables

| Environment variable | Default                               |
| -------------------- | ------------------------------------- |
| egress_ca_cert_path  | ''/etc/proxy/tls/sidecar/ca.crt''     |
| egress_cert_path     | '/etc/proxy/tls/sidecar/server.crt'   |
| egress_key_path      | '/etc/proxy/tls/sidecar/server.key'   |
| egress_use_tls       | 'true'                                |
| ingress_use_tls      | 'true'                                |
| ingress_ca_cert_path | '/etc/proxy/tls/sidecar/ca.crt'       |
| ingress_cert_path    | '/etc/proxy/tls/sidecar/server.crt'   |
| ingress_key_path     | '/etc/proxy/tls/sidecar/server.key'   |
| metrics_port         | '9081                                 |
| port                 | '9080'                                |
| metrics_key_function | 'depth'                               |
| proxy_dynamic        | 'true'                                |
| service_host         | 127.0.0.1                             |
| service_port         | {{ $.Values.fibonacci.service_port }} |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

- All the files listed under this variable will overwrite any existing files by the same name in the Fibonacci config directory.
- Files not mentioned under this variable will remain unaffected.

```console
$ helm install Fibonacci --name <my-release> --tiller-namespace <tiller-namespace> \
  --set=jwt.version=v0.2.0, sidecar.ingress_use_tls='false'
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example :

```console
$ helm install Fibonacci --name <my-release> -f custom.yaml  --tiller-namespace <tiller-namespace>
```

Values that are added first in the command will be overwritten by values defined after them.
