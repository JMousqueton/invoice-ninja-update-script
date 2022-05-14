#!/bin/bash 
#Invoice Ninja Self-Hosted Upgrade

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo
  echo "You can override the OS detection by setting os= and dist= prior to running this script."
  echo "You can find a list of supported OSes and distributions on our website: https://packagecloud.io/docs#os_distro_version"
  echo
  echo "For example, to force Ubuntu Trusty: os=ubuntu dist=trusty ./script.sh"
  echo
  echo "Please email support@packagecloud.io and let us know if you run into any issues."
  exit 1
}

mlocate_check ()
{
  echo "Checking for curl..."
  if command -v mlocate > /dev/null; then
    echo "Detected mlocate..."
  else
    echo "Installing mlocate..."
    apt-get install -q -y mlocate
    if [ "$?" -ne "0" ]; then
      echo "Unable to install mlocate ! Your base system has a problem; please check your default OS's package repositories because mlocate should work."
      echo "Repository installation aborted."
      exit 1
    fi
  fi
}

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    # some systems dont have lsb-release yet have the lsb_release binary and
    # vice-versa
    if [ -e /etc/lsb-release ]; then
      . /etc/lsb-release

      if [ "${ID}" = "raspbian" ]; then
        os=${ID}
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      else
        os=${DISTRIB_ID}
        dist=${DISTRIB_CODENAME}

        if [ -z "$dist" ]; then
          dist=${DISTRIB_RELEASE}
        fi
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/debian_version ]; then
      # some Debians have jessie/sid in their /etc/debian_version
      # while others have '6.0.7'
      os=`cat /etc/issue | head -1 | awk '{ print tolower($1) }'`
      if grep -q '/' /etc/debian_version; then
        dist=`cut --delimiter='/' -f1 /etc/debian_version`
      else
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      fi

    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as $os/$dist."
}

detect_version_id () {
  # detect version_id and round down float to integer
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    version_id=${VERSION_ID%%.*}
  elif [ -f /usr/lib/os-release ]; then
    . /usr/lib/os-release
    version_id=${VERSION_ID%%.*}
  else
    version_id="1"
  fi
}

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#CHECK OS
#--------------------------------------------------------
#detect_os
#detect_version_id

#SET INVOICE NINJA INSTALL PATH
#--------------------------------------------------------
mlocate_check
updatedb
ninja_home="$(locate -b '\composer.json' | xargs grep -l "invoiceninja/invoiceninja" | xargs -n 1 dirname)"
ninja_user="$(sudo ps aux | grep 'php-fpm: pool' | grep -v grep | cut -d' ' -f 1 | head -n 1)" 

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
    cd $ninja_home 
    wget https://github.com/invoiceninja/invoiceninja/releases/download/$ninja_latest/invoiceninja.zip
    
    printf 'Extracting to temporary folder "%s" ...\n\n' "$ninja_home"
    unzip -o invoiceninja.zip 

    printf '%s - Invoice Ninja successfully updated to v%s!\n\n' "$(date)" "$ninja_latest"

    printf 'update configuration\n\n'
    php artisan optimize
    chown -R $ninja_user * 
    ninja_installed="$(cat "$versiontxt")"
    printf '✔︎ Invoice Ninja "%s" fully installed\n\n' "$ninja_installed"
    
    nginx_owner=$(grep -e '^Uid:' /proc/$(pidof nginx -s)/status | cut -f 2)
    nginx_grp=$(grep -e '^Gid:' /proc/$(pidof nginx -s)/status | cut -f 2)
    printf 'update right\n\n'
    sudo chown -R $nginx_owner:$nginx_grp $ninja_home
    ;;
esac
