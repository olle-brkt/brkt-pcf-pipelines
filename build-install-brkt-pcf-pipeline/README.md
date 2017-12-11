# build-install-brkt-pcf pipeline

Builds a `install-brkt-pcf pipeline` and adds it to Concourse.

## install-brkt-pcf pipeline

Deploys bracketized PCF on AWS. The pipeline will deploy the necessary infrastructure in AWS, such as the networks, loadbalancers, and databases, and use these resources to then deploy PCF (with a bracketized Ops Manager AMI and stemcell).

The desired output of these install pipelines is a PCF deployment that matches the [Pivotal reference architecture](http://docs.pivotal.io/pivotalcf/refarch), usually using three availability zones and opting for high-availability components whenever possible.

## Usage
1. Create:
* A versioned bucket for holding terraform state.
* A versioned bucket for holding the generated `install-brkt-pcf` pipeline
* A versioned bucket for holding the bracketized Ops Manager AMI

2. Ensure [the prerequisites are met](https://docs.pivotal.io/pivotalcf/1-12/customizing/aws.html#prerequisities), in particular:

* A key pair to use with your PCF deployment. For more information, see the AWS documentation about [creating a key pair](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-keypair.html).
* Create a public DNS zone, get its zone ID and place it in `params.yml` under `ROUTE_53_ZONE_ID`
* [Generate a certificate](http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-server-cert.html#create-cert) for the domain used in the public DNS zone.

3. Change all of the CHANGEME values in `params.yml` with real values.

4. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated `params.yml`:
  ```
  fly -t your_target set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
  ```

5. Unpause the pipeline

6. Run `build-install-brkt-pcf-pipeline`. A new pipeline with the name defined in `params.yml` should be added.

7. In the generated pipeline:
* Run `bootstrap-terraform-state` job manually. This will prepare the s3 resource that holds the terraform state. This only needs to be run once. This will create a `terraform.tfstate` file in the configured S3 bucket. Note that the `terraform.tfstate` file contains plaintext secrets, so secure your bucket!
* `create-infrastructure` will automatically upload the latest matching version of Operations Manager
* Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.
