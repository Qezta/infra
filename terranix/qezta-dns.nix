## qezta.com on Cloudflare: DNS records and Email Routing, plus the
## nameserver cutover at Spaceship (the registrar). Runbook and staging:
## docs/dns-migration.md. Stages are controlled by Terragrunt inputs:
##   cutover        point the registrar's nameservers at Cloudflare
##   enable_dnssec  sign the zone on Cloudflare (after the cutover)
{lib, ...}: let
  domain = "qezta.com";

  ## Records Spaceship DNS serves today (public DNS, 2026-11-17).
  ## TODO(divit): confirm against a full export from the Spaceship dashboard;
  ## names nobody queries can't be discovered from outside.
  ## Spaceship's email-forwarding MX/SPF are deliberately absent: Email
  ## Routing publishes its own, and two SPF records would break SPF.
  records = {
    apex = {
      type = "A";
      name = "@";
      content = "216.198.79.1";
      comment = "Vercel: qezta.com";
    };
    www = {
      type = "CNAME";
      name = "www";
      content = "1066d2359f768c2c.vercel-dns-017.com";
      comment = "Vercel: www.qezta.com";
    };
    divit = {
      type = "CNAME";
      name = "divit";
      content = "4deef02f11d29c72.vercel-dns-017.com";
      comment = "Vercel: divit.qezta.com";
    };
    google-site-verification = {
      type = "TXT";
      name = "@";
      content = "google-site-verification=ejJP8qgpK_Wox4e1eVaZirMQ4aPrAI7yfYdM8UwsBcg";
      comment = "Google Search Console";
    };
    ## Monitoring only. TODO(divit): add rua=mailto:<reports mailbox>, then
    ## tighten. Don't tighten while sending as @qezta.com through Gmail:
    ## that mail isn't aligned for qezta.com and would be rejected.
    dmarc = {
      type = "TXT";
      name = "_dmarc";
      content = "v=DMARC1; p=none";
      comment = "DMARC";
    };
  };

  ## Addresses forwarded to var.email_forward_to.
  forwards = ["divit" "hello" "hi" "security" "privacy" "legal"];
in {
  terraform.required_version = ">= 1.10";
  terraform.required_providers = {
    cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
    spaceship = {
      source = "namecheap/spaceship";
      version = "~> 1.0";
    };
  };
  ## Credentials: CLOUDFLARE_API_TOKEN, SPACESHIP_API_KEY, SPACESHIP_API_SECRET.
  provider = {
    cloudflare = {};
    spaceship = {};
  };

  variable = {
    cloudflare_account_id = {
      description = "Cloudflare account that owns the zone.";
      type = "string";
    };
    email_forward_to = {
      description = "Inbox that receives every forwarded address. From the environment; never committed.";
      type = "string";
      sensitive = true;
    };
    cutover = {
      description = "Point qezta.com's nameservers at Cloudflare (registrar change).";
      type = "bool";
      default = false;
    };
    enable_dnssec = {
      description = "Sign the zone on Cloudflare. Only after the cutover; then publish the DS at Spaceship.";
      type = "bool";
      default = false;
    };
  };

  resource = {
    cloudflare_zone.qezta = {
      account.id = "\${var.cloudflare_account_id}";
      name = domain;
      type = "full";
      lifecycle.prevent_destroy = true;
    };

    cloudflare_dns_record =
      lib.mapAttrs (_: r: {
        zone_id = "\${cloudflare_zone.qezta.id}";
        inherit (r) type name content comment;
        ## 1 = automatic. Vercel needs DNS-only records, never proxied.
        ttl = 1;
        proxied = false;
      })
      records;

    ## Turns on Email Routing and publishes its MX, SPF and DKIM records.
    cloudflare_email_routing_dns.qezta = {
      zone_id = "\${cloudflare_zone.qezta.id}";
      name = domain;
    };

    ## Cloudflare emails a verification link here; rules forward nothing
    ## until it is clicked.
    cloudflare_email_routing_address.inbox = {
      account_id = "\${var.cloudflare_account_id}";
      email = "\${var.email_forward_to}";
    };

    cloudflare_email_routing_rule = lib.listToAttrs (map (local:
      lib.nameValuePair local {
        zone_id = "\${cloudflare_zone.qezta.id}";
        name = "${local}@${domain}";
        enabled = true;
        matchers = [
          {
            type = "literal";
            field = "to";
            value = "${local}@${domain}";
          }
        ];
        actions = [
          {
            type = "forward";
            value = ["\${cloudflare_email_routing_address.inbox.email}"];
          }
        ];
      })
    forwards);

    ## The cutover. Refused by a Terragrunt hook while a DS record is still
    ## published (see dns/qezta.com/terragrunt.hcl).
    spaceship_domain.qezta = {
      count = "\${var.cutover ? 1 : 0}";
      inherit domain;
      nameservers = {
        provider = "custom";
        hosts = "\${cloudflare_zone.qezta.name_servers}";
      };
      depends_on = ["cloudflare_dns_record.apex" "cloudflare_email_routing_dns.qezta"];
    };

    cloudflare_zone_dnssec.qezta = {
      count = "\${var.enable_dnssec ? 1 : 0}";
      zone_id = "\${cloudflare_zone.qezta.id}";
      status = "active";
    };
  };

  output = {
    name_servers.value = "\${cloudflare_zone.qezta.name_servers}";
    ## Publish this at Spaceship after enable_dnssec.
    ds_record.value = "\${try(cloudflare_zone_dnssec.qezta[0].ds, null)}";
  };
}
