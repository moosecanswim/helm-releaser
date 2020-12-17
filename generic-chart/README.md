# Generic Chart

This generic chart is to help speed up the ability for developers to issue simple statefulsets or deployments into the mesh.

All you need to do is copy the values file and add in your own values.

Most of the changes you will make will be under the service section:

```yaml
service:
  name: supercoolservicename
  version: '0.3.1'
  image: 'docker-greymatter.di2e.net/services/nifi-openshift:1.11.4'
  imagePullPolicy: Always
  resources:
    limits:
      cpu: 1
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  # This change containerPort to the port that your service can be reached at  
  ports:
    - containerPort: 8002
      protocol: TCP
  # add a list of your envars here  
  envvars:
    PORT:
      type: 'value'
      value: '{{ $.Values.service.port }}'
    NAME:
      type: 'value'
      value: "your name"
```
