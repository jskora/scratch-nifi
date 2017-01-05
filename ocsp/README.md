Scripts to facilitate:
* creating a self signed root Certificate Authority (CA),
* creating an intermediate CA signed by the root CA,
* creating server and client certificates signed by the intermediate CA,
* validating the existing server and client certificates, and
* running an OCSP validation service to confirm the revocation status of certificates.

{{check_certs_status.sh}} - lists status of existing certificates (revocation only shown if OCSP validation is running).
make_test_ca.sh - creates the root CA, intermediate CA, and OCSP certificates.
make_test_ca_cfg.sh - referenced by other scripts to eliminate duplicate setup code.
make_test_entity.sh - creates a server or client certificate.
revoke_test_entity.sh	- revokes a server or client certificate.

make_test2.sh - testing (to be removed)
