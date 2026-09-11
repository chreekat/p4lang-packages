# OBS project to push to
obs_project := "home:p4lang:latest"

# Add a changelog entry.
changelog-add package:
    DEBEMAIL="$(git config user.name) <$(git config user.email)>" \
        dch --changelog p4lang-{{package}}/changelog

# Start a changelog entry for new upstream <tag> at Debian revision 1.
changelog-upstream-add package tag:
    DEBEMAIL="$(git config user.name) <$(git config user.email)>" \
        dch --changelog p4lang-{{package}}/changelog \
        --newversion {{trim_start_match(tag, "v")}}-1 \
        Upstream release

# Generate build/<package> source package at upstream <tag>
generate-src-pkg package tag:
    ./scripts/generate-src-pkg {{package}} {{tag}}

# Build .dsc locally via osc-in-Docker: [--clean|--dry-run] <srcdir> [repo] [arch]
build-pkg +args:
    ./scripts/build-pkg {{args}}

# Build <package> at upstream <tag> and upload it to the latest channel's OBS project.
upload-src-pkg package tag: (generate-src-pkg package tag)
    ./scripts/upload-src-pkg {{obs_project}} p4lang-{{package}} build/{{package}}

# Drop the cached build image so the next build-pkg re-provisions it.
clean-image:
    docker rmi obs-build-image

# Wipe build-package's cached buildroot + package cache.
clean-buildroot:
    docker run --rm --mount type=bind,source=$PWD/build,target=/x obs-build-image \
        sh -c 'rm -rf /x/.osc-buildroot /x/.osc-cache /x/.osc-work'
