# Qezta secrets

This directory is reserved for encrypted age/ragenix secrets used by Qezta
infrastructure and CI.

Never commit plaintext credentials, API keys, Terraform state, or unencrypted
`.env` files. Add recipients and encrypted files only after the Qezta secrets
repository has been initialized with the intended age public keys.
