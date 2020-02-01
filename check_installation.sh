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
version_path="${server_path}/version"
ts3server_minimal_runscript="ts3server_minimal_runscript.sh"
exclude="${ts3server_minimal_runscript}"

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

determing_new_version
check_symlinks_ts_home
check_ts3server_minimal_runscript
