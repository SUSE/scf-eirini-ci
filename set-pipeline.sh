#!/bin/bash

if ! hash gomplate 2>/dev/null;then
  echo "gomplate missing. Follow the instructions in https://docs.gomplate.ca/installing/ and install it first."
  exit 1
fi

TARGET=${TARGET:-suse.de}
SECRETS_FILE=${SECRETS_FILE:-../cloudfoundry/secure/concourse-secrets.yml.gpg}

fly -t "${TARGET}" set-pipeline -p scf-eirini-ci -c <(gomplate -V -f pipeline.yaml.gomplate) --load-vars-from=<(${SECRETS_FILE:+gpg --decrypt --batch ${SECRETS_FILE}})
