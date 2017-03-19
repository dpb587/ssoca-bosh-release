# Development

Release resources can be managed by [Terraform](https://www.terraform.io/).

    $ LASTPASS_NOTE="${LASTPASS_PREFIX:-}$( git remote get-url origin )/terraform.tfstate"
    $ lpass show --sync=now --notes -G "${LASTPASS_NOTE}" > terraform.tfstate
    $ terraform plan
    $ terraform apply
    $ lpass edit --sync=now --non-interactive --notes "${LASTPASS_NOTE}" < terraform.tfstate
