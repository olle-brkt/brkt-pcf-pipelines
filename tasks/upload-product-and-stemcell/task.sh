#!/bin/bash
set -eu

curl -L -s -k -o jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
chmod +x jq

if [[ -n "$NO_PROXY" ]]; then
  echo "$OM_IP $OPSMAN_DOMAIN_OR_IP_ADDRESS" >> /etc/hosts
fi

# echo om version for debugging
echo "$(om-linux -v)"

mv encrypted-stemcell/*.tgz ./
encrypted_sc_path=$(find ./ -name *.tgz | sed "s|^\./||")
echo "Uploading $encrypted_sc_path to $OPSMAN_DOMAIN_OR_IP_ADDRESS"

echo "Getting director guid"
director_guid="$(om-darwin -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS -k \
    -c \"${OPSMAN_CLIENT_ID}\" \
    -s \"${OPSMAN_CLIENT_SECRET}\" \
    -u \"$OPS_MGR_USR\" \
    -p \"$OPS_MGR_PWD\" \ curl --path /api/v0/deployed/products \
    | ./jq --raw-output '.[] | select(.type == "p-bosh") | .guid')"

echo "Getting director IP"
director_ip="$(om-darwin -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS -k \
    -c \"${OPSMAN_CLIENT_ID}\" \
    -s \"${OPSMAN_CLIENT_SECRET}\" \
    -u \"$OPS_MGR_USR\" \
    -p \"$OPS_MGR_PWD\" \
    curl --path /api/v0/deployed/products/$director_guid/static_ips \
    | ./jq --raw-output '.[] | .ips[0]')"

echo "Getting UAA user credentials"
login_password="$(om-darwin -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS -k \
    -c \"${OPSMAN_CLIENT_ID}\" \
    -s \"${OPSMAN_CLIENT_SECRET}\" \
    -u \"$OPS_MGR_USR\" \
    -p \"$OPS_MGR_PWD\" \
    curl --path /api/v0/deployed/director/credentials/uaa_admin_user_credentials \
    | ./jq '.credential.value.password')"

echo "Getting UAA login client credentials"
client_secret="$(om-darwin -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS -k \
    -c \"${OPSMAN_CLIENT_ID}\" \
    -s \"${OPSMAN_CLIENT_SECRET}\" \
    -u \"$OPS_MGR_USR\" \
    -p \"$OPS_MGR_PWD\" \
    curl --path /api/v0/deployed/director/credentials/uaa_login_client_credentials \
    | ./jq '.credential.value.password')"

cat << EOF > /tmp/upload_stemcell.sh
uaac --skip-ssl-validation target https://$director_ip:8443
uaac token owner get login admin -s $client_secret -p $login_password
uaac client add stemcell_uploader --scope uaa.none --authorized_grant_types client_credentials --authorities bosh.admin -s $client_secret
uaac token client get stemcell_uploader -s $client_secret
BOSH_CLIENT=stemcell_uploader BOSH_CLIENT_SECRET=$client_secret bosh2 -e $director_ip --ca-cert /var/tempest/workspaces/default/root_ca_certificate upload-stemcell encrypted_stemcell.tgz --fix
EOF

echo "scp:ing the encrypted stemcell to $OPSMAN_DOMAIN_OR_IP_ADDRESS"
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error $encrypted_sc_path ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS:encrypted_stemcell.tgz

echo "scp:ing a stemcell uploader script to $OPSMAN_DOMAIN_OR_IP_ADDRESS"
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error /tmp/upload_stemcell.sh ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS:upload_stemcell.sh

echo "running the script..."
ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS 'chmod +x upload_stemcell.sh; ./upload_stemcell.sh'

om-linux -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
    --client-id "${OPSMAN_CLIENT_ID}" \
    --client-secret "${OPSMAN_CLIENT_SECRET}" \
    -u "$OPS_MGR_USR" \
    -p "$OPS_MGR_PWD" \
    -k \
    upload-stemcell --force \
    -s $encrypted_sc_path

# Should the slug contain more than one product, pick only the first.
FILE_PATH=$(find ./pivnet-product -name *.pivotal | sort | head -1)
om-linux -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --client-id "${OPSMAN_CLIENT_ID}" \
  --client-secret "${OPSMAN_CLIENT_SECRET}" \
  -u "$OPS_MGR_USR" \
  -p "$OPS_MGR_PWD" \
  -k \
  --request-timeout 3600 \
  upload-product \
  -p $FILE_PATH
