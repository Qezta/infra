## Organization-level settings and membership. Off by default: managing them
## needs a token with the admin:org scope. Turn on with
## QEZTA_MANAGE_ORG_SETTINGS=true (see orgs/Qezta/terragrunt.hcl).
##
## Not settable through the API or provider (do these by hand in
## Settings → Authentication security): requiring two-factor authentication.
{lib, ...}: let
  members = import ./qezta-members.nix;
  enabled = "\${var.manage_org_settings ? 1 : 0}";
in {
  variable = {
    manage_org_settings = {
      description = "Manage org settings, Actions policy and membership (needs admin:org).";
      type = "bool";
      default = false;
    };
    org_billing_email = {
      description = "Billing email for the Qezta org. From the environment; never committed.";
      type = "string";
      default = "";
      sensitive = true;
    };
  };

  resource.github_organization_settings.qezta = {
    count = enabled;
    billing_email = "\${var.org_billing_email}";
    default_repository_permission = "read";
    ## Repositories are created through this repository, not by hand.
    members_can_create_repositories = false;
    members_can_create_public_repositories = false;
    members_can_create_private_repositories = false;
    members_can_fork_private_repositories = false;
    dependabot_alerts_enabled_for_new_repositories = true;
    dependabot_security_updates_enabled_for_new_repositories = true;
    dependency_graph_enabled_for_new_repositories = true;
    secret_scanning_enabled_for_new_repositories = true;
    secret_scanning_push_protection_enabled_for_new_repositories = true;
    lifecycle.precondition = [
      {
        condition = "\${var.org_billing_email != \"\"}";
        error_message = "Set QEZTA_ORG_BILLING_EMAIL to manage org settings.";
      }
    ];
  };

  ## Current policy, codified. TODO(divit): switch to allowed_actions =
  ## "selected" and sha_pinning_required = true once every repo pins by SHA.
  resource.github_actions_organization_permissions.qezta = {
    count = enabled;
    enabled_repositories = "all";
    allowed_actions = "all";
  };

  locals.org_members = members;

  resource.github_membership.members = {
    for_each = "\${{for login, role in local.org_members : login => role if var.manage_org_settings}}";
    username = "\${each.key}";
    role = "\${each.value}";
    lifecycle.prevent_destroy = true;
  };

  import =
    lib.mapAttrsToList (login: _: {
      for_each = "\${toset([for l in [\"${login}\"] : l if var.manage_org_settings])}";
      to = "github_membership.members[\"${login}\"]";
      id = "Qezta:${login}";
    })
    members;
}
