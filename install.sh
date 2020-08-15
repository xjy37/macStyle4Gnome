#!/bin/bash

unexpected(){
	if [[ -f $cDir/../.deps ]];then
		rm -f $cDir/../.deps
		echo " ==> error occurred. exit 1"
		exit 1
	fi
}

os(){
dtpEnv="$DESKTOP_SESSION"
#if [[ $dtpEnv != "gnome" ]];then echo " ==> Visit https://www.gnome.org for more info.";exit 1;fi
dstRaw="$(head -1 /etc/os-release)"
dst="${dstRaw:5}"

echo -n "  ==> Distro: "
echo $dst 

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

echo $pkgmng
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
ohmyzshStr="robbyrussell/oh-my-zsh"

themeDir="Mojave-gtk-theme"
iconDir="McMojave-circle"
cusorDir="Capitaine-Cursors"
ohmyzshDir="oh-my-zsh"
sourceList=($themeDir $iconDir $cusorDir $ohmyzshDir)

cursorBranchStr="CapitaineCursor-build"
cursorDirStr="Capitaine-Cursors"

gitTheme="$gitBase/$themeStr"
gitIcon="$gitBase/$iconStr"
gitCursor="$gitBase/$cursorStr"
gitOhmyzsh="$gitBase/$ohmyzshStr"
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

# handle source
# theme & icon & cursor & oh-my-zsh

# theme
if [[ ! -d $themeDir ]];then
	git clone $gitTheme
	cd $themeDir && ./install.sh && cd $cDir
else
	cd $themeDir && ./install.sh && cd $cDir
fi
# icon
if [[ ! -d $iconDir ]];then
	git clone $gitIcon
	cd $iconDir && ./install.sh && cd $cDir
else
	cd $iconDir && ./install.sh && cd $cDir
fi

# cursor
if [[ ! -d $cusorDir ]];then
	git clone $gitCursor -b $cursorBranchStr $cursorDirStr
	sudo cp -rf $cusorDir/*cursors* /usr/share/icons
else
	sudo cp -rf $cusorDir/*cursors* /usr/share/icons
fi
}

handleZsh(){
# oh-my-zsh
# may the last to install because it changes to zsh
if [[ ! -d $ohmyzshDir ]];then
	git clone $gitOhmyzsh
	if [[ $timeArg == "CST+0800" ]];then
		sed -i 's/github.com/git.sdut.me/g' $ohmyzshDir/tools/install.sh
		sed -i 's/exec zsh -l/#deleted/g' $ohmyzshDir/tools/install.sh
	fi
	cd $ohmyzshDir/tools && ./install.sh && cd $cDir
else
	if [[ $timeArg == "CST+0800" ]];then
		sed -i 's/github.com/git.sdut.me/g' $ohmyzshDir/tools/install.sh
		sed -i 's/exec zsh -l/#deleted/g' $ohmyzshDir/tools/install.sh
	fi
	cd $ohmyzshDir/tools && ./install.sh && cd $cDir
fi
exec zsh -l
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
		$_task
	done
	handleZsh
}

taskList=(os varConfig mirror deps handle)

while getopts ":alr" opt
do
case $opt in
	a)
		taskList[5]="apply"
		echo "Apply option"
		#taskList=(os varConfig mirror deps handle apply)
		;;
	l)
		gsettings set  org.gnome.desktop.wm.preferences button-layout 'close:'
		;;
	r)
		gsettings set  org.gnome.desktop.wm.preferences button-layout ':close'
		;;
	-button-guide)
		cat <<BUTTONGUIDE
		
show all window buttons at right, run

	gsettings set  org.gnome.desktop.wm.preferences button-layout ':maximize,minimize,close'
	
show all window buttons at left, run

	gsettings set  org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
BUTTONGUIDE
		exit 0
		;;
	?)
		cat <<HELP
-a  -- install & apply
-r  -- window buttons at right
-h  -- print help

--button-guide -- show guide about setup
		  window button at the cornor
HELP
	exit 1
	esac
done

install
