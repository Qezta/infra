_: let
  repos = import ./qezta-repositories.nix;
  repoNames = builtins.attrNames repos;

  ## Validated at `nix build` time, before OpenTofu ever sees the config.
  active = builtins.filter (n: !(repos.${n}.archived or false)) repoNames;
  missingDescription = builtins.filter (n: (repos.${n}.description or "") == "") active;
  badWorkflowPerms =
    builtins.filter
    (n: !(builtins.elem (repos.${n}.workflow_permissions or "read") ["read" "write"]))
    repoNames;
in
  assert missingDescription == [] || throw "Repos missing a description: ${toString missingDescription}";
  assert badWorkflowPerms == [] || throw "workflow_permissions must be \"read\" or \"write\" for: ${toString badWorkflowPerms}"; {
    terraform.required_version = ">= 1.10";

    terraform.required_providers.github = {
      source = "integrations/github";
      version = "~> 6.0";
    };

    provider.github = {
      owner = "Qezta";
      token = "\${var.github_token}";
    };

    variable.github_token = {
      description = "GitHub PAT for the Qezta organization.";
      type = "string";
      sensitive = true;
    };

    ## Teams, memberships, repository access and rulesets come from the
    ## company projection; org settings and CI environments are separate.
    imports = [
      ./qezta-teams.nix
      ./qezta-rulesets.nix
      ./qezta-org.nix
      ./qezta-ci.nix
      ./qezta-actions-environments.nix
    ];

    locals.repos = repos;

    resource.github_repository.repos = {
      for_each = "\${local.repos}";
      name = "\${each.key}";
      description = "\${each.value.description}";
      visibility = "\${each.value.visibility}";
      has_issues = true;
      has_wiki = false;
      has_projects = false;
      archived = "\${try(each.value.archived, false)}";
      delete_branch_on_merge = "\${each.value.delete_branch_on_merge}";
      topics = "\${each.value.topics}";
      homepage_url = "\${try(each.value.homepage_url, null)}";
      ## GitHub switches Dependabot alerts off on archived repos and won't
      ## turn them back on, so only ask for them on active public repos.
      vulnerability_alerts = "\${each.value.visibility == \"public\" && !try(each.value.archived, false)}";
      lifecycle = {
        prevent_destroy = true;
        ignore_changes = ["auto_init"];
      };
    };

    ## Settings → Actions → General → Workflow permissions. Defaults to a
    ## read-only GITHUB_TOKEN that may still open PRs (update-flake-lock needs
    ## that). Archived repos are read-only on GitHub, so the API rejects changes.
    ## Creating this resource just writes the setting; no import is needed.
    resource.github_workflow_repository_permissions.repos = {
      for_each = "\${{for k, v in local.repos : k => v if !try(v.archived, false)}}";
      repository = "\${github_repository.repos[each.key].name}";
      default_workflow_permissions = "\${try(each.value.workflow_permissions, \"read\")}";
      can_approve_pull_request_reviews = "\${try(each.value.actions_can_create_prs, true)}";
    };

    ## Adopt repos that already exist on GitHub; `existing = false` marks one
    ## for OpenTofu to create instead (the flag can stay once created).
    import =
      map (name: {
        to = "github_repository.repos[\"${name}\"]";
        id = name;
      })
      (builtins.filter (name: repos.${name}.existing or true) repoNames);

    moved =
      map (name: {
        from = "module.repositories.github_repository.repos[\"${name}\"]";
        to = "github_repository.repos[\"${name}\"]";
      })
      repoNames;

    output = {
      repo_urls.value = "\${{for name, repo in github_repository.repos : name => repo.html_url}}";
      private_repos.value = "\${[for name, repo in github_repository.repos : name if repo.visibility == \"private\"]}";
      repo_count.value = "\${length(github_repository.repos)}";
      write_workflow_repos.value = "\${[for k, r in github_workflow_repository_permissions.repos : k if r.default_workflow_permissions == \"write\"]}";
    };
  }
