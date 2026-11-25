## qezta.com on Cloudflare: DNS records and Email Routing, plus the
## nameserver cutover at Spaceship (the registrar). Runbook and staging:
## docs/dns-migration.md. Stages are controlled by Terragrunt inputs:
##   cutover        point the registrar's nameservers at Cloudflare
##   email_routing  swap Spaceship forwarding for Cloudflare Email Routing
##                  (needs an active zone, i.e. after the cutover)
##   enable_dnssec  sign the zone on Cloudflare (after the cutover)
{lib, ...}: let
  domain = "qezta.com";

  ## Every custom record Spaceship DNS serves (Spaceship API export,
  ## 2026-11-19). Mail records are separate (see `transitional`).
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
    www-divit = {
      type = "CNAME";
      name = "www.divit";
      content = "4deef02f11d29c72.vercel-dns-017.com";
      comment = "Vercel: www.divit.qezta.com";
    };
    divit-dnslink = {
      type = "TXT";
      name = "_dnslink.divit";
      content = "dnslink=/ipns/k51qzi5uqu5dhpcpz3aoftwf32m7gkgdw0i4tlac9ercttqdzukhtfma4lxpsa";
      comment = "IPNS: static portfolio published by T3";
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

  ## Spaceship email forwarding's records, present until `email_routing`
  ## switches mail to Cloudflare. Email Routing only works on an active zone,
  ## so these keep mail flowing across the nameserver cutover. Removing them
  ## and enabling Email Routing happen together (two SPF records would break
  ## SPF).
  transitional = {
    spaceship-mx1 = {
      type = "MX";
      name = "@";
      content = "mx1.efwd.spaceship.net";
      priority = 0;
      comment = "Spaceship email forwarding (until Email Routing)";
    };
    spaceship-mx2 = {
      type = "MX";
      name = "@";
      content = "mx2.efwd.spaceship.net";
      priority = 0;
      comment = "Spaceship email forwarding (until Email Routing)";
    };
    spaceship-spf = {
      type = "TXT";
      name = "@";
      content = "\"v=spf1 include:spf.efwd.spaceship.net ~all\"";
      comment = "Spaceship email forwarding (until Email Routing)";
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
    email_routing = {
      description = "Switch mail from Spaceship forwarding to Cloudflare Email Routing. Needs an active zone (after the cutover).";
      type = "bool";
      default = false;
    };
    enable_dnssec = {
      description = "Sign the zone on Cloudflare. Only after the cutover; then publish the DS at Spaceship.";
      type = "bool";
      default = false;
    };
    portfolio_ssh_ipv4 = {
      description = "Verified public IPv4 for the homelab SSH portfolio, not the router LAN or CGNAT address.";
      type = "string";
      default = null;
      validation = {
        condition = "\${var.portfolio_ssh_ipv4 == null ? true : can(cidrnetmask(format(\"%s/32\", var.portfolio_ssh_ipv4)))}";
        error_message = "The portfolio SSH address must be IPv4.";
      };
    };
  };

  resource = {
    # The registrar still serves DNS before cutover. Manage only the SSH
    # record there, never the whole custom-record set.
    spaceship_dns_record.portfolio-ssh = {
      count = "\${var.portfolio_ssh_ipv4 != null && !var.cutover ? 1 : 0}";
      inherit domain;
      type = "A";
      name = "ssh";
      address = "\${var.portfolio_ssh_ipv4}";
      ttl = 300;
      lifecycle.create_before_destroy = true;
    };

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
      records
      // {
        portfolio-ssh = {
          count = "\${var.portfolio_ssh_ipv4 == null ? 0 : 1}";
          zone_id = "\${cloudflare_zone.qezta.id}";
          type = "A";
          name = "ssh";
          content = "\${var.portfolio_ssh_ipv4}";
          comment = "Qezta SSH portfolio on T3 (not admin SSH)";
          ttl = 300;
          proxied = false;
        };
      }
      ## Spaceship forwarding's MX/SPF carry mail across the cutover, until
      ## Email Routing (which needs an active zone) replaces them.
      // lib.mapAttrs (_: r:
        {
          count = "\${var.email_routing ? 0 : 1}";
          zone_id = "\${cloudflare_zone.qezta.id}";
          inherit (r) type name content comment;
          ttl = 1;
          proxied = false;
        }
        // lib.optionalAttrs (r ? priority) {inherit (r) priority;})
      transitional;

    ## Turns on Email Routing and publishes its MX, SPF and DKIM records.
    cloudflare_email_routing_dns.qezta = {
      count = "\${var.email_routing ? 1 : 0}";
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
        count = "\${var.email_routing ? 1 : 0}";
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
      depends_on = ["cloudflare_dns_record.apex"];
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
