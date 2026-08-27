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

# Build <package> at upstream <tag> and upload it to the latest channel's OBS project.
latest package tag: (generate-src-pkg package tag)
    ./scripts/osc-upload {{obs_latest_project}} p4lang-{{package}} \
        build/{{package}}/p4lang-{{package}}_*.dsc \
        build/{{package}}/p4lang-{{package}}_*.orig*.tar.* \
        build/{{package}}/p4lang-{{package}}_*.debian.tar.*

# Build <srcdir>'s .dsc locally for [repo] [arch] via osc-in-Docker.
build-package srcdir repo="xUbuntu_22.04" arch="x86_64":
    ./scripts/build-package {{srcdir}} {{repo}} {{arch}}

# Drop the cached build image so the next build-package re-provisions it.
clean-image:
    docker rmi obs-build-image

# Wipe build-package's cached buildroot + package cache.
clean-buildroot:
    docker run --rm --mount type=bind,source=$PWD/build,target=/x obs-build-image \
        sh -c 'rm -rf /x/.osc-buildroot /x/.osc-cache'
