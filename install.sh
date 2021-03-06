#!/bin/bash
#xjy37 signed


os(){
dtpEnvRaw="$(env | grep GDMSESSION=)"
dtpEnv="${dtpEnvRaw:11}"
if [[ -f ./install.sh ]];then
	xjy37Sign="$(sed -n 2p ./install.sh)"
	if [[ $xjy37Sign != "#xjy37 signed" ]];then
		echo "  ==> Swith to main Directory(macStyle4Gnome) then run: ./install -a"
		exit 1
	fi
fi
if [[ $dtpEnv != "gnome" ]] && [[ ! -f /usr/bin/gnome-session ]];then
	echo "  ==> Desktop: $dtpEnv"
	echo "  ==> Visit https://www.gnome.org for more info."
	exit 1
fi
dstRaw="$(head -1 /etc/os-release)"
dstArg0="${dstRaw:5}"
dst=$(echo $dstArg0 | sed 's/"//g')
dstVersionRaw="$(sed -n '/VERSION_CODENAME/p' /etc/os-release)"
dstVersionArg0="${dstVersionRaw:17}"
dstVersion=$(echo $dstVersionArg0 | sed 's/"//g')
if [[ ! -n $dstVersion ]];then
	#version null
	dstVersionRaw="$(sed -n '/VERSION_ID/p' /etc/os-release)"
	dstVersionArg0="${dstVersionRaw:11}"
	dstVersion=$(echo $dstVersionArg0 | sed 's/"//g')
fi

echo -e "\033[1;37m  ==> Distro: \033[0m $dst: $dstVersion"

case $dst in
	"Fedora")
		pkgmng="dnf"
		softwareTg=/etc/yum.repos.d/*.repo
		softwareDir=/etc/yum.repos.d
		mkCache="makecache"
		#depslist=(git zsh dbus-x11 gtk-murrine-engine gtk2-engines sassc glib2-devel)
		;;
	"CentOS Linux")
		dst="CentOS"
		pkgmng="yum"
		softwareTg=/etc/yum.repos.d/*.repo
		softwareDir=/etc/yum.repos.d
		mkCache="makecache"
		#depslist=(git zsh dbus-x11 gtk-murrine-engine gtk2-engines sassc glib2-devel)
		;;
	"Ubuntu")
		pkgmng="apt"
		softwareTg=/etc/apt/sources.list
		softwareDir=/etc/apt
		mkCache="update -yq"
		#depslist=(git zsh dbus-x11 gtk2-engines-murrine gtk2-engines-pixbuf sassc libcanberra-gtk-module libglib2.0-dev)
		;;
	"Arch Linux")
		pkgmng="pacman"
		#depslist=(git zsh gtk-engine-murrine gtk-engines sassc)
		;;
	**)
		pkgmng="unknown"
		echo "  ==> Current Distribution Not Supported"
		exit 1
esac

}

varConfig(){
cDir="$(pwd)"
timeArg="$(date +%Z%z)"
case $timeArg in
	"CST+0800" | "EDT-0400" | "UTC+0000")
		#echo -n "  ==> Region: "
		#echo "China"
		#echo "  ==> (timezone default) ahead"
		gitBase="https://git.sdut.me"
		;;
	**)
		gitBase="https://github.com"
		;;
esac

themeStr="xjy37/macStyle4Gnome.git"
iconStr="xjy37/macStyle4Gnome.git"
cursorStr="xjy37/macStyle4Gnome.git"
ohmyzshStr="robbyrussell/oh-my-zsh.git"
wallpaperStr="xjy37/macStyle4Gnome.git"

themeBranchStr="Mojave-dark"
iconBranchStr="Mojave-CT-Light"
cursorBranchStr="CapitaineCursor-build"

themeDir="Mojave-dark"
iconDir="Mojave-CT-Light"
cusorDir="Capitaine-Cursors"
wallpaperDir="wallpaper"
ohmyzshDir="oh-my-zsh"

cursorDirStr="Capitaine-Cursors"

mirrorStr="xjy37/mirrorChina.git"

gitTheme="$gitBase/$themeStr"
gitIcon="$gitBase/$iconStr"
gitCursor="$gitBase/$cursorStr"
gitOhmyzsh="$gitBase/$ohmyzshStr"
gitMirror="$gitBase/$mirrorStr"
gitWallpaper="$gitBase/$wallpaperStr"

ZSH=$HOME/.oh-my-zsh

themeTgDir=/usr/share/themes
iconTgDir=/usr/share/icons

depslist=(zsh)
sourceList=($themeDir $iconDir $cusorDir $wallpaperDir $ohmyzshDir)
}

deps(){
case $pkgmng in
	"dnf" | "apt" | "yum")
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
eval $depSolveBase
touch ../.deps
}


handle(){
# wait ...
echo -e "\033[1;33m  ==> Wait ... \033[0m"

# handle source
# theme & icon & cursor & oh-my-zsh

# theme
if [[ ! -d $themeDir ]];then
	git clone $gitTheme -b $themeBranchStr $themeDir -q
fi
sudo cp -rf $themeDir $themeTgDir

# icon
if [[ ! -d $iconDir ]];then
	git clone $gitIcon -b $iconBranchStr $iconDir -q
fi
sudo cp -rf $iconDir $iconTgDir

# cursor
if [[ ! -d $cusorDir ]];then
	git clone $gitCursor -b $cursorBranchStr $cursorDirStr -q	
fi
sudo cp -rf $cusorDir/*cursors* $iconTgDir

# wallpaper
if [[ ! -d $wallpaperDir ]];then
	git clone $gitWallpaper -b wallpaper $wallpaperDir -q
fi
mkdir -p $HOME/.local/share/backgrounds/
cp -f $wallpaperDir/wallpaper.jpg $HOME/.local/share/backgrounds/

sudo chmod -R 777 ./*
sudo chmod -R 755 $themeTgDir $iconTgDir
}

handleZsh(){
# oh-my-zsh
# may the last to install because it changes to zsh
if [[ -d $ZSH ]];then
	echo -e "\n\033[33mYou already have Oh My Zsh installed.\033[0m"
	echo -e "You'll need to remove '$ZSH' if you want to reinstall."
	return 0
fi

if [[ ! -d $ohmyzshDir ]];then
	git clone $gitOhmyzsh -q
fi
case $timeArg in
	"CST+0800" | "EDT-0400" | "UTC+0000")
		sed -i 's/github.com/git.sdut.me/g' $ohmyzshDir/tools/install.sh
		sed -i 's/exec zsh -l/#deleted/g' $ohmyzshDir/tools/install.sh
		;;
esac
cd $ohmyzshDir/tools && ./install.sh && cd $cDir
#exec zsh -l
}

mirrorFile(){
# Arch Linux & CentOS itself auto select fastest repo
case $dst in
	"Arch Linux" | "CentOS")
		return 0
	;;
esac

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
3. keep -- for current
MIRROR
read -p "Select fastest source [1/2] " mirrorSel

mkdir -p $bakRanDir
sudo cp -f $softwareTg $bakRanDir
echo "This is a backup of software repo." > $bakDir/README

case $mirrorSel in
1)
	mirrorSelArg="ustc"
	;;
2)
	mirrorSelArg="tuna"
	;;
*)
	echo "  ==> Keep current"
	return 0
	;;
esac

if [[ $dst == "Ubuntu" ]];then
	sed -i "s/eoan/$dstVersion/g" ./mirror/$mirrorSelArg/$dst/sources.list
fi

sudo cp -rf ./mirror/$mirrorSelArg/$dst/* $softwareDir
eval "sudo $pkgmng $mkCache"
}

apply(){
if [[ $USER != "root" ]];then
	# theme
	gsettings set org.gnome.desktop.interface gtk-theme Mojave-dark
	gsettings set org.gnome.desktop.wm.preferences theme Mojave-dark
	
	# icon
	gsettings set org.gnome.desktop.interface icon-theme Mojave-CT-Light
	
	# cursor
	gsettings set org.gnome.desktop.interface cursor-theme Capitaine-cursors-dark
	
	# window button
	gsettings set  org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
	
	#wallpaper
	gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/wallpaper.jpg"
else
	echo "  ==> Apply theme in root mode"
	echo "  ==> not supported. Skip"
fi
}

clean(){
	echo -e "\033[1;32m  ==> Clean cache \033[0m"
	cacheFile=($themeDir $iconDir $cursorDir $ohmyzshDir mirror wallpaper ../.deps)
	if [[ $USER != "root" ]];then
		for cFile in "${cacheFile[@]}"
		do
			echo "==> Remove $cFile"
			sleep .4
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

tips(){
cat<<TIPS

To start zsh experience :
  
    $ zsh
    
TIPS
}

install(){
	if [[ -f ../.deps ]];then unset taskList[2];unset taskList[3];fi
	echo "ALL TASK: ${taskList[@]}"
	#exit 1
	
	# handle task
	for _task in "${taskList[@]}"
	do
		echo -e "\n\033[1;34m  ==> Executing $_task ...\033[0m"
		$_task || exit 1
		echo -e "\033[1;32m  ==> Execute $_task done.\033[0m"
		sleep .5
	done
	handleZsh
	tips
}

# here begin
taskList=(os varConfig mirrorFile deps handle)

while getopts ":alrbcd" opt
do
case $opt in
	a)
		taskList[5]="apply"
		#taskList=(os varConfig mirror deps handle apply)
		;;
	l)
		gsettings set org.gnome.desktop.wm.preferences button-layout 'close:'
		;;
	r)
		gsettings set org.gnome.desktop.wm.preferences button-layout ':close'
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
		varConfig
		clean
		;;
	d)
		# for debuger, option ./install -d
		if [[ $USER != "root" ]];then
			gsettings set org.gnome.desktop.interface gtk-theme fdfhnifnhd
			gsettings set org.gnome.desktop.interface icon-theme fdjfhndnjfnh
			gsettings set org.gnome.desktop.background picture-uri dhsjhffuk
			gsettings set org.gnome.desktop.wm.preferences button-layout ':close'
		else
			echo "  ==> Try debug mode in User mode."
		fi
		exit 0
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
