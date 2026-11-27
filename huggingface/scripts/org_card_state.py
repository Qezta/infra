"""Org card drift probe.

Reads {"repo", "card"} as JSON on stdin (OpenTofu's external data source
protocol) and prints {"state": ...}: "in_sync" when the Space holds exactly
the card's files (same paths and git blob ids, .gitattributes aside),
"missing" when the Space doesn't exist, or "drift:<n> files differ".
"""
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request

IGNORED = {".gitattributes"}  # created by the Hub, always present


def blob_id(path):
    data = open(path, "rb").read()
    return hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()


def local_tree(card):
    return {
        os.path.relpath(os.path.join(root, f), card): blob_id(os.path.join(root, f))
        for root, _, files in os.walk(card)
        for f in files
    }


def remote_tree(repo):
    url = f"https://huggingface.co/api/spaces/{repo}/tree/main?recursive=true"
    req = urllib.request.Request(url)
    token = os.environ.get("HF_TOKEN")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            entries = json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise
    return {
        e["path"]: e["oid"]
        for e in entries
        if e["type"] == "file" and e["path"] not in IGNORED
    }


def main():
    q = json.load(sys.stdin)
    want = local_tree(q["card"])
    have = remote_tree(q["repo"])
    if have == want:
        state = "in_sync"
    elif have is None:
        state = "missing"
    else:
        paths = {p for p, _ in set(have.items()) ^ set(want.items())}
        state = f"drift:{len(paths)} files differ"
    json.dump({"state": state}, sys.stdout)


main()
