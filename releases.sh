function create-github-release () {
    if [ "$BETA" -gt "0" ]; then
        RELEASE_TAG="v${VERSION_STUB}beta"
        RELEASE_NAME="Beta pre-release of v${VERSION_STUB}"
        RELEASE_BODY="To install, click on the *.xpi link for the beta version you wish to install. Beta pre-releases will update automatically when the final release appears."
    else
        RELEASE_TAG="v${VERSION_STUB}"
        RELEASE_NAME="v${VERSION_STUB} final"
        RELEASE_BODY="To install the plugin, click on the &ldquo;${CLIENT}-v${VERSION_STUB}.xpi&rdquo; file below while viewing this page in Firefox. This plugin is signed for use in Firefox and will update automatically."
    fi
    UPLOAD_URL=$(curl -k --fail --silent \
        --user "${DOORKEY}" \
        "https://api.github.com/repos/Juris-M/${FORK}/releases/tags/${RELEASE_TAG}" \
        | ~/bin/jq '.upload_url')
    #echo "FIRST ${UPLOAD_URL}"
    if [ "$UPLOAD_URL" == "" ]; then
        # Create the release
        DAT=$(printf '{"tag_name": "%s", "name": "%s", "body":"%s", "draft": false, "prerelease": %s}' "$RELEASE_TAG" "$RELEASE_NAME" "$RELEASE_BODY" "$IS_BETA")
        echo "${DAT}"
        UPLOAD_URL=$(curl -k --fail --silent \
            --user "${DOORKEY}" \
            --data "${DAT}" \
            "https://api.github.com/repos/Juris-M/${FORK}/releases" \
            | ~/bin/jq '.upload_url')
    fi
    #echo "SECOND ${UPLOAD_URL}"
    UPLOAD_URL=$(echo $UPLOAD_URL | $GSED -e "s/\"\(.*\){.*/\1/")
    #echo "THIRD ${UPLOAD_URL}"
    if [ "${UPLOAD_URL}" == "" ]; then
        echo "Fatal: no upload URL"
        echo "Aborting"
        exit 0
    fi
}

function add-xpi-to-github-release () {
    # Sign XPI and move into place
    jpm sign --api-key=${API_KEY} --api-secret=${API_SECRET} --xpi="releases/${VERSION_STUB}/${CLIENT}-v${VERSION}.xpi"
    mv "${SIGNED_STUB}${VERSION}-fx.xpi" "releases/${VERSION_STUB}/${CLIENT}-v${VERSION}-fx.xpi"

    # Get content-length of downloaded file
    SIZE=$(stat -c %s "${RELEASE_DIR}/${CLIENT}-v${VERSION}-fx.xpi")
    
    echo $SIZE
    echo $UPLOAD_URL
    echo "${RELEASE_DIR}/${CLIENT}-v${VERSION}-fx.xpi"

    # Upload "asset"
    NAME=$(curl --fail --silent --show-error \
        --user "${DOORKEY}" \
        -H "Accept: application/vnd.github.manifold-preview" \
        -H "Content-Type: application/x-xpinstall" \
	-H "Content-Length: ${SIZE}" \
        --data-binary "@${RELEASE_DIR}/${CLIENT}-v${VERSION}-fx.xpi" \
        "${UPLOAD_URL}?name=${CLIENT}-v${VERSION}-fx.xpi" \
            | ~/bin/jq '.name')
    echo "Uploaded ${NAME}"
}

function publish-update () {
    # Prepare the update manifest
    $GSED -si "s/\(<em:version>\).*\(<\/em:version>\)/\\1${VERSION_STUB}\\2/" update-TEMPLATE.rdf
    $GSED -si "s/\(<em:updateLink>.*download\/\).*\(<\/em:updateLink>\)/\\1v${VERSION_STUB}\/${CLIENT}-v${VERSION_STUB}-fx.xpi\\2/" update-TEMPLATE.rdf
    git commit -m "Refresh update-TEMPLATE.rdf" update-TEMPLATE.rdf >> "${LOG_FILE}" 2<&1
    echo -n "Proceed? (y/n): "
    read CHOICE
    if [ "${CHOICE}" == "y" ]; then
        echo Okay, here goes ...
    else
        echo Aborting
        exit 1
    fi
    # Slip the update manifest over to the gh-pages branch, commit, and push
    cp update-TEMPLATE.rdf update-TRANSFER.rdf
    git checkout gh-pages >> "${LOG_FILE}" 2<&1
    if [ $(git ls-files | grep -c update.rdf) -eq 0 ]; then
        echo "XXX" > update.rdf
        git add update.rdf
    fi
    mv update-TRANSFER.rdf update.rdf >> "${LOG_FILE}" 2<&1
    git commit -m "Refresh update.rdf" update.rdf >> "${LOG_FILE}" 2<&1
    git push >> "${LOG_FILE}" 2<&1
    echo "Refreshed update.rdf on project site"
    git checkout "${BRANCH}" >> "${LOG_FILE}" 2<&1
}
