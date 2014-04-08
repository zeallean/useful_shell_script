#!/bin/sh
# author: zouz
# mail:zouz@mail.51.com
# copyright: www.51.com
# desc:
#	this script is a processor to generate a xml file that contains the whole resource list
#   hash(git rev-parse format) of the git repository.
# --------------------------------------------------
# usage:
#   git_revison_xml_processor.sh  gitweb@192.168.69.40:webgameJj_client v1.0 release /proj/git/client
#
#   /proj/git/client : the location that you want clone (initilize) the repository to
#
#   v1.0 : the target repository tag that you want
#
#	release : the resource folder name in the repository
#
#	0 : mode (use for when exec by script not output the usage info)	
# --------------------------------------------------
usage(){
mode="$1"
[[ "${mode}" == "0" ]] && return
echo -e "Usage: This script is use for get the files list with the file_name|hash (product from git rev-parse)\n

example: git_revison_xml_processor.sh v1.0 release /proj/git/client\n

Options:\n
  /proj/git/client                          the location that you want clone (initilize) the repository to,if not given any value,will set \$HOME as default\n
  v1.0                                      the target repository tag that you want\n
  release                                   the resource folder name in the repository\n"
}

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/bin"
local_repo_location="$1"
git_tag="$2"
resource_folder="$3"
mode="$4"

if [[ "g$mode" == "g" ]];then
mode=1
fi

if [ ! -d "$local_repo_location" ];then
	echo 'Error: local repo location not exists'
	usage ${mode}
	exit 1
fi

if [[ ! -d ${local_repo_location%/}"/.git" ]];then
	echo 'Error: the repository is not a git repository'
	usage ${mode}
	exit 2
fi

cd ${local_repo_location}
# check is the target repository is available.
git status &> /dev/null
if [[ $? != 0 ]];then
	echo 'Error: the repository is not available'
	usage ${mode}
	exit 4
fi 

if [[ "g$git_tag" == "g" ]];then
git_tag='master'
fi
git checkout ${git_tag} &> /dev/null
if [[ $? != 0 ]];then
	echo -e "Error: checkout ${git_tag} fail"
	usage ${mode}
	exit 4
fi

repo=${local_repo_location%/}/${resource_folder}

if [[ "x$repo" == "x" || ! -d "${repo}" ]];then
 	echo 'repo not exists'
 	usage ${mode}
 	exit 3
fi

cd ${repo}
IFS=$(echo -en "\n\b")
echo -e '<xml version="1.0" charset="UTF-8">'
echo -e '<Root GameVerRes="'${git_tag}'">';
for file in `find . -type f | grep -Ev "/.git/"`
do
	hash=$(git rev-parse HEAD:"$file");
	if [[ ! $(echo ${hash} | grep "HEAD:") ]];then
		f=$(echo $file | sed 's/\.\///g');
		size=$(du -b $file | awk '{print $1}')
		echo -e '<Res file="'${f}'" ver="'${hash}'" size="'${size}'"/>'
	fi
done
echo -e "</Root>"
echo -e "</xml>"