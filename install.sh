#!/bin/bash
#xjy37 signed

unexpected(){
	if [[ -f $cDir/../.deps ]];then
		rm -f $cDir/../.deps
		echo " ==> error occurred. exit 1"
		exit 1
	fi
}

os(){
dtpEnv="$DESKTOP_SESSION"
if [[ -f ./install.sh ]];then
	xjy37Sign="$(sed -n 2p ./install.sh)"
	if [[ $xjy37Sign != "#xjy37 signed" ]];then
		echo "  ==> Swith to main Directory(macStyle4Gnome) then run: ./install -a"
		exit 1
	fi
fi
#if [[ $dtpEnv != "gnome" ]];then echo " ==> Visit https://www.gnome.org for more info.";exit 1;fi
dstRaw="$(head -1 /etc/os-release)"
dst="${dstRaw:5}"

echo -e "\033[1;37m  ==> Distro: \033[0m $dst"

case $dst in
	"Fedora" | "CentOS")
		pkgmng="dnf"
		depslist=(git zsh dbus-x11 gtk-murrine-engine gtk2-engines sassc glib2-devel)
		;;
	"Ubuntu")
		pkgmng="apt"
		# if Debian10, add "libxml2-utils" package behind
		depslist=(git zsh dbus-x11 gtk2-engines-murrine gtk2-engines-pixbuf sassc libcanberra-gtk-module libglib2.0-dev)
		;;
	"ArchLinux")
		pkgmng="pacman"
		;;
	**)
		pkgmng="unknown"
		echo "  ==> Current Distribution Not Supported"
		exit 1
esac

}

varConfig(){
timeArg="$(date +%Z%z)"
if [[ $timeArg != "CST+0800" ]];then
	#gitBase="https://github.com"
	gitBase="https://git.sdut.me"
else
	echo -n "  ==> Region: "
	echo "China"
	gitBase="https://git.sdut.me"
fi

themeStr="vinceliuice/Mojave-gtk-theme.git"
iconStr="vinceliuice/McMojave-circle.git"
cursorStr="xjy37/macStyle4Gnome.git"
ohmyzshStr="robbyrussell/oh-my-zsh.git"

themeDir="Mojave-gtk-theme"
iconDir="McMojave-circle"
cusorDir="Capitaine-Cursors"
ohmyzshDir="oh-my-zsh"
sourceList=($themeDir $iconDir $cusorDir $ohmyzshDir)

cursorBranchStr="CapitaineCursor-build"
cursorDirStr="Capitaine-Cursors"

mirrorStr="xjy37/mirrorChina.git"

gitTheme="$gitBase/$themeStr"
gitIcon="$gitBase/$iconStr"
gitCursor="$gitBase/$cursorStr"
gitOhmyzsh="$gitBase/$ohmyzshStr"
gitMirror="$gitBase/$mirrorStr"
}

deps(){
case $pkgmng in
	"dnf" | "apt")
		itArg="install -y"
		;;
	"pacman")
		itArg="-Syy"
		;;
	**)
		itArg="unknown"
		echo "  ==> Current Distribution Not Supported"
		exit 1
esac

depSolveBase="sudo $pkgmng $itArg ${depslist[@]}"
eval $depSolveBase || unexpected
touch ../.deps
}

