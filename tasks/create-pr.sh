#!/bin/bash

# Updates the docker image information in the role-manifest
# Looks for a block like:
#
#- name: EIRINI_EXECUTOR_IMAGE
#  options:
#    default: 'eirini/recipe-executor:0.3.0'
#    description: "Executes the buildpackapplifecyle to build a Droplet"
#    imagename: true
#
# and changes the lines to match the built image

set -e

if [ -z "$IMAGE_TO_REPLACE"  ]; then
  echo "IMAGE_TO_REPLACE environment variable not set"
  exit 1
fi

if [ -z "$GITHUB_TOKEN"  ]; then
  echo "GITHUB_TOKEN environment variable not set"
  exit 1
fi

# Get rid of quotes in the beginning and end
export GITHUB_PRIVATE_KEY=${GITHUB_PRIVATE_KEY:1:-1}
# Setup git
mkdir -p ~/.ssh
echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> ~/.ssh/known_hosts
echo -e $GITHUB_PRIVATE_KEY > ~/.ssh/id_ecdsa
chmod 0600 ~/.ssh/id_ecdsa

git config --global user.email "$GIT_MAIL"
git config --global user.name "$GIT_USER"

# TODO: Get the image url from the resource directory
new_image="$(cat docker_image/repository):$(cat docker_image/tag)"
COMMIT_TITLE="Bump Eirini ${IMAGE_TO_REPLACE} image"

# Update release in scf repo
mkdir updated-scf
cp -r git.scf/. updated-scf/
cd updated-scf

export GIT_BRANCH_NAME="bump-${IMAGE_TO_REPLACE}-`date +%Y%m%d%H%M%S`"
git checkout -b $GIT_BRANCH_NAME

echo "Will replace ${IMAGE_TO_REPLACE} with ${new_image}"
sed -i "s#\(\s\+default: '\).*${IMAGE_TO_REPLACE}:[0-9\.]\+#\1${new_image}#" container-host-files/etc/scf/config/role-manifest.yml

git commit container-host-files/etc/scf/config/role-manifest.yml -m "$COMMIT_TITLE"
git push origin $GIT_BRANCH_NAME

# Open a Pull Request
PR_MESSAGE=`echo -e "${COMMIT_TITLE}"`
hub pull-request -m "$PR_MESSAGE" -b develop
