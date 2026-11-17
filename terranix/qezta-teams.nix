## GitHub teams, memberships and repository access, generated from the
## company projection (data/company/projection.json, exported by the private
## Qezta/company repo). Only roles with a `githubTeam` become teams.
##
## Teams are deliberately flat: in GitHub a child team inherits its parent's
## repository access, so mirroring the role tree (founder over engineering)
## would hand every team the founders' admin rights.
{lib, ...}: let
  projection = builtins.fromJSON (builtins.readFile ../data/company/projection.json);
  repos = import ./qezta-repositories.nix;
  members = import ./qezta-members.nix;

  teamRoles = lib.filterAttrs (_: r: r.githubTeam != null) projection.roles;
  teamOf = role: projection.roles.${role}.githubTeam or null;

  ## Systems hosted in this org, keyed by repository name.
  orgPrefix = "Qezta/";
  orgSystems = lib.filterAttrs (_: s: s.repo != null && lib.hasPrefix orgPrefix s.repo) projection.systems;
  repoName = s: lib.removePrefix orgPrefix s.repo;

  ## Teams need at least write access for CODEOWNERS to accept them, so code
  ## owners get max(their role's permission, push).
  rank = {
    pull = 0;
    triage = 1;
    push = 2;
    maintain = 3;
    admin = 4;
  };
  maxPerm = a: b:
    if rank.${a} >= rank.${b}
    then a
    else b;
  grants = lib.concatLists (lib.mapAttrsToList (_: s:
    (let
      t = teamOf s.owner;
    in
      lib.optional (t != null) {
        team = t;
        repo = repoName s;
        permission = projection.roles.${s.owner}.githubPermission;
      })
    ++ lib.concatMap (rule:
      lib.concatMap (role: let
        t = teamOf role;
      in
        lib.optional (t != null) {
          team = t;
          repo = repoName s;
          permission = maxPerm projection.roles.${role}.githubPermission "push";
        })
      rule.owners)
    s.codeowners)
  orgSystems);
  access = lib.foldl' (acc: g: let
    key = "${g.team}:${g.repo}";
  in
    acc
    // {
      ${key} = {
        inherit (g) team repo;
        permission =
          if acc ? ${key}
          then maxPerm acc.${key}.permission g.permission
          else g.permission;
      };
    }) {}
  grants;

  memberships = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (_: r:
    map (login:
      lib.nameValuePair "${r.githubTeam}:${login}" {
        team = r.githubTeam;
        username = login;
      })
    r.githubMembers)
  teamRoles));

  unmanagedRepos = lib.filter (name: !(repos ? ${name})) (lib.unique (map (a: a.repo) (lib.attrValues access)));
  strangers = lib.filter (login: !(members ? ${login})) (lib.unique (lib.concatMap (r: r.githubMembers) (lib.attrValues teamRoles)));
in
  assert unmanagedRepos == [] || throw "Projection references repos not in qezta-repositories.nix: ${toString unmanagedRepos}";
  assert strangers == [] || throw "Projection team members are not org members in qezta-members.nix: ${toString strangers}"; {
    locals = {
      teams = lib.mapAttrs' (_: r:
        lib.nameValuePair r.githubTeam {
          inherit (r) description;
        })
      teamRoles;
      team_memberships =
        lib.mapAttrs (_: m: {
          inherit (m) team username;
          ## Org owners can only be team maintainers; anything else diffs forever.
          role =
            if members.${m.username} == "admin"
            then "maintainer"
            else "member";
        })
        memberships;
      team_access = access;
    };

    resource.github_team.teams = {
      for_each = "\${local.teams}";
      name = "\${each.key}";
      description = "\${each.value.description}";
      privacy = "closed";
    };

    resource.github_team_membership.members = {
      for_each = "\${local.team_memberships}";
      team_id = "\${github_team.teams[each.value.team].id}";
      username = "\${each.value.username}";
      role = "\${each.value.role}";
    };

    resource.github_team_repository.access = {
      for_each = "\${local.team_access}";
      team_id = "\${github_team.teams[each.value.team].id}";
      repository = "\${github_repository.repos[each.value.repo].name}";
      permission = "\${each.value.permission}";
    };

    output.team_access.value = "\${{for k, a in local.team_access : k => a.permission}}";
  }
