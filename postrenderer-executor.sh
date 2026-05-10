#!/bin/sh

set -eu

usage() {
  cat >&2 <<'EOF'
Usage: postrenderer-executor COMMAND [ARG...]

Execute COMMAND as a Helm post-renderer.

The Kubernetes manifests rendered by Helm are read from stdin and forwarded to
COMMAND stdin. COMMAND stdout is written back to stdout for Helm to consume.

If COMMAND is omitted, HELM_POSTRENDERER_EXECUTOR_COMMAND can contain the full command
line to execute. It is evaluated by sh -c.

Example:
  helm template release chart \
    --post-renderer postrenderer-executor \
    --post-renderer-args yq \
    --post-renderer-args '.metadata.labels.foo = "bar"'

With an environment variable:

  HELM_POSTRENDERER_EXECUTOR_COMMAND='yq ''.metadata.labels.foo = "bar"''' \
    helm template release chart \
      --post-renderer postrenderer-executor
EOF
}

if [ "$#" -gt 0 ]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  exec "$@"
fi

if [ "${HELM_POSTRENDERER_EXECUTOR_COMMAND:-}" ]; then
  exec sh -c "$HELM_POSTRENDERER_EXECUTOR_COMMAND"
fi

usage
exit 64
