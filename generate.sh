#!/bin/sh

GITDIR="/srv/git"
WEBDIR="/var/www/html"

stagit-index "${GITDIR}/"*/ > "${WEBDIR}/index.html"

# make files per repo
for repo in "${GITDIR}/"*/; do
    # strip .git suffix
    REPO_DIR=$(basename "${repo}")
    REPO_NAME=$(basename "${repo}" ".git")
    printf "%s... " "${REPO_NAME}"

    mkdir -p "${WEBDIR}/${REPO_NAME}"
    cd "${WEBDIR}/${REPO_NAME}" || continue
    stagit -c ".cache" "${GITDIR}/${REPO_DIR}"

    ln -sf log.html index.html
    ln -sf ../style.css style.css
    ln -sf ../logo.png logo.png
    ln -sf ../favicon.png favicon.png

    echo "done"
done
