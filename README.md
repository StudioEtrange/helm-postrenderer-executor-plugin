# helm-postrenderer-executor-plugin

Helm 4 plugin that provides a post-renderer able to run any command passed
through `--post-renderer-arg` or through an environment variable.

The plugin reads the manifests rendered by Helm from `stdin`, forwards them to
the requested command, then returns the command output on `stdout` for Helm to
continue the install, upgrade, or template flow.

## Install

From this repository:

```sh
helm plugin install https://github.com/StudioEtrange/helm-postrenderer-executor-plugin.git
```

Or cloning this repository first, then:

```sh
helm plugin install .
```

The plugin is declared as a Helm 4 post-renderer plugin with
`type: postrenderer/v1` and the `subprocess` runtime.

## Usage

Use the plugin name as the Helm 4 post-renderer, then pass the command and its
arguments with one `--post-renderer-arg` per argument:

```sh
helm template my-release ./chart \
  --post-renderer postrenderer-executor \
  --post-renderer-arg yq \
  --post-renderer-arg '.metadata.labels.managed-by = "postrenderer-executor"'
```

The first `--post-renderer-arg` is the command to execute. The following
`--post-renderer-arg` values are passed as arguments to that command.

Alternatively, pass the whole command line with `HELM_POSTRENDERER_EXECUTOR_COMMAND`
and omit `--post-renderer-arg`:

```sh
HELM_POSTRENDERER_EXECUTOR_COMMAND='yq ''.metadata.labels.managed-by = "postrenderer-executor"''' \
  helm template my-release ./chart \
    --post-renderer postrenderer-executor
```

`HELM_POSTRENDERER_EXECUTOR_COMMAND` is evaluated with `sh -c`, so normal shell
quoting, pipes, and redirections are available:

```sh
HELM_POSTRENDERER_EXECUTOR_COMMAND='yq ''.metadata.labels.env = "dev"'' | yq ''.metadata.annotations.checked = "true"''' \
  helm template my-release ./chart \
    --post-renderer postrenderer-executor
```

## Examples

Run `kustomize` as the transformation command:

```sh
helm template my-release ./chart \
  --post-renderer postrenderer-executor \
  --post-renderer-arg kustomize \
  --post-renderer-arg build \
  --post-renderer-arg overlays/dev
```

Run custom shell script:

```sh
helm upgrade --install my-release ./chart \
  --post-renderer postrenderer-executor \
  --post-renderer-arg ./post-render.sh
```

```sh
helm install my-release ./chart \
  --post-renderer postrenderer-executor \
  --post-renderer-arg ./scripts/post-render.sh \
  --post-renderer-arg --flag \
  --post-renderer-arg value
```

## Behavior

`postrenderer-executor.sh` does not modify manifests itself. It only delegates to
the command supplied through `--post-renderer-arg`:

```sh
postrenderer-executor.sh COMMAND [ARG...]
```

If no command argument is supplied, it delegates to
`HELM_POSTRENDERER_EXECUTOR_COMMAND`:

```sh
HELM_POSTRENDERER_EXECUTOR_COMMAND='COMMAND [ARG...]'
postrenderer-executor.sh
```

The delegated command must read manifests from `stdin` and write the transformed
manifests to `stdout`.
