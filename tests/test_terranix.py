"""Invariants on the generated OpenTofu JSON (terranix output), checked without credentials.

`tofu plan` only runs once remote state exists and needs live tokens; these catch the mistakes
that would otherwise surface as a broken zone, an unprotected repo or a leaked address.
Paths come from the flake check (QEZTA_*_JSON); see flake/tests.nix.
"""
import json
import os
import re

import pytest


def _load(var):
    path = os.environ.get(var)
    if not path:
        pytest.skip(f"{var} not set (run via `nix flake check`)")
    with open(path) as f:
        return json.load(f)


@pytest.fixture(scope="module")
def dns():
    return _load("QEZTA_DNS_JSON")


@pytest.fixture(scope="module")
def github():
    return _load("QEZTA_GITHUB_JSON")


@pytest.fixture(scope="module")
def vercel():
    return _load("QEZTA_VERCEL_JSON")


DOMAIN = "qezta.com"
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")


def fqdn(name):
    return DOMAIN if name == "@" else f"{name}.{DOMAIN}"


def unconditional(r):
    return "count" not in r


# ---------------------------------------------------------------- DNS


def records(dns):
    return dns["resource"]["cloudflare_dns_record"]


def test_zone_cannot_be_destroyed(dns):
    assert dns["resource"]["cloudflare_zone"]["qezta"]["lifecycle"]["prevent_destroy"] is True


def test_records_are_dns_only_and_in_the_zone(dns):
    # Vercel's certificate issuance breaks behind the Cloudflare proxy.
    for key, r in records(dns).items():
        assert r["proxied"] is False, key
        assert r["zone_id"] == "${cloudflare_zone.qezta.id}", key


def test_cname_is_exclusive_and_never_at_apex(dns):
    by_name = {}
    for key, r in records(dns).items():
        by_name.setdefault(r["name"], []).append((key, r["type"]))
    for name, entries in by_name.items():
        types = [t for _, t in entries]
        if "CNAME" in types:
            assert name != "@", "CNAME at the zone apex"
            assert len(entries) == 1, f"CNAME {name} shares its name with {entries}"


def test_unconditional_records_are_unique(dns):
    seen = set()
    for key, r in records(dns).items():
        if not unconditional(r):
            continue
        ident = (r["type"], r["name"], r["content"])
        assert ident not in seen, f"duplicate record {key}: {ident}"
        seen.add(ident)


def test_spf_never_coexists_with_email_routing(dns):
    # Email Routing publishes its own SPF; two SPF TXT records at @ invalidate both.
    spf = {k: r for k, r in records(dns).items() if r["type"] == "TXT" and "v=spf1" in r["content"]}
    assert len([r for r in spf.values() if unconditional(r)]) == 0, "SPF must be gated on email_routing"
    for key, r in spf.items():
        assert r["count"] == "${var.email_routing ? 0 : 1}", key
    for key, r in records(dns).items():
        if r["type"] == "MX":
            assert r.get("count") == "${var.email_routing ? 0 : 1}", f"{key}: MX must hand over to Email Routing"
    assert dns["resource"]["cloudflare_email_routing_dns"]["qezta"]["count"] == "${var.email_routing ? 1 : 0}"


def test_txt_records_are_well_formed(dns):
    for key, r in records(dns).items():
        if r["type"] != "TXT":
            continue
        c = r["content"].strip('"')
        if r["name"] == "_dmarc":
            assert re.match(r"^v=DMARC1;\s*p=(none|quarantine|reject)\b", c), key
        if r["name"].startswith("_dnslink."):
            assert re.match(r"^dnslink=/(ipns|ipfs)/\S+$", c), key


def test_email_routing_rules_forward_only_qezta_addresses(dns):
    rules = dns["resource"]["cloudflare_email_routing_rule"]
    assert rules
    for key, rule in rules.items():
        assert rule["count"] == "${var.email_routing ? 1 : 0}", key
        (matcher,) = rule["matchers"]
        assert matcher["value"] == f"{key}@{DOMAIN}"
        (action,) = rule["actions"]
        assert action == {"type": "forward", "value": ["${cloudflare_email_routing_address.inbox.email}"]}


def test_forward_inbox_comes_from_a_sensitive_variable(dns):
    assert dns["resource"]["cloudflare_email_routing_address"]["inbox"]["email"] == "${var.email_forward_to}"
    assert dns["variable"]["email_forward_to"]["sensitive"] is True


@pytest.mark.parametrize("stack", ["dns", "github", "vercel"])
def test_no_personal_email_addresses_committed(stack, request):
    text = json.dumps(request.getfixturevalue(stack))
    leaked = {e for e in EMAIL_RE.findall(text) if not e.endswith(f"@{DOMAIN}")}
    assert not leaked, f"non-{DOMAIN} addresses in {stack} config: {leaked}"


def test_staged_resources_default_off(dns):
    v = dns["variable"]
    for flag in ("cutover", "email_routing", "enable_dnssec"):
        assert v[flag]["default"] is False, flag
    r = dns["resource"]
    assert r["spaceship_domain"]["qezta"]["count"] == "${var.cutover ? 1 : 0}"
    assert r["cloudflare_zone_dnssec"]["qezta"]["count"] == "${var.enable_dnssec ? 1 : 0}"
    # nameservers must not move before the apex record exists on Cloudflare
    assert "cloudflare_dns_record.apex" in r["spaceship_domain"]["qezta"]["depends_on"]


