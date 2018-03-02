#!/bin/bash

set -eu

echo "Bumping Ops Manager disk size..."

echo "$PEM" > ssh-key
chmod 700 ssh-key

curl -L -s -k -o jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
chmod +x jq

opsman_ip=$(dig "$OPSMAN_DOMAIN_OR_IP_ADDRESS" +short)
echo "Ops Manager IP address: $opsman_ip"

volume_id=$(aws ec2 --region "$REGION" describe-instances --filter Name=ip-address,Values="$opsman_ip" | ./jq -r '.Reservations[0].Instances[0].BlockDeviceMappings[] | select(.DeviceName == "/dev/sdf") | .Ebs.VolumeId')
echo "VolumeId for the /dev/sdf volume: $volume_id"

echo "Increasing size of /dev/sdf to 100 GB"
aws ec2 --region "$REGION" modify-volume --volume-id "$volume_id" --size 100

until [[ "$(aws ec2 --region "$REGION" describe-volumes-modifications --volume-ids "$volume_id" | jq -r '.VolumesModifications[0].Progress')" == "100" ]]
do
    progress="$(aws ec2 --region "$REGION" describe-volumes-modifications --volume-ids "$volume_id" | jq -r '.VolumesModifications[0].Progress')"
    echo "Modifying volume... $progress% done"
    sleep 60
done

instance_id=$(aws ec2 --region "$REGION" describe-instances --filter Name=ip-address,Values="$opsman_ip" | jq -r '.Reservations[0].Instances[0].InstanceId')
echo "Rebooting Ops Manager, instance_id: $instance_id"
aws ec2 --region "$REGION" reboot-instances --instance-ids "$instance_id"

sleep 10

echo "Waiting for Ops Manager to pass status checks..."
aws ec2 wait --region "$REGION" instance-status-ok --instance-ids "$instance_id"

sleep 60

echo "Checking if 'lsblk' reports the new updated disk size..."
until [[ "$(ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error "ubuntu@$opsman_ip" 'lsblk | grep xvda1 | grep -Eo [0-9]+G')" == "100G" ]]
do
    echo "Disk size reported by 'lsblk': $(ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error "ubuntu@$opsman_ip" 'lsblk | grep xvda1 | grep -Eo [0-9]+G')B"
    sleep 10
done

echo "Disk size reported by 'lsblk': 100GB"
echo "Done!"
