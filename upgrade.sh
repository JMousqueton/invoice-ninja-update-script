#!/bin/bash 
#Invoice Ninja Self-Hosted Upgrade

#SET INVOICE NINJA INSTALL PATH
#--------------------------------------------------------
updatedb
ninja_home="$(locate -b '\composer.json' | xargs grep -l "invoiceninja/invoiceninja" | xargs -n 1 dirname)"

#GET INSTALLED AND LATEST VERSION 
#--------------------------------------------------------
versiontxt="$ninja_home/VERSION.txt"
ninja_installed="$(cat "$versiontxt")"
ninja_latest=$(basename $(curl -fs -o/dev/null -w %{redirect_url} https://github.com/invoiceninja/invoiceninja/releases/latest)| cut -c 2-)

#SEE IF AN UPDATE IS REQUIRED
#--------------------------------------------------------
updgrade_required="no"
set -f
array_ninja_installed=(${ninja_installed//./ })
array_ninja_latest=(${ninja_latest//./ })
 
if (( ${#array_ninja_installed[@]} == "2" ))
then
    array_ninja_installed+=("0")
fi
 
for ((i=0; i<${#array_ninja_installed[@]}; i++))
do
    if (( ${array_ninja_installed[$i]} < ${array_ninja_latest[$i]} ))
    then
    upgrade_required="yes"
    fi
done


#MAIN UPGRADE SECTION
#--------------------------------------------------------
case $upgrade_required in
    no)
    printf '\n%s - Invoice Ninja v%s is installed with the lastest version. No upgrade required.\n' "$(date)" "$ninja_installed"
    ;;
    yes)
    printf '\n%s - Updating Invoice Ninja from v%s to v%s.\n\n' "$(date)" "$ninja_installed" "$ninja_latest"

    printf 'Deleting previous archive\n\n'
    rm -f $ninja_home/invoicejinja.zip
    
    printf 'Downloading Invoice Ninja v%s archive ...\n\n' "$ninja_latest" 
    wget https://github.com/invoiceninja/invoiceninja/releases/download/$ninja_latest/invoiceninja.zip
    
    printf 'Extracting to temporary folder "%s" ...\n\n' "$ninja_home"
    unzip -o invoiceninja.zip 

    printf '%s - Invoice Ninja successfully updated to v%s!\n\n' "$(date)" "$ninja_latest"

    printf 'update configuration\n\n'
    php artisan optimize
    ninja_installed="$(cat "$versiontxt")"
    printf '✔︎ Invoice Ninja "%s" fully installed\n\n' "$ninja_installed"
    ;;
esac
