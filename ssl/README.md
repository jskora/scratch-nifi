Scripts to facilitate creation and use of a self signed SSL Certificate Authority (CA) infrastructure.

script | description
------ | -----------
`make_test_ca.sh` | creates keys and certificates for a self signed root CA, an intermediate CA, and OCSP validation.
`make_test_ca_cfg.sh` | sets up configuration needed by scripts.
`make_test_entity.sh` | creates a server or client certificates signed by the intermediate CA.
`check_certs_status.sh` | checks the validity and revocation status of existing certificates created by intermediate CA (revocation depends on a running OCSP validation service).
`revoke_test_entity.sh` | revokes a server or client certificate.
~~`make_test2.sh`~~ | old test code (to be removed)
