import {
  for_each = local.repos
  to       = module.repositories.github_repository.repos[each.key]
  id       = each.key
}

module "repositories" {
  source = "../../modules/repositories"
  repos  = local.repos
}

module "branch_protection" {
  source             = "../../modules/branch-protection"
  repo_node_ids      = module.repositories.node_ids
  protected_branches = local.protected_branches
}
