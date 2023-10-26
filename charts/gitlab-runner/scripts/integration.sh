#!/bin/bash

# Two types of token are supported:
# - Registration Token (registration)
# - Authentication Token (authentication)
tokenType=$1
token=$2
valueYamlPath=$3

INTEGRATION_RUNNER_NAME=${INTEGRATION_RUNNER_NAME:-integration-runner}
INTEGRATION_HELM_POD_RELEASE_LABEL=${INTEGRATION_HELM_POD_RELEASE_LABEL:-release=$INTEGRATION_RUNNER_NAME}

case $tokenType in
    "registration")
        helm install -f "$valueYamlPath" --timeout 5m --wait --set gitlabUrl="$CI_SERVER_URL",runnerRegistrationToken="$token" "$INTEGRATION_RUNNER_NAME" .
        ;;
    "authentication")
        helm install -f "$valueYamlPath" --timeout 5m --wait --set gitlabUrl="$CI_SERVER_URL",runnerToken="$token" "$INTEGRATION_RUNNER_NAME" .
        ;;
    *)
        echo "Token provided is not supported"
        exit 1
        ;;
esac

kubectl describe pod -l "$INTEGRATION_HELM_POD_RELEASE_LABEL"

timeout 60s grep -m1 "Starting multi-runner" <(kubectl logs -f -l "$INTEGRATION_HELM_POD_RELEASE_LABEL" --tail=-1)

exit_code="$?"

kubectl logs --tail=-1 -l "$INTEGRATION_HELM_POD_RELEASE_LABEL"

exit $exit_code

