# Remote state: encrypted, locked, on Cloudflare R2

State is local today (`orgs/*/terraform.tfstate`, git-ignored), which means
only one machine can plan or apply and CI can't run at all. This is the plan
to move it to Cloudflare R2. Nothing below has been done yet.

| Concern | How |
| --- | --- |
| Storage | R2 bucket `qezta-tofu-state`, through the S3 backend (`root.hcl`) |
| Locking | OpenTofu's native S3 lock file (`use_lockfile = true`, OpenTofu ≥ 1.10). Relies on R2 honouring conditional writes (`If-None-Match`). **Verify in step 4 before relying on it.** |
| Encryption | OpenTofu client-side state encryption (AES-GCM, PBKDF2 passphrase), configured through the `TF_ENCRYPTION` environment variable so no key material is ever in the repository |
| Switch | `TOFU_REMOTE_STATE=true`; unset means the local backend |

## Bootstrap

1. **Create the bucket** in the Cloudflare dashboard (R2 → Create bucket →
   `qezta-tofu-state`, location hint near you). Keep it private.

1. **Create an R2 API token** scoped to that bucket with Object Read & Write.
   Note the access key ID, secret, and your Cloudflare account ID.

1. **Choose an encryption passphrase** (at least 16 characters; store it in
   your password manager and in the secrets repo with ragenix). Build the
   `TF_ENCRYPTION` value:

   ```hcl
   key_provider "pbkdf2" "state" {
     passphrase = "<passphrase>"
   }
   method "aes_gcm" "state" {
     keys = key_provider.pbkdf2.state
   }
   state {
     method = method.aes_gcm.state
     # Only for the first migration, so the existing unencrypted state can be
     # read. Remove after step 5.
     fallback {}
   }
   plan {
     method = method.aes_gcm.state
   }
   ```

1. **Test locking.** In a scratch unit pointed at the bucket, start two
   `tofu apply` runs at once; the second must fail to acquire the lock. If it
   doesn't, R2 isn't honouring conditional writes: stop and use a different
   locking approach before moving real state.

1. **Migrate** each unit:

   ```sh
   export TOFU_REMOTE_STATE=true CLOUDFLARE_ACCOUNT_ID=... \
     AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... TF_ENCRYPTION="$(cat encryption.hcl)"
   cd orgs/Qezta && terragrunt init -migrate-state
   terragrunt plan   # must show the same changes as before
   ```

   Then remove `fallback {}` from `TF_ENCRYPTION`, run `terragrunt plan` again
   to confirm the encrypted state reads, and delete the local state files.

1. **Enable CI**: add repository secrets `R2_ACCESS_KEY_ID`,
   `R2_SECRET_ACCESS_KEY`, `TF_ENCRYPTION` and `QEZTA_INFRA_TOKEN` (a token
   with `repo` and `admin:org`), the variable `CLOUDFLARE_ACCOUNT_ID`, then set
   the variable `REMOTE_STATE_ENABLED=true`. Pull requests then get a plan
   comment, and merges to `main` wait for approval in the `infra-apply`
   environment before applying.
