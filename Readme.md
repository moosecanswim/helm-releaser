# Helm Releaser

To make this work add to the releases.yaml then use the makefile.

## Usage

    `make install <namespace> <project>`
    `make install dia-test nifi`

## Schema

```yaml
namespace:
    configs:
        aws_profile: ""
        values_path: ""
        secret_path: ""
    releases:
        <name>:
            chart:
                path: ""  (can be local or remote)
                version: ""
            release:
                secrets: "" (optional)
                values: "" (optional)
```