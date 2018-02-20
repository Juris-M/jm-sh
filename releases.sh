function add-xpi-to-our-law () {
    # Sign XPI and move into place
    jpm sign --api-key=${API_KEY} --api-secret=${API_SECRET} --xpi="releases/${VERSION_STUB}/${CLIENT}-v${VERSION}.xpi"
    mv "${SIGNED_STUB}${VERSION}-fx.xpi" "releases/${VERSION_STUB}/${CLIENT}-v${VERSION}-fx.xpi"

    # Get content-length of downloaded file
    SIZE=$(stat -c %s "${RELEASE_DIR}/${CLIENT}-v${VERSION}-fx.xpi")

    # Upload "asset"
    scp "${RELEASE_DIR}/${CLIENT}-v${VERSION}-fx.xpi" our.law.nagoya-u.ac.jp:/var/www/nginx/download/"${FORK}"/
    echo "Uploaded ${NAME}"
}

function publish-update () {
    # Prepare the update manifest
    $GSED -si "s/\(<em:version>\).*\(<\/em:version>\)/\\1${VERSION_STUB}\\2/" update-TEMPLATE.rdf
    $GSED -si "s/\(<em:updateLink>.*download\/myles\/\).*\(<\/em:updateLink>\)/\\1${CLIENT}-v${VERSION_STUB}-fx.xpi\\2/" update-TEMPLATE.rdf
    echo -n "Proceed? (y/n): "
    read CHOICE
    if [ "${CHOICE}" == "y" ]; then
        echo Okay, here goes ...
    else
        echo Aborting
        exit 1
    fi
    git commit -m "Refresh update-TEMPLATE.rdf" update-TEMPLATE.rdf >> "${LOG_FILE}" 2<&1
    # Slip the update manifest over to our.law
    scp update-TEMPLATE.rdf our.law.nagoya-u.ac.jp:/var/www/nginx/download/"${FORK}"/update/update.rdf
    
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
