#!/bin/bash
set -eu

echo "Installing pyyaml"
pip install pyyaml 1>/dev/null

touch ami/ami

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

enc_ami = None

if mv_ver in data:
    for ami in data[mv_ver]:
        source_ami = ami.items()[0][0]
        encrypted_ami = ami.items()[0][1]
        if src_ami.items()[0][0] == stock_ami:
            enc_ami = src_ami.items()[0][1]


with open('ami/ami', 'w') as f:
    if enc_ami is None:
        print "Can not reuse pre-encrypted ami, not found! Start the encrypt job again."
        f.write("Not found")
        exit(1)
    else:
        print "Found %s" % enc_ami)
        f.write(enc_ami)
EOF

