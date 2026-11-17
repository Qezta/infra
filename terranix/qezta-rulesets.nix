## Default-branch rulesets for public repositories: changes land through pull
## requests, no force pushes, no branch deletion. Org admins may bypass only
## inside a pull request (e.g. to merge with a failing check), never by
## pushing directly. Rulesets need a paid plan on private repos, and the org is
## on GitHub Free, so private repos are skipped.
{lib, ...}: let
  repos = import ./qezta-repositories.nix;
  githubActionsAppId = 15368; # https://api.github.com/apps/github-actions
  eligible = lib.filterAttrs (_: r: r.visibility == "public" && !(r.archived or false)) repos;

  ## One resource per repository: nested blocks differ per repo, which
  ## for_each can't express without dynamic blocks.
  resourceName = name: "default_branch_${lib.replaceStrings ["." "-"] ["dot_" "_"] name}";

  ruleset = name: r: {
    inherit name;
    repository = "\${github_repository.repos[\"${name}\"].name}";
    target = "branch";
    enforcement = "active";
    conditions.ref_name = {
      include = ["~DEFAULT_BRANCH"];
      exclude = [];
    };
    bypass_actors =
      [
        ## OrganizationAdmin takes no actor_id.
        {
          actor_type = "OrganizationAdmin";
          bypass_mode = "pull_request";
        }
      ]
      ++ lib.optional (r.ruleset_bypass_actions or false) {
        actor_id = githubActionsAppId;
        actor_type = "Integration";
        bypass_mode = "always";
      };
    rules =
      {
        deletion = true;
        non_fast_forward = true;
        required_signatures = r.require_signed_commits or false;
        pull_request = {
          ## A one-person org can't approve its own pull requests.
          required_approving_review_count = 0;
          dismiss_stale_reviews_on_push = true;
          required_review_thread_resolution = true;
        };
      }
      // lib.optionalAttrs ((r.required_checks or []) != []) {
        required_status_checks = {
          required_check = map (context: {inherit context;}) r.required_checks;
          strict_required_status_checks_policy = false;
        };
      };
  };
in {
  resource.github_repository_ruleset = lib.mapAttrs' (name: r: lib.nameValuePair (resourceName name) (ruleset name r)) eligible;
}
