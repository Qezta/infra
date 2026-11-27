"""Push the org card to its Space, run by the org card resource on apply.

usage: org_card_push.py <repo> <card-dir>

Creates the Space as a free static Space if it's missing (`hf upload` would
create a Gradio Space, which needs a paid plan on orgs), then makes the
Space's files exactly the card's: changed files are uploaded and anything
else is deleted (.gitattributes excepted). Uses HF_TOKEN.
"""
import sys

from huggingface_hub import HfApi

repo, card = sys.argv[1], sys.argv[2]
api = HfApi()
api.create_repo(repo, repo_type="space", space_sdk="static", private=False, exist_ok=True)
info = api.upload_folder(
    repo_id=repo,
    repo_type="space",
    folder_path=card,
    delete_patterns="*",
    commit_message="chore: sync org card from Qezta/infra",
)
print(f"org card synced: {info}")
