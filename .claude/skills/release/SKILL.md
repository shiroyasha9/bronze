---
name: release
description: Release a new Bronze version. Use when the user asks to do a release, ship, cut, or publish a new version (with or without an explicit version number).
---

# Release a Bronze version

End state: a published GitHub release on shiroyasha9/bronze whose assets include the notarized versioned dmg and an EdDSA-signed appcast.xml, with version bump and README updates committed and pushed to main.

## 1. Preflight

- Working tree clean (stash or surface anything unrelated before proceeding), on `main`, up to date with origin.
- `gh auth status` shows the active account for github.com is `shiroyasha9`; otherwise run `gh auth switch --user shiroyasha9`.

Done when: tree clean, correct account active.

## 2. Pick the version

- If the user named a version in their request, use it.
- Otherwise: last tag via `git describe --tags --abbrev=0`, read `git log <last-tag>..HEAD --oneline`, propose patch (fixes only) or minor (new features), state the reasoning in one line, and proceed — the user can object.

Done when: `<ver>` fixed and its rationale stated to the user.

## 3. Bump versions

In project.yml set `MARKETING_VERSION: <ver>` and increment `CURRENT_PROJECT_VERSION` by 1 (Sparkle compares CFBundleVersion; it must increase every release).

Done when: both values updated.

## 4. Draft README + release notes — approval gate

- From the commit log since the last tag, draft: (a) README edits covering user-facing features added or changed (features list, install steps, screenshots that went stale), (b) release notes for the GitHub release.
- Show both drafts to the user and wait for approval. Apply README edits only after OK.

Done when: user approved and README edits applied (or user said skip).

## 5. Build and sign

Run `make appcast`. This builds Release, notarizes, staples, creates the dmg, and generates `dist/appcast/appcast.xml` + `dist/appcast/Bronze-<ver>.dmg`.

Done when: `appcast.xml` exists and its `<enclosure>` carries a `sparkle:edSignature` attribute — grep for it; a missing signature means the built app lacks `SUPublicEDKey` and the release must not ship.

## 6. Commit and push

Commit project.yml + README changes as `release: v<ver>`, push to main.

Done when: pushed.

## 7. Publish — confirmation gate

Ask the user for final OK before publishing (public, hard to unpublish cleanly). After OK:

```sh
gh release create v<ver> dist/appcast/Bronze-<ver>.dmg dist/appcast/appcast.xml \
  --title "Bronze <ver>" --notes "<approved notes>"
```

Done when: `curl -sIL -o /dev/null -w '%{http_code}' https://github.com/shiroyasha9/bronze/releases/latest/download/appcast.xml` prints 200. (SUFeedURL points at latest/download, so appcast.xml must be an asset of every release.)

## 8. Wrap up

Remind the user to upload `Bronze-<ver>.dmg` to Gumroad (manual step).
