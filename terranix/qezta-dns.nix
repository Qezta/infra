## Email DNS for qezta.com on Spaceship DNS.
##
## spaceship_dns_record manages one record at a time, so only the records
## listed here are touched. Do NOT switch to spaceship_dns_records (plural):
## it owns the whole custom record set and deletes anything not listed.
##
## Current state (dig, 2026-11-17): MX and SPF point at Spaceship email
## forwarding (mx1/mx2.efwd.spaceship.net, include:spf.efwd.spaceship.net),
## which Spaceship manages for the forwarding feature, so they are documented
## here but not managed. No DMARC and no DKIM exist yet.
{lib, ...}: let
  domain = "qezta.com";

  ## Records this module creates.
  records = {
    ## Monitoring-only DMARC to start. TODO(divit): add
    ## `rua=mailto:<reports mailbox>` once a mailbox exists, then tighten to
    ## p=quarantine and p=reject after reviewing reports.
    dmarc = {
      type = "TXT";
      name = "_dmarc";
      value = "v=DMARC1; p=none";
    };
    ## TODO(divit): when a sending provider is chosen (e.g. for transactional
    ## mail), add its DKIM selector record(s) and extend SPF accordingly.
  };
in {
  terraform.required_version = ">= 1.10";
  terraform.required_providers.spaceship = {
    source = "namecheap/spaceship";
    version = "~> 1.0";
  };
  ## Credentials come from SPACESHIP_API_KEY / SPACESHIP_API_SECRET.
  provider.spaceship = {};

  resource.spaceship_dns_record = lib.mapAttrs (_: r:
    {
      inherit domain;
      inherit (r) type name;
      ttl = 3600;
      ## Any change other than ttl replaces the record.
      lifecycle.create_before_destroy = true;
    }
    // lib.optionalAttrs (r ? value) {inherit (r) value;})
  records;
}
