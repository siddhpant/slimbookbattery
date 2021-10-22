#!/bin/bash
#Prepare terminal output formatting
INFO=""
WARN=""
DONE=""
BOLD=""
RESET=""
if $(tput -V &> /dev/null); then
	INFO=$(tput setaf 3)
	WARN=$(tput setaf 1)
	DONE=$(tput setaf 2)
	BOLD=$(tput bold)
	RESET=$(tput sgr0)
fi

echo $INFO$BOLD"This script will deploy SlimbookBattery in your system (replacing previous installation if exists)"
echo "Press ENTER to proceed"
echo "CTRL-C to exit"$RESET
read


#Used python binary
python="python3"
python_pck_installer="pip3"
#Parse entire repository looking for python import string
python_packages=$(grep -Re "^import" * | awk '{print $2}' | sort -u)

echo $INFO$BOLD"Checking Python dependencies..."
echo -n $RESET"Dependencies are: $python $python_pck_installer"
echo $python_packages
if [ ! $python ] && [ ! $python_pck_installer ];
then
	echo $WARN$BOLD"Please install $python and $python_pck_installer"
	echo -n $RESET
	exit 1
else 
	for package in $python_packages; do
		if ! $($python -c "import $package" &> /dev/null);
		then
			echo $INFO"Installing \"$python_pck_installer $package\"..."
			echo -n $RESET
			if $python_pck_installer install $package; 
			then
				echo $DONE"... done"
				echo -n $RESET
			else
				echo $WARN"... ERROR: could not install $package. Try to install manually and run this script again"
				echo -n $RESET
				exit 1
			fi
		fi
	done  
fi

echo
echo $INFO$BOLD"Check system dependencies..."
echo -n $RESET
system_dependencies="libindicator7 libappindicator1 gir1.2-gtk-3.0 gir1.2-gdkpixbuf-2.0 gir1.2-glib-2.0 libappindicator3-1 libgirepository-1.0-1 gir1.2-notify-0.7 gir1.2-appindicator3-0.1 tlp tlp-rdw libnotify-bin cron"

echo $INFO"Detecting your distro package manager..."
echo -n $RESET
packageman=""
if $(pamac --version &> /dev/null); then 		#Arch based distros
	packageman="pamac list | grep"
elif $(apt-get --version &> /dev/null); then 	#Debian based distros
	packageman="dpkg -l |grep"
elif $(yum --version &> /dev/null); then 		#CentOS based distros
	packageman="rpm -qa"
fi

echo $INFO"Looking for dependencie installed in your system..."
echo -n $RESET
for lib in $system_dependencies; do
	if ! $($packageman $lib &> /dev/null);
	then
		echo $WARN$BOLD"Missing package: $lib. Try to install using your distro package manager"
		echo -n $RESET
		exit 1
	fi
done
echo $DONE"... done"

echo
echo $INFO$BOLD"Deploying..."
echo -n $RESET
echo 
echo $INFO"Removing previously installed resources..."
echo -n $RESET
sudo rm -rf /usr/share/slimbookbattery/
echo
echo $INFO"Creating folder structure..."
echo -n $RESET
#TODO remove needed to create folder structure manually
sudo mkdir /usr/share/slimbookbattery
sudo mkdir /usr/share/slimbookbattery/images
sudo mkdir /usr/share/slimbookbattery/changelog
sudo mkdir /usr/share/slimbookbattery/src
sudo mkdir /usr/share/slimbookbattery/bin
while read line; do
	sudo cp -vrf $line
done < debian/install
echo
echo $INFO"Creating binary simlinks..."
echo -n $RESET
sudo rm /usr/bin/slimbookbattery /usr/bin/slimbookbattery-pkexec
sudo cp -sv /usr/share/slimbookbattery/bin/* /usr/bin/
sudo chmod +x /usr/share/slimbookbattery/bin/*
echo $DONE"... done"
echo -n $RESET

echo
echo $INFO$BOLD"Checking installation (post installation script and applying translations)"
echo -n $RESET
chmod +x debian/postinst
if ./src/check_config.py && ./debian/postinst && ./replace.sh ; then
	echo $DONE$BOLD"Done! SlimbookBattery properly deployed!"
	echo -n $RESET
	exit 0
else
	echo $WARN$BOLD"ERROR: See below otput, could not check your installation porperly"
	echo -n $RESET
	exit 1
fi
