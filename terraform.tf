variable "release_name"   { default = "ssoca" }
variable "release_repo"   { default = "ssoca-bosh-release" }
variable "release_owner"  { default = "dpb587" }
variable "region1"         { default = "us-east-1" }
variable "region2"         { default = "us-west-2" }

provider "aws" {
  region = "${var.region1}"
}

#
# bosh
#

data "template_file" "config_final" {
  template = <<EOF
name: $${name}
blobstore:
  provider: s3
  options:
    bucket_name: $${bucket}
    region: $${region}
EOF

  vars {
    name = "${var.release_name}"
    region = "${aws_s3_bucket.bucket.region}"
    bucket = "${aws_s3_bucket.bucket.bucket}"
  }
}

resource "null_resource" "config_final" {
  triggers {
    config_final = "${data.template_file.config_final.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.config_final.rendered}' > ${path.module}/config/final.yml"
  }
}

data "template_file" "config_private" {
  template = <<EOF
blobstore:
  options:
    access_key_id: "$${access_key_id}"
    secret_access_key: "$${secret_access_key}"
EOF

  vars {
    access_key_id = "${aws_iam_access_key.user.id}"
    secret_access_key = "${aws_iam_access_key.user.secret}"
  }
}

resource "null_resource" "config_private" {
  triggers {
    config_private = "${data.template_file.config_private.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.config_private.rendered}' > ${path.module}/config/private.yml"
  }
}

#
# iam
#

resource "aws_iam_user" "user" {
  name = "${var.release_repo}"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
}

#
# s3
#

resource "aws_s3_bucket" "bucket" {
  region = "${var.region1}"
  bucket = "${var.release_owner}-${var.release_repo}-${var.region1}"
  versioning {
    enabled = true
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    effect = "Allow"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket.json}"
}

data "aws_iam_policy_document" "user_s3" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.bucket.arn}",
    ]
  }
}

resource "aws_iam_user_policy" "user_s3" {
    name = "s3"
    user = "${aws_iam_user.user.name}"
    policy = "${data.aws_iam_policy_document.user_s3.json}"
}
