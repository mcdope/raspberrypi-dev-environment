#!/bin/bash
echo "Packing node_modules and package-lock.json..."
ssh alarm@localhost -p 5022 "cd /srv/http/mirror/frontend-build-env && rm npm_preload.tar.gz; tar czfv npm_preload.tar.gz package-lock.json node_modules"

echo "Downloading archive from VM..."
scp -P 5022 alarm@localhost:/srv/http/mirror/frontend-build-env/npm_preload.tar.gz ./

echo "Uploading to distribution ftp..."
curl -T npm_preload.tar.gz ftp://mcdope.org --user pimirror:p1m1rr0r

echo
echo "DONE!"