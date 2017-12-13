#!/bin/bash
set -eu

echo "Installing pyyaml"
pip install pyyaml 1>/dev/null

touch encrypted_ami

ami=$(grep $REGION pivnet-opsmgr/*.yml | cut -d' ' -f2)

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

