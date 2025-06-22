## Installation

Followed the turingpi guide https://docs.turingpi.com/docs/turing-pi2-kubernetes-cluster-argo-cd#install

Then, adjusted the config by defining argocd-cmd-params-cm.yml and running 'kubectl apply -f argocd-cmd-params-cm.yml -n argocd'

## Upgrading

Check patchnotes on https://argo-cd.readthedocs.io/en/stable/operator-manual/upgrading/overview/

Then run 'kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/<version>/manifests/install.yaml' where <version> could also be 'stable'