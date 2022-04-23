#!/bin/bash 
#Invoice Ninja Self-Hosted Update

#SET INVOICE NINJA INSTALL AND STORAGE PATHS
#--------------------------------------------------------
updatedb
ninja_home="$(locate -b '\composer.json' | xargs grep -l "invoiceninja/invoiceninja" | xargs -n 1 dirname)"

#GET INSTALLED AND CURRENT VERSION NUMBERS
#--------------------------------------------------------
versiontxt="$ninja_home/VERSION.txt"
ninja_installed="$(cat "$versiontxt")"
ninja_latest=$(basename $(curl -fs -o/dev/null -w %{redirect_url} https://github.com/invoiceninja/invoiceninja/releases/latest)| cut -c 2-)



mv invoiceninja.zip invoiceninja-previous.zip 
version=$(basename $(curl -fs -o/dev/null -w %{redirect_url} https://github.com/invoiceninja/invoiceninja/releases/latest))
wget https://github.com/invoiceninja/invoiceninja/releases/download/$version/invoiceninja.zip
unzip -o invoiceninja.zip
php artisan optimize
