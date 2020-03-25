#!/bin/bash
green='\e[32m'
red='\e[31m'
yellow='\e[33m'
white='\e[39m'
ok="${green}[ OK ]${white}"
warning="${yellow}[ WARNING ]${white}"
error="${red}[ ERROR ]${white}"

ts_home="/home/teamspeak"
server_path="${ts_home}/server"
version_path="${server_path}/latest"
ts3server_minimal_runscript="ts3server_minimal_runscript.sh"
exclude="${ts3server_minimal_runscript}"
ts3server_name="teamspeak3-server_linux_amd64"
version_pattern="[0-9]{0,2}\.[0-9]{1,3}\.[0-9]{1,3}"
search_string="${ts3server_name}-${version_pattern}.tar.bz2"
download_site="https://www.teamspeak.com/en/downloads/#server"
file_server="https://files.teamspeak-services.com/releases/server"
index='index.html'
last_downloaded="last_downloaded.txt"

download_ts3server () {

  [ -r ${last_downloaded} ] && last_downloaded_file=`cat ${last_downloaded}`
  
  wget -O ${index} -q $download_site
  
  if [ -r ${index} ]; then
    file=`grep -Eo "${search_string}" ${index} | uniq`
    if [ ! -z ${file} ]; then
      version=`echo ${file} | grep -Eo "${version_pattern}"`
      donwload_link="${file_server}/${version}/${file}"
      if [ "${file}" != "${last_downloaded_file}" ]; then
        wget -O ${file} -q ${donwload_link}
        if [ $? -eq 0 ]; then
          echo ${file} > ${last_downloaded}
          echo "${file} donwloaded from ${donwload_link}"
          mkdir tmp
          mv ${file} tmp
          tar -xf tmp/${file} -C tmp
          mv tmp/${ts3server_name} ${version}
          # Replace by sodoers systemctl
          ../ts3server_minimal_runscript.sh stop
          ./check_installation.sh
          ../ts3server_minimal_runscript.sh start
          rm -r tmp
          #add cleanup verion root@mars /home/teamspeak/server # ls -d 3* | sort -V
          # ls -d 3* | sort -V | wc -l
        fi
      fi
    fi
  fi

}

determing_new_version () {

  new_version_search=`ls -d ${server_path}/*.*.* | sort -V | tail -n1`
  [ ! -z ${new_version_search} ] && new_version=`basename ${new_version_search}` || echo -e "${error} determining new version"

  if [ ! -z ${new_version} ]; then
    installed_version=`readlink ${version_path}`
    if [ ${version_path} == ${installed_version} ]; then
      echo -e "${ok} server already linked to version ${new_version}"
    else
      if unlink ${version_path}; then
        if ln -s ${server_path}/${new_version} ${version_path}; then
          echo -e "${ok} server linked to version ${new_version}"
        else
          echo -e "${error} linking server to version ${new_version}"
        fi
      else
        echo -e "${error} unlinking server from version ${installed_version}"
      fi
    fi
  else
    echo -e "${error} dermining version"
  fi


}

check_symlinks_ts_home () {
  
  for file in `ls ${version_path} | egrep -v "${exclude}"`; do
  
    readlink_link=`readlink -f ${ts_home}/${file}`
    readlink_target=`readlink -f ${version_path}/${file}`

    if [ ${readlink_link} == ${readlink_target} ]; then
      echo -e "${ok} ${ts_home}/${file} -> ${version_path}/${file}"
    else
      [ -f ${ts_home}/${file} ] && rm ${ts_home}/${file}
      ln -s ${version_path}/${file} ${ts_home}/${file} && echo -e "${ok} ${ts_home}/${file} -> ${version_path}/${file}" || echo -e "${error} creating symlink ${ts_home}/${file} -> ${version_path}/${file}"
    fi
  
  done
}

check_ts3server_minimal_runscript () {
  
  echo "${FUNCNAME[0]}"

  if cmp -s "${ts_home}/${ts3server_minimal_runscript}" "${version_path}/${ts3server_minimal_runscript}"; then
    echo -e "${ok} ${ts3server_minimal_runscript}"
  else
    echo -e "${warning} ${ts_home}/${ts3server_minimal_runscript} != ${version_path}/${ts3server_minimal_runscript}"
    if cp -vp "${version_path}/${ts3server_minimal_runscript}" "${ts_home}/${ts3server_minimal_runscript}"; then
      echo -e "${ok} copying ${version_path}/${ts3server_minimal_runscript} to ${ts_home}/${ts3server_minimal_runscript}"
    else
      echo -e "${error} copying ${version_path}/${ts3server_minimal_runscript} to ${ts_home}/${ts3server_minimal_runscript}"
    fi
  fi

}

download_ts3server
determing_new_version
check_symlinks_ts_home
check_ts3server_minimal_runscript
