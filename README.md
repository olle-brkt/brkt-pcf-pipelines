# brkt-pcf-pipelines

This repo is a collection of operations, tasks and other resources to create PCF deployments secured by Bracket.

<!-- TOC -->
- [The `install-brkt-pcf` pipeline](#the-install-brkt-pcf-pipeline)
    - [Usage](#usage)
        - [Patching the stock pipeline](#patching-the-stock-pipeline)
        - [Deploying and running the pipeline](#deploying-and-running-the-pipeline)
    - [Tearing down the environment](#tearing-down-the-environment)
    - [Known Issues](#known-issues)
    - [Troubleshooting](#troubleshooting)

<!-- /TOC -->

<br>

# The `install-brkt-pcf` pipeline

From the docs:

"This pipeline uses Terraform to create the infrastructure required to run a
3 AZ PCF deployment on AWS per the Customer [reference
architecture](http://docs.pivotal.io/pivotalcf/refarch/aws/aws_ref_arch.html).

This pipeline downloads artifacts from DockerHub (czero/rootfs and custom
docker-image resources) and the configured S3 bucket
(terraform.tfstate file), and as such the Concourse instance must have access
to those. Note that Terraform outputs a .tfstate file that contains plaintext
secrets."

## Usage

### Patching the stock pipeline
The `install-brkt-pcf` pipeline is generated by performing a set of `yaml-patch`operations
on the stock [`pipeline.yml`](https://github.com/pivotal-cf/pcf-pipelines/blob/v0.23.0/install-pcf/aws/pipeline.yml) from the [pcf-pipelines](https://github.com/pivotal-cf/pcf-pipelines) project.


Requirements:
* [`yaml-patch`](https://github.com/pivotal-cf/yaml-patch)
* [`fly`](https://concourse.ci/fly-cli.html) 
```
fly format-pipeline -c <(cat path/to/pcf-pipeline/install-pcf/aws/pipeline.yml | yaml-patch --ops-file path/to/brkt-pcf-pipelines/operations/brktize.yml) > patched-pipeline.yml
```

---
### Deploying and running the pipeline

With the pipeline patched, the usage of this pipeline is identical with the [usage](https://github.com/pivotal-cf/pcf-pipelines/blob/v0.23.0/install-pcf/aws/README.md#usage) of the stock pipeline, **with the exception of step 3 and 4:**
* In step 3, we also need to update the [`brkt-params.yml`](https://github.com/olle-brkt/brkt-pcf-pipelines/blob/master/install-brkt-pcf/brkt-params.yml).
* In step 4, we use the patched [`pipeline.yml` from the instructions above](https://github.com/olle-brkt/brkt-pcf-pipelines#patching-the-stock-pipeline) and we also use load params from `brkt-params.yml` when setting the pipeline.

Steps 1, 2 and 5-8 are just copied over from the pcf-pipelines project for convenience.

1. Create a versioned bucket for holding terraform state.

2. Ensure [the prerequisites are met](https://docs.pivotal.io/pivotalcf/1-12/customizing/aws.html#prerequisities), in particular:

* A key pair to use with your PCF deployment. For more information, see the AWS documentation about [creating a key pair](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-keypair.html).
* Create a public DNS zone, get its zone ID and place it in params.yml under `ROUTE_53_ZONE_ID`
* [Generate a certificate](http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-server-cert.html#create-cert) for the domain used in the public DNS zone.

3. Change all of the CHANGEME values in [`params.yml`](https://github.com/pivotal-cf/pcf-pipelines/blob/v0.23.0/install-pcf/aws/params.yml) and [`brkt-params.yml`](https://github.com/olle-brkt/brkt-pcf-pipelines/blob/master/install-brkt-pcf/brkt-params.yml) with real values.

4. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using the patched [`pipeline.yml` from the instructions above](https://github.com/olle-brkt/brkt-pcf-pipelines#patch-the-stock-pipeline), your updated `params.yml` and your updated `brkt-params.yml`:
  ```
  fly -t target set-pipeline -p deploy-brkt-pcf -c patched-pipeline.yml -l params.yml -l brkt-params.yml
  ```

5. Unpause the pipeline

6. Run `bootstrap-terraform-state` job manually. This will prepare the s3 resource that holds the terraform state. This only needs to be run once.

7. `create-infrastructure` will automatically upload the latest matching version of Operations Manager

8. Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.

### Tearing down the environment

There is a job, `wipe-env`, which you can run to destroy the infrastructure
that was created by `create-infrastructure`.

If you want to bring the environment up again, run `create-infrastructure`.

Do NOT use username `admin` for any of database credentials that you configure for this pipeline.

### Known Issues
see: https://github.com/pivotal-cf/pcf-pipelines/blob/v0.23.0/install-pcf/aws/README.md#known-issues

### Troubleshooting
see: https://github.com/pivotal-cf/pcf-pipelines/blob/v0.23.0/install-pcf/aws/README.md#troubleshooting
