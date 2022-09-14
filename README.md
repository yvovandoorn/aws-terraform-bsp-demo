# Catching Terraform Compliance Issues with Mondoo 

      * [Prerequisites](#prerequisites)
      * [Setup GitHub Repo](#setup-github-repo)
      * [Getting your first scan! (5 minutes)](#getting-your-first-scan-5-minutes)
            * [Method #1 - Via the GitHub Actions interface under the Scan with Mondoo step](#method-1---via-the-github-actions-interface-under-the-scan-with-mondoo-step)
            * [Method #2 (Recommended) - Via the <a href="https://console.mondoo.com/" rel="nofollow">Mondoo Console</a>.](#method-2-recommended---via-the-mondoo-console)
      * [Enforcing a score in the pipeline.](#enforcing-a-score-in-the-pipeline)
      * [Getting to a hundred (100)!](#getting-to-a-hundred-100)

### Prerequisites

- A place to maintain Terraform state. This repo uses a preconfigured S3 bucket to store state.
- An AWS account
- A GitHub repo
- Hashicorp's AWS v4 provider

### Setup GitHub Repo

Five (5) GitHub Action repository secrets need to be set. 

  - `AWS_ACCESS_KEY_ID` an AWS Access Key with sufficient access to create, modify and delete S3 buckets. It should also have access to the bucket where the terraform state is being stored. 
  - `AWS_REGION` which region the S3 bucket will be deployed in. This should be done in the [AWS region code format](https://docs.aws.amazon.com/general/latest/gr/rande.html), e.g. `us-east-2`, `ap-northeast-3`, or `eu-central-1`. 
  - `AWS_S3_BACKEND_BUCKET_NAME` the bucket where the Terraform state is kept. The code can easily be modified to use initiate another backend, such as [Terraform Cloud](https://www.hashicorp.com/products/terraform/pricing). 
  - `AWS_S3_FILES_BUCKET_NAME` the name of the bucket name that will be deployed. _Note: S3 buckets are globally uniquely named, so 'example' isn't going to be enough here._ 
  - `AWS_SECRET_ACCESS_KEY` the corresponding access key that is assigned to the `AWS_ACCESS_KEY_ID`.

### Getting your first scan! (5 minutes)

With the above setup, you should be off to the races to getting your first scan of this repo's Terraform file

1. Having done the setup of the environmental files above, your first run of GitHub Actions is to check if it all works.

1. Setup Mondoo
   1. Enable the Terraform policy
      1. Goto the [Mondoo Console](https://console.mondoo.com/) located at [https://console.mondoo.com/](https://console.mondoo.com/).
      1. Click on `Policy Hub`
      1. Click on `Add Policies`
      1. Click on the `[ ]` next to `Terraform Static Analysis Policy for AWS by Mondoo` and click on `Enable`.
   1. Get credentials for service account
      1. Goto the [Mondoo Console](https://console.mondoo.com/) located at [https://console.mondoo.com/](https://console.mondoo.com/).
      1. Click on `Settings` and then `Service Accounts`.
      1. Click on `+ Add Account`.
      1. Before clicking on `Generate New Credentials` check on the `[ ] Base64-encoded` checkbox.
      1. Now click on `Generate New Credentials`
      1. Click on the purple `Copy` button or simply select the encoded credentials and store it in your system's clipboard.
1. Further setup of GitHub
   1. Create a new GitHub Action repository secret called `MONDOO_SERVICE_ACCOUNT`. As value for the secret, paste the contents of your system's clipboard.
1. Modify the GitHub Action (`.github/workflows/deploy.yml`) in the repo and add Mondoo as a step before deploying the `Terraform code`. This should be around line 19. That code is:

   ```yaml
   - name: Scan with Mondoo
     uses: mondoohq/actions/terraform@main
     with:
       service-account-credentials: ${{ secrets.MONDOO_SERVICE_ACCOUNT }}
       path: "."
   ```

   This change can either be done in the GitHub interface or locally via your text editor of choice and then pushed to your repository. You can also chose to submit this as a PR to the repo or commit to the `main` branch.

1. Upon push from the above step, GitHub Actions will run and you will see Mondoo being setup & executed before Terraform. There are a few ways to look at the output.

   ##### Method #1 - Via the GitHub Actions interface under the `Scan with Mondoo` step

   ##### Method #2 (Recommended) - Via the [Mondoo Console](https://console.mondoo.com/).

   1. Goto the [Mondoo Console](https://console.mondoo.com/) located at [https://console.mondoo.com/](https://console.mondoo.com/).
   1. Click on `CI/CD` in the menu bar. You should see your repository that was just scanned listed. Click on it.
   1. Clicking on the policy, you see that the policy scored `82/100` (at time of writing this `README.md`). Click on it reveals which controls in the policy are failing.

### Enforcing a score in the pipeline.

You got here because you finished your first scan. Awesome. What if we added a score threshold so that a GitHub Action will fail if the score is lower than the threshold.

1. Goto your GitHub repo and modify the GitHub Action (`.github/workflows/deploy.yml`). You can chose to do this locally and pushing to the `main` branch (or as a PR to the `main` branch).
1. In the the `Scan with Mondoo` step (around line 20 if you followed the above steps). Add the following line under `path: '.'`:

   ```yaml
   score-threshold: "85"
   ```

1. Push or save the file.
1. GitHub Actions will immediately start executing.
1. The Action will fail as Mondoo quit with a non-zero exit, which GitHub Actions picks up.

### Getting to a hundred (100)!

So now your pipeline is in a broken state. You can remove the `score-threshold` _or_ we can beef up the existing Terraform configuration in order to get that shiny `100`.

The three controls (as of writing) that failed are:

- `✕ Fail: Ensure Amazon Simple Storage Service (Amazon S3) buckets are not publicly accessible`
- `✕ Fail: Ensure logging is enabled for your S3 buckets.`
- `✕ Fail: Ensure that versioning is enabled for your S3 buckets`

All three are [security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html set forth by AWS.

1. Add the following lines to the `main.tf` file at the root of this repository

   ```terraform
     resource "aws_s3_bucket_versioning" "files" {
       bucket = aws_s3_bucket.files.id
       versioning_configuration {
         status = "Enabled"
       }
     }

     resource "aws_s3_bucket_logging" "files" {
       bucket = aws_s3_bucket.files.id
       target_bucket = aws_s3_bucket.log_bucket.id
       target_prefix = "log-${aws_s3_bucket.files.id}/"
     }

     resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
     bucket = aws_s3_bucket.files.id
     rule {
       apply_server_side_encryption_by_default {
         kms_master_key_id = aws_kms_key.mykey.arn
         sse_algorithm = "aws:kms"
       }
     }
     }

     resource "aws_s3_bucket_public_access_block" "files" {
       bucket = aws_s3_bucket.files.id

       block_public_acls       = true
       block_public_policy     = true
       ignore_public_acls      = true
       restrict_public_buckets = true
     }

     # Setup the logging bucket
     resource "aws_s3_bucket" "log_bucket" {
       bucket = "${var.files-bucket-name}-logbucket"
     }

     resource "aws_s3_bucket_acl" "log_bucket" {
       bucket = aws_s3_bucket.log_bucket.id
       acl = "private"
     }

     resource "aws_s3_bucket_versioning" "log_bucket" {
       bucket = aws_s3_bucket.log_bucket.id
       versioning_configuration {
         status = "Enabled"
       }
     }

     resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
     bucket = aws_s3_bucket.log_bucket.id
     rule {
       apply_server_side_encryption_by_default {
         kms_master_key_id = aws_kms_key.mykey.arn
         sse_algorithm = "aws:kms"
       }
     }
     }

     resource "aws_s3_bucket_logging" "log_bucket" {
       bucket = aws_s3_bucket.log_bucket.id
       target_bucket = aws_s3_bucket.log_bucket2.id
       target_prefix = "log-${aws_s3_bucket.log_bucket.id}/"
     }

     resource "aws_s3_bucket_public_access_block" "log_bucket" {
       bucket = aws_s3_bucket.log_bucket.id

       block_public_acls       = true
       block_public_policy     = true
       ignore_public_acls      = true
       restrict_public_buckets = true
     }

     # Setup the second logging bucket
     resource "aws_s3_bucket" "log_bucket2" {
       bucket = "${var.files-bucket-name}-logbucket2"
     }

     resource "aws_s3_bucket_acl" "log_bucket2" {
       bucket = aws_s3_bucket.log_bucket2.id
       acl = "private"
     }

     resource "aws_s3_bucket_versioning" "log_bucket2" {
       bucket = aws_s3_bucket.log_bucket2.id
       versioning_configuration {
         status = "Enabled"
       }
     }

     resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket2" {
     bucket = aws_s3_bucket.log_bucket2.id
     rule {
       apply_server_side_encryption_by_default {
         kms_master_key_id = aws_kms_key.mykey.arn
         sse_algorithm = "aws:kms"
       }
     }
     }

     resource "aws_s3_bucket_logging" "log_bucket2" {
       bucket = aws_s3_bucket.log_bucket2.id
       target_bucket = aws_s3_bucket.log_bucket.id
       target_prefix = "log-${aws_s3_bucket.log_bucket2.id}/"
     }

     resource "aws_s3_bucket_public_access_block" "log_bucket2" {
       bucket = aws_s3_bucket.log_bucket2.id

       block_public_acls       = true
       block_public_policy     = true
       ignore_public_acls      = true
       restrict_public_buckets = true
     }
   ```

1. Save or push to the repo.
1. GitHub Actions starts running.
1. The Actions should pass and you're now deploying a more secure S3 bucket because of it!