handle(){
cDir="$(pwd)"

# wait ...
echo -e "\033[1;33m  ==> Wait ... \033[0m"

# handle source
# theme & icon & cursor & oh-my-zsh
sudo chmod -R 777 ./*

# theme
if [[ ! -d $themeDir ]];then
	git clone $gitTheme -q
	cd $themeDir && ./install.sh > theme.log && cd $cDir
else
	cd $themeDir && ./install.sh > theme.log && cd $cDir
fi
# icon
if [[ ! -d $iconDir ]];then
	git clone $gitIcon -q
	cd $iconDir && ./install.sh > icon.log && cd $cDir
else
	cd $iconDir && ./install.sh > icon.log && cd $cDir
fi

# cursor
if [[ ! -d $cusorDir ]];then
	git clone $gitCursor -b $cursorBranchStr $cursorDirStr -q
	sudo cp -rf $cusorDir/*cursors* /usr/share/icons
else
	sudo cp -rf $cusorDir/*cursors* /usr/share/icons
fi
}

handleZsh(){
# oh-my-zsh
# may the last to install because it changes to zsh
if [[ ! -d $ohmyzshDir ]];then
	git clone $gitOhmyzsh -q
	if [[ $timeArg == "CST+0800" ]] || [[ $timeArg == "EDT-0400" ]];then
		sed -i 's/github.com/git.sdut.me/g' $ohmyzshDir/tools/install.sh
		sed -i 's/exec zsh -l/#deleted/g' $ohmyzshDir/tools/install.sh
	fi
	cd $ohmyzshDir/tools && ./install.sh > ohmyzsh.log && cd $cDir
else
	if [[ $timeArg == "CST+0800" ]] || [[ $timeArg == "EDT-0400" ]];then
		sed -i 's/github.com/git.sdut.me/g' $ohmyzshDir/tools/install.sh
		sed -i 's/exec zsh -l/#deleted/g' $ohmyzshDir/tools/install.sh
	fi
	cd $ohmyzshDir/tools && ./install.sh > ohmyzsh.log && cd $cDir
fi
#exec zsh -l
}

mirror(){
if [[ $pkgmng == "dnf" ]];then
sudo sed -e 's|^metalink=|#metalink=|g' \
         -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.ustc.edu.cn/fedora|g' \
         -i.bak \
         /etc/yum.repos.d/fedora.repo \
         /etc/yum.repos.d/fedora-modular.repo \
         /etc/yum.repos.d/fedora-updates.repo \
         /etc/yum.repos.d/fedora-updates-modular.repo

sudo dnf makecache
elif [[ $pkgmng == "apt" ]];then
	sudo sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
sudo apt update -y
fi
}

mirrorFile(){
ranStrArg0="$(cat /proc/sys/kernel/random/uuid)"
ranStr=${ranStrArg0:0-3}
bakDir=./backup
bakRanDir=$bakDir/backup-$ranStr

echo "  ==> Start ..."
if [[ ! -d ./mirror ]];then
	git clone $gitMirror ./mirror -q
fi
cat<<MIRROR

1. ustc -- China USTC
2. tuna -- tSinghua
MIRROR
read -p "Select fastest source [1/2] " mirrorSel

mkdir -p $bakRanDir
sudo cp -rf /etc/yum.repos.d/* $bakRanDir
echo "This is a backup of software repo." > $bakDir/README

case $mirrorSel in
1)
	sudo cp -rf ./mirror/ustc/* /etc/yum.repos.d/
	;;
2)
	sudo cp -rf ./mirror/tuna/* /etc/yum.repos.d/
	;;
*)
	echo "  ==> Num out of [ 1-2 ]"
	exit 1
	;;
esac
}
 
apply(){
	# theme
	gsettings set org.gnome.desktop.interface gtk-theme Mojave-dark
	gsettings set org.gnome.desktop.wm.preferences theme Mojave-dark
	
	# icon
	gsettings set org.gnome.desktop.interface icon-theme McMojave-circle
	
	# cursor
	gsettings set org.gnome.desktop.interface cursor-theme Capitaine-cursors-dark
	
	# window button
	gsettings set  org.gnome.desktop.wm.preferences button-layout 'close:'
}

clean(){
	echo -e "\033[1;32m  ==> Clean cache \033[0m"
	cacheFile=(Capitaine-Cursors McMojave-circle Mojave-gtk-theme oh-my-zsh mirror ../.deps)
	if [[ $USER != "root" ]];then
		for cFile in "${cacheFile[@]}"
		do
			echo "==> Remove $cFile"
			sleep .5
			rm -rf $cFile
		done
	else
		for cFile in "${cacheFile[@]}"
		do
			echo "==> Remove $cFile"
			sleep .5
			sudo rm -rf $cFile
		done
	fi
	echo -e "\033[1;32m  ==> Done \033[0m"
	exit 0
}

install(){
	if [[ -f ../.deps ]];then
		unset taskList[2]
		unset taskList[3]
	else
		echo "no deps file"
	fi
	echo "ALL TASK: ${taskList[@]}"
	#exit 1
	
	# handle task
	for _task in "${taskList[@]}"
	do
		echo -e "\n\033[1;34m  ==> Executing $_task ...\033[0m"
		$_task
		sleep .5
		echo -e "\033[1;32m  ==> Execute $_task done.\033[0m"
	done
	handleZsh
}

taskList=(os varConfig mirrorFile deps handle)

while getopts ":alrbcd" opt
do
case $opt in
	a)
		taskList[5]="apply"
		#taskList=(os varConfig mirror deps handle apply)
		;;
	l)
		gsettings set  org.gnome.desktop.wm.preferences button-layout 'close:'
		;;
	r)
		gsettings set  org.gnome.desktop.wm.preferences button-layout ':close'
		;;
	b)
		cat <<BUTTONGUIDE
		
show all window buttons at right, run

	gsettings set  org.gnome.desktop.wm.preferences button-layout ':maximize,minimize,close'
	
show all window buttons at left, run

	gsettings set  org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
BUTTONGUIDE
		exit 0
		;;
	c)
		clean
		;;
	d)
		# for debuger, option ./install -dc
		gsettings set org.gnome.desktop.interface gtk-theme fdfhnifnhd
		gsettings set org.gnome.desktop.interface icon-theme fdjfhndnjfnh
		;;
	?)
		cat <<HELP
-a  -- install & apply
-r  -- window buttons at right
-h  -- print help

-b  -- button guide, show guide about
       setup window button at the cornor
-c  -- clean cache, clean files script
       downloaded
HELP
	exit 1
	esac
done

install
