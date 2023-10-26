#!/bin/bash

# Two types of token are supported:
# - Registration Token (registration)
# - Authentication Token (authentication)
tokenType=$1
token=$2

variableName=""

case $tokenType in
    "registration")
        variableName="REGISTRATION_TOKEN"
        ;;
    "authentication")
        variableName="AUTHENTICATION_TOKEN"
        ;;
esac

if [[ -z "$token" ]]; then
    echo -e "\033[0;31mThe $variableName variable must be set for the (fork) project" && exit 1
else
    echo -e "The $variableName variable found and is not empty"
fi
