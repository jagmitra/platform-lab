#!/usr/bin/env bash
set -euo pipefail

for CLUSTER in dev prod; do
  CTX="kind-${CLUSTER}"

  # Service account that Argo CD will use inside the target cluster
  kubectl --context "$CTX" -n kube-system create sa argocd-manager --dry-run=client -o yaml \
    | kubectl --context "$CTX" apply -f -
  kubectl --context "$CTX" create clusterrolebinding argocd-manager \
    --clusterrole cluster-admin --serviceaccount kube-system:argocd-manager \
    --dry-run=client -o yaml | kubectl --context "$CTX" apply -f -

  TOKEN=$(kubectl --context "$CTX" -n kube-system create token argocd-manager --duration 8760h)

  # Cluster secret in the mgmt cluster's argocd namespace
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
type: Opaque
stringData:
  name: ${CLUSTER}
  server: https://${CLUSTER}-control-plane:6443
  config: |
    {"bearerToken": "${TOKEN}", "tlsClientConfig": {"insecure": true}}
EOF
done