# ---------------------------------------------------------------- GitHub


def repos(github):
    return github["locals"]["repos"]


def test_repositories_cannot_be_destroyed(github):
    repo = github["resource"]["github_repository"]["repos"]
    assert repo["lifecycle"]["prevent_destroy"] is True


def test_every_active_public_repo_has_a_ruleset(github):
    rulesets = github["resource"]["github_repository_ruleset"]
    protected = {re.search(r'repos\["([^"]+)"\]', r["repository"]).group(1) for r in rulesets.values()}
    want = {n for n, r in repos(github).items() if r["visibility"] == "public" and not r.get("archived")}
    assert protected == want


def test_rulesets_block_history_rewrites(github):
    for key, r in github["resource"]["github_repository_ruleset"].items():
        assert r["enforcement"] == "active", key
        assert r["conditions"]["ref_name"]["include"] == ["~DEFAULT_BRANCH"], key
        assert r["rules"]["deletion"] is True, key
        assert r["rules"]["non_fast_forward"] is True, key
        for actor in r["bypass_actors"]:
            assert actor["bypass_mode"] == "pull_request", f"{key}: bypass outside PRs"


def test_required_checks_imply_pull_requests(github):
    for key, r in github["resource"]["github_repository_ruleset"].items():
        if "required_status_checks" in r["rules"]:
            assert "pull_request" in r["rules"], f"{key}: status checks without a PR requirement never run"


def test_imports_match_existing_repos(github):
    imported = {i["id"] for i in github["import"] if i["to"].startswith("github_repository.repos")}
    existing = {n for n, r in repos(github).items() if r.get("existing", True)}
    assert imported == existing
    for i in github["import"]:
        if i["to"].startswith("github_repository.repos"):
            assert i["to"] == f'github_repository.repos["{i["id"]}"]'


def test_archived_repos_get_no_actions_settings(github):
    perms = github["resource"]["github_workflow_repository_permissions"]["repos"]["for_each"]
    assert "!try(v.archived, false)" in perms


def test_team_access_targets_managed_repos(github):
    managed = set(repos(github))
    allowed = {"pull", "triage", "push", "maintain", "admin"}
    for key, a in github["locals"]["team_access"].items():
        assert a["repo"] in managed, key
        assert a["permission"] in allowed, key


def test_apply_environment_is_main_only(github):
    env = github["resource"]["github_repository_environment"]["infra_apply"]
    assert env["deployment_branch_policy"] == {"protected_branches": False, "custom_branch_policies": True}
    policy = github["resource"]["github_repository_environment_deployment_policy"]["infra_apply_main"]
    assert policy["branch_pattern"] == "main"


def test_org_settings_stay_opt_in(github):
    assert github["variable"]["manage_org_settings"]["default"] is False
    assert github["resource"]["github_organization_settings"]["qezta"]["count"] == "${var.manage_org_settings ? 1 : 0}"


# ---------------------------------------------------------------- Vercel (+ cross-stack)


def test_vercel_projects_cannot_be_destroyed(vercel):
    for key, p in vercel["resource"]["vercel_project"].items():
        assert p["lifecycle"]["prevent_destroy"] is True, key


def test_vercel_secrets_are_write_only(vercel):
    assert vercel["variable"]["gemini_api_key"]["ephemeral"] is True
    for key, e in vercel["resource"]["vercel_project_environment_variable"].items():
        assert "value" not in e, f"{key}: plain `value` would be stored in state"
        assert e["value_wo"].startswith("${var."), key
        assert e["sensitive"] is True, key


def test_vercel_domain_redirects_point_at_served_domains(vercel):
    domains = {d["domain"] for d in vercel["resource"]["vercel_project_domain"].values()}
    for key, d in vercel["resource"]["vercel_project_domain"].items():
        if d.get("redirect"):
            assert d["redirect"] in domains, f"{key} redirects to unmanaged {d['redirect']}"
            assert d["redirect"] != d["domain"], key


def test_every_vercel_domain_has_a_dns_record(vercel, dns):
    served = {fqdn(r["name"]) for r in records(dns).values() if r["type"] in ("A", "AAAA", "CNAME")}
    for key, d in vercel["resource"]["vercel_project_domain"].items():
        assert d["domain"] in served, f"{key}: {d['domain']} has no A/CNAME in the qezta.com zone"


def test_vercel_git_repos_are_managed_in_github(vercel, github):
    managed = {f"Qezta/{n}" for n, r in repos(github).items() if not r.get("archived")}
    for key, p in vercel["resource"]["vercel_project"].items():
        assert p["git_repository"]["repo"] in managed, key


def test_vercel_imports_cover_every_project_and_domain(vercel):
    targets = {i["to"] for i in vercel["import"]}
    for kind in ("vercel_project", "vercel_project_domain"):
        for key in vercel["resource"][kind]:
            assert f"{kind}.{key}" in targets, f"{kind}.{key} would be created instead of adopted"
