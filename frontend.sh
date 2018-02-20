
set +e
gsed --version > /dev/null 2<&1
if [ $? -gt 0 ]; then
    GSED="sed"
else
    GSED="gsed"
fi


gfind --version > /dev/null 2<&1
if [ $? -gt 0 ]; then
    GFIND="find"
else
    GFIND="gfind"
fi
set -e


# Error handlers
. jm-sh/errors.sh

# Setup
. jm-sh/setup.sh

# Version levels
. jm-sh/versions.sh

# Update about.xul etc etc
. jm-sh/fixcontentmaybe.sh

# Parse command-line options
. jm-sh/opts.sh

# Functions for build
. jm-sh/builder.sh

# Functions for release
. jm-sh/releases.sh

# Functions for repo management
. jm-sh/repo.sh

if [ $RELEASE -gt 1 ]; then
  DOORKEY=$(cat "${HOME}/bin/doorkey.txt")
fi

# Perform release ops
case $RELEASE in
    1)
        echo "(1)"
        # Preliminaries
        increment-patch-level
        if [ "$BETA" -gt 0 ]; then
            increment-beta-level
        fi
        echo "Version: ${VERSION}"

        # Build
        echo "(a)"
        touch-log
        echo "(b)"
        refresh-style-modules
        echo "(c)"
        build-the-plugin
        echo "(d)"
        repo-finish 1 "Built as ALPHA (no upload to GitHub)"
        echo "(e)"
        ;;
    2)
        echo "(2)"
        # Claxon
        check-for-uncommitted
        # Preliminaries
        increment-patch-level
        increment-beta-level
        save-beta-level
        echo "Version is: $VERSION"
        # Build
        touch-log
        refresh-style-modules
        build-the-plugin
        git-checkin-all-and-push
        add-xpi-to-our-law
        repo-finish 0 "Released as BETA (uploaded to our.law, prerelease)"
        ;;
    3)
        echo "(3)"
        # Claxon
        check-for-uncommitted
        block-uncommitted
        # Preliminaries
        reset-beta-level
        increment-patch-level
        check-for-release-dir
        save-patch-level
        echo "Version is: $VERSION"
        # Build
        echo "A"
        touch-log
        echo "B"
        refresh-style-modules
        echo "C"
        build-the-plugin
        echo "D"
        git-checkin-all-and-push
        echo "E"
        echo "F"
        add-xpi-to-our-law
        echo "G"
        publish-update
        echo "H"
        repo-finish 0 "Released as FINAL (uploaded to our.law, full wax)"
        ;;
esac

