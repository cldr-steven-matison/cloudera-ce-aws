#!/bin/bash
set -euo pipefail

cd /home/tunas/cloudera-ce-aws

CREDS=$(aws configure export-credentials --profile cldr-se --format env 2>/dev/null)
AWS_ACCESS_KEY_ID=$(echo "$CREDS" | grep AWS_ACCESS_KEY_ID | cut -d= -f2-)
AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | grep AWS_SECRET_ACCESS_KEY | cut -d= -f2-)
AWS_SESSION_TOKEN=$(echo "$CREDS" | grep AWS_SESSION_TOKEN | cut -d= -f2-)

docker run --rm --interactive \
  -v "$(pwd)/:/home/tunas/cloudera-ce-aws/" \
  --workdir /home/tunas/cloudera-ce-aws \
  -v "/run/user/1000/keyring/:/run/user/1000/keyring/" \
  -e SSH_AUTH_SOCK=/run/user/1000/keyring/ssh \
  -v "/home/tunas/.ssh/:/home/runner/.ssh/" \
  -v "/home/tunas/.ssh/:/root/.ssh/" \
  -v "$(pwd)/runs/artifacts/:/runner/artifacts/:Z" \
  -v "$(pwd)/runs/:/runner/:Z" \
  -v "/home/tunas/license.txt:/home/tunas/license.txt" \
  -v "/home/tunas/cloudera-ce-aws/patches/jdk_facts.py:/usr/share/ansible/collections/ansible_collections/cloudera/exe/plugins/modules/jdk_facts.py" \
  -v "/home/tunas/cloudera-ce-aws/patches/RedHat-pre.yml:/usr/share/ansible/collections/ansible_collections/cloudera/exe/roles/caddy/tasks/RedHat-pre.yml" \
  -e ANSIBLE_SSH_CONTROL_PATH="/dev/shm/cp%%h-%%p-%%r" \
  -e ANSIBLE_HOST_KEY_CHECKING="False" \
  -e ANSIBLE_SSH_RETRIES="10" \
  -e CDP_LICENSE_FILE="/home/tunas/license.txt" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \
  --user=1000 \
  --name ansible_deploy_v3 \
  --network=host \
  ghcr.io/cloudera-labs/cloudera-ce-aws:1.0.0-arm64 \
  ansible-playbook \
  /home/tunas/cloudera-ce-aws/playbooks/infrastructure.yml \
  playbooks/services.yml \
  playbooks/cms.yml \
  playbooks/ozone-nifi-cluster.yml \
  -e @config-srm-base.yml \
  -i /home/tunas/cloudera-ce-aws/inventory.yml
