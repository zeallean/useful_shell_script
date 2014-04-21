#!/bin/sh
# author: zouz
# mail:zouz@mail.51.com
# copyright: www.51.com
# desc:
#	this script is a processor to generate a xml file that contains the whole resource list
#   hash(git rev-parse format) of the git repository.
# --------------------------------------------------
#	usage: git_revison_xml_producer.sh [-R <the git repository path>] [-T <the tag of the repository>] 
#		   [-r <the relative root document that you want in the repository>]
#           [-p <the target path>]
#           [-h]
#
#	example: git_revison_xml_producer.sh -R /proj/git/client -T v1.0 -r release -p res,img,assets
#
#	Options:
#		-R 		the git repository,There is must be have the \".git\" dir and use the absolute path.
#		-T 		the tag of the repository in git.
#		-r 		the relative root document,provide to you the list just relative to the root document.
#		-p 		the target dir that you want,NOTE: it is relative to the repository root by default,if -r <relative root> is passed,relative to it.
#		-h 		help info
# --------------------------------------------------
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/bin"

#help info
usage(){
mode="$1"
[[ "${mode}" == "0" ]] && return
echo "usage: git_revison_xml_producer.sh [-R <the git repository path>]
                                       [-T <the tag of the repository>]
                                       [-r <the relative root document that you want in the repository>]
                                       [-p <the target path>] [-h]

example: git_revison_xml_producer.sh -R /proj/git/client -T v1.0 -r release -p res,img,assets

Options:
	-R 		the git repository,There is must be have the \".git\" dir and use the absolute path.
	-T 		the tag of the repository in git.
	-r 		the relative root document,provide to you the list just relative to the root document.
	-p 		the target dir that you want,NOTE: it is relative to the repository root by default,if -r <relative root> is passed,relative to it.
	-m 		the mode: default 1,when eq 0, the help info will not output when exec error
	-h 		help info
"
exit
}

if [[ $# == 0 ]];then
	usage
fi

while getopts R:T:r:p:m:h option 2>/dev/null
do
  case $option in
    R)
        local_repo_location=$OPTARG
    ;;
    T)
        git_tag=$OPTARG
    ;;
    r)
    	relative_root=$OPTARG
   	;;
   	p)
   		resource_folder=$OPTARG
   	;;
   	m)
   		mode=$OPTARG
   	;;
    h)
        usage
    ;;
    \?)
        Print_Msg "[\033[0;31;1mFailed\033[0m] ARGV-ERROR"
    ;;
  esac
done

if [[ "x$mode" == "x" ]];then
mode=1
fi

#check repo
if [[ ! -d "$local_repo_location" ]];then
	echo 'Error: local repo location not exists'
	#usage ${mode}
	exit 1
fi

if [[ ! -d ${local_repo_location%/}"/.git" ]];then
	echo 'Error: the repository is not a git repository'
	#usage ${mode}
	exit 2
fi

# check is the target repository is available.
cd ${local_repo_location}
git status &> /dev/null
if [[ $? != 0 ]];then
	echo 'Error: the repository is not available'
	#usage ${mode}
	exit 4
fi

# check git tag is exists
if [[ "g$git_tag" == "g" ]]; then
	git_tag='master'
fi

git checkout ${git_tag} &> /dev/null
if [[ $? != 0 ]];then
	echo "Error: checkout ${git_tag} fail"
	#usage ${mode}
	exit 4
fi

# if passed relative folder 
if [[ "r$relative_root" == "r" ]];then
	repo=${local_repo_location%/}/
else
	repo=${local_repo_location%/}/${relative_root}
fi

if [[ ! -d "${repo}" ]];then
 	echo "repo ${repo} not exists"
 	#usage ${mode}
 	exit 3
fi

# if passed target dir
if [[ "p$resource_folder" != "p" ]];then
	resource_folder=($(echo "$resource_folder" | sed 's/,/ /g'))
	cnt=0
	for i in ${resource_folder[@]}
	do
		target_dir=${repo%/}/${i}
		if [[ ! -d  ${target_dir} ]];then
			echo "the target dir ${target_dir} not exists"
			#usage ${mode}
			exit 3
		fi
		if [[ $cnt == 0 ]];then
			target_path="^./$i/"
		else
			target_path=${target_path}"|^./$i/"
		fi
		cnt=$(($cnt + 1))
	done
fi

cd ${repo}
#IFS=$(echo -en "\n\b")
echo '<xml version="1.0" charset="UTF-8">'
echo '<Root GameVerRes="'${git_tag}'">';
find . -type f | sed 's/ /\\ /g' | grep -E "${target_path}" | grep -v "/.git/" | while read file
do
	hash=$(git rev-parse HEAD:"$file");
	if [[ ! $(echo ${hash} | grep "HEAD:") ]];then
		f=$(echo "$file" | sed -e 's/\.\///g');
		size=$(ls -lsa "$file" | awk '{print $(NF-4)}')
		echo '<Res file="'${f}'" ver="'${hash}'" size="'${size}'"/>'
	fi
done
echo  "</Root>"
echo  "</xml>"