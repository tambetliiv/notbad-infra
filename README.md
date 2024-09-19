# notbad k8s infra

1. Deploy infra via terraform from `terraform` dir.
1. Connect to k8s cluster and install services.
1. Install ingress: `helm install ingress ingress-nginx/ingress-nginx --namespace cert-manager --create-namespace --set controller.containerPort.https=8089`
1. Install cert-manager: 
```
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.3 \
  --set crds.enabled=true
```
1. Create cluster issuer: `kubectl -n cert-manager apply -f cluster-issuer.yaml`
1. Continue app deployment from https://github.com/tambetliiv/notbad-app
