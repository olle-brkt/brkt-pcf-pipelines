# build-install-brkt-pcf pipeline

Builds a `install-brkt-pcf pipeline` and adds it to Concourse.

## install-brkt-pcf pipeline

Deploys bracketized PCF on AWS. The pipeline will deploy the necessary infrastructure in AWS, such as the networks, loadbalancers, and databases, and use these resources to then deploy PCF (with a bracketized Ops Manager AMI and stemcell).

The desired output of these install pipelines is a PCF deployment that matches the [Pivotal reference architecture](http://docs.pivotal.io/pivotalcf/refarch), usually using three availability zones and opting for high-availability components whenever possible.
