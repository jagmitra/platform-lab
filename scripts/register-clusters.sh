#!/usr/bin/env bash
set -euo pipefail

for CLUSTER in dev prod; do
  CTX="kind-${CLUSTER}"

  # dev follows main, prod follows the prod branch
  if [ "$CLUSTER" = "prod" ]; then REVISION="prod"; else REVISION="main"; fi

  kubectl --context "$CTX" -n kube-system create sa argocd-manager --dry-run=client -o yaml \
    | kubectl --context "$CTX" apply -f -
  kubectl --context "$CTX" create clusterrolebinding argocd-manager \
    --clusterrole cluster-admin --serviceaccount kube-system:argocd-manager \
    --dry-run=client -o yaml | kubectl --context "$CTX" apply -f -

  TOKEN=$(kubectl --context "$CTX" -n kube-system create token argocd-manager --duration 8760h)

  cat <<EOF | kubectl --context kind-mgmt apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: cluster-${CLUSTER}
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    env: ${CLUSTER}
    fleet: lab
    revision: ${REVISION}
type: Opaque
stringData:
  name: ${CLUSTER}
  server: https://${CLUSTER}-control-plane:6443
  config: |
    {"bearerToken": "${TOKEN}", "tlsClientConfig": {"insecure": true}}
EOF
done
