# OBS project the latest channel publishes to; tracks upstream release tags.
obs_latest_project := "home:p4lang:latest"

# Add a changelog entry.
changelog-add package:
    DEBEMAIL="$(git config user.name) <$(git config user.email)>" \
        dch --changelog p4lang-{{package}}/changelog

# Add a new upstream release to the changelog.
changelog-upstream-add package version:
    DEBEMAIL="$(git config user.name) <$(git config user.email)>" \
        dch --changelog p4lang-{{package}}/changelog --newversion {{version}} \
        Upstream release

# Generate build/<package> source package at upstream <tag>
generate-src-pkg package tag:
    ./scripts/generate-src-pkg {{package}} {{tag}}

# Build .dsc locally via osc-in-Docker: [--clean|--dry-run] <srcdir> [repo] [arch]
build-pkg +args:
    ./scripts/build-pkg {{args}}

# Build <package> at upstream <tag> and upload it to the latest channel's OBS project.
upload-src-pkg package tag: (generate-src-pkg package tag)
    ./scripts/osc-upload {{obs_project}} p4lang-{{package}} build/{{package}}

# Drop the cached build image so the next build-package re-provisions it.
clean-image:
    docker rmi obs-build-image

# Wipe build-package's cached buildroot + package cache.
clean-buildroot:
    docker run --rm --mount type=bind,source=$PWD/build,target=/x obs-build-image \
        sh -c 'rm -rf /x/.osc-buildroot /x/.osc-cache /x/.osc-work'
