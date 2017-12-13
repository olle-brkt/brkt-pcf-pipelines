#!/bin/bash
set -eu

ami=$(cat stock-ami/ami)

touch pre_encrypted_ami

# If this metavisor version already has encrypted this source_ami, reuse it save time
python <<EOF
import yaml

mv_ver = "$METAVISOR_VERSION"
stock_ami = "$ami"

print "Looking in 'encrypted-amis/encrypted-amis-map.yml' for %s that has been encrypted by %s" % (stock_ami, mv_ver)

data = None
with open('encrypted-amis/encrypted-amis-map.yml', 'r') as f:
    data = yaml.safe_load(f)

print "Currently encrypted amis: (in the format: Metavisor_version: [{source_ami:encrypted_ami}])"
for mv in data.items():
    print "%s: %s" % mv

pre_enc_ami = None

if mv_ver in data:
    for ami in data[mv_ver]:
        source_ami = ami.items()[0][0]
        encrypted_ami = ami.items()[0][1]
        if src_ami.items()[0][0] == stock_ami:
            pre_enc_ami = src_ami.items()[0][1]


with open('pre_encrypted_ami', 'w') as f:
    if pre_enc_ami is None:
        print "Can not reuse pre-encrypted ami, not found"
        f.write("Not found")
    else:
        print "%s has already been encrypted by %s. Resulting ami %s. Reusing it to save time" % (stock_ami, mv_ver, pre_enc_ami)
        f.write(pre_enc_ami)
EOF

if [[ `cat pre_encrypted_ami` =~ ^ami- ]] ; then cp encrypted-amis/encrypted-amis-map.yml results/encrypted-amis-map.yml ; exit 0; fi

echo "Installing brkt-cli"
pip install brkt-cli 1>/dev/null

echo "Getting token from https://api.$SERVICE_DOMAIN:443"
auth_cmd="brkt auth --email $EMAIL --password $PASSWORD --root-url https://api.$SERVICE_DOMAIN:443"
echo "Running command: export BRKT_API_TOKEN=\`brkt auth --email $EMAIL --password ***** --root-url https://api.$SERVICE_DOMAIN:443\`"
export BRKT_API_TOKEN=`$auth_cmd`

# echo "${CA_CERT}" > ${ROOT}/ca.crt
# cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $region --metavisor-version ${METAVISOR_VERSION} --ca-cert ${ROOT}/ca.crt $ami"

echo "Encrypting stemcell image $ami"
cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $REGION --metavisor-version ${METAVISOR_VERSION} --no-single-disk --brkt-tag app=pcf --brkt-tag role=opsmanager $ami"
echo "Running command: $cmd"
$cmd | tee encrypt.log &

# Wait for all background tasks to complete
wait

output_ami=`tail -1 encrypt.log | awk '{print $1}'`
if ! [[ $output_ami =~ ^ami- ]]; then
    echo "Encryption failed in region $REGION"
    exit 1
fi

touch results/encrypted-amis-map.yml

# Update the encrypted-amis-map file to include new result
python <<EOF
import yaml

mv_ver = "$METAVISOR_VERSION"
stock_ami = "$ami"
output_ami = "$output_ami"

print "Adding '%s: [{%s:%s}]' to 'encrypted-amis/encrypted-amis-map.yml'" % (mv_ver, stock_ami, output_ami)

data = None
with open('encrypted-amis/encrypted-amis-map.yml', 'r') as f:
    data = yaml.safe_load(f)

pre_enc_ami = None

if mv_ver in data:
    data[mv_ver].append({stock_ami: output_ami})

else:
    data[mv_ver] = [{stock_ami: output_ami}]

print "Currently encrypted amis: (in the format: Metavisor_version: [{source_ami:encrypted_ami}])"
for mv in data.items():
    print "%s: %s" % mv

with open('results/encrypted-amis-map.yml', 'w') as f:
    yaml.dump(data, f)
EOF
