function set-install-version () {
    cat install.rdf | $GSED -e "s/<em:version>.*<\/em:version>/<em:version>${VERSION}<\/em:version>/" > frag.txt
    mv frag.txt install.rdf
    cat install.rdf | $GSED -e "s/<em:updateURL>.*<\/em:updateURL>/<em:updateURL>https:\/\/our.law.nagoya-u.ac.jp\/download\/${FORK}\/update\/update.rdf<\/em:updateURL>/" > frag.txt
    mv frag.txt install.rdf
}
