## The `infra-apply` environment that gates `tofu apply` in CI: a run waits
## for approval from these reviewers, and only `main` can deploy to it.
_: {
  resource.github_repository_environment.infra_apply = {
    repository = "\${github_repository.repos[\"infra\"].name}";
    environment = "infra-apply";
    ## A sole maintainer must be able to approve their own runs.
    prevent_self_review = false;
    reviewers.users = [17973568]; # DivitMittal
    deployment_branch_policy = {
      protected_branches = false;
      custom_branch_policies = true;
    };
  };

  resource.github_repository_environment_deployment_policy.infra_apply_main = {
    repository = "\${github_repository.repos[\"infra\"].name}";
    environment = "\${github_repository_environment.infra_apply.environment}";
    branch_pattern = "main";
  };
}
