# ssoca-bosh-release

A [BOSH](https://bosh.io/) release to deploy [ssoca](https://github.com/dpb587/ssoca).


## Example

The [`src/bosh-lite-allinone/deployment.yml`](src/bosh-lite-allinone/deployment.yml) deployment manifest provides a sample configuration which can be used with [`bosh-lite`](https://github.com/cloudfoundry/bosh-lite). Configure an authentication provider (like Google) and then try connecting to the built-in OpenVPN + SSH server after authenticating.

    # configure ssoca_auth_type and ssoca_auth_options per https://dpb587.github.io/ssoca/authn/
    bosh deploy -n --vars-file /tmp/allinone-auth.yml --vars-store /tmp/allinone-store.yml src/bosh-lite-allinone/deployment.yml

    # add the ip address to /etc/hosts for ssoca.bosh-lite.com
    bosh instances

    # open the ui
    open https://ssoca.bosh-lite.com:18705/

    # download client
    alias ssoca=~/Downloads/ssoca-client-*-darwin-amd64

    # add the environment
    ssoca env add https://ssoca.bosh-lite.com:18705 --ca-cert <( bosh int --path /ca/ca /tmp/allinone-store.yml )

    # login
    ssoca auth login

    # try a service
    ssoca ssh exec
    ssoca openvpn connect


## License

[MIT License](LICENSE)
