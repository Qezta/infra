_: let
  repos = import ./qezta-repositories.nix;
  repoNames = builtins.attrNames repos;
in {
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

  locals.repos = repos;

  resource.github_repository.repos = {
    for_each = "\${local.repos}";
    name = "\${each.key}";
    description = "\${each.value.description}";
    visibility = "\${each.value.visibility}";
    has_issues = true;
    has_wiki = false;
    has_projects = false;
    archived = false;
    delete_branch_on_merge = "\${each.value.delete_branch_on_merge}";
    topics = "\${each.value.topics}";
    homepage_url = "\${try(each.value.homepage_url, null)}";
    vulnerability_alerts = "\${each.value.visibility == \"public\" ? true : false}";
    lifecycle = {
      prevent_destroy = true;
      ignore_changes = ["auto_init"];
    };
  };

  import =
    map (name: {
      to = "github_repository.repos[\"${name}\"]";
      id = name;
    })
    repoNames;

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
  };
}
