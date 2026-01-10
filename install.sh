#!/bin/bash
#set -x

MYDIR=$(dirname $0)
INITDIR=/etc/systemd/system
UDEVDIR=/etc/udev/rules.d
POLKDIR=/etc/polkit-1/rules.d
KODI_USERNAME=kodi
KODI_USERHOME=/var/lib/kodi

RM='sudo rm'
INSTALL="sudo install -p"
INSTALL_DIR="${INSTALL} -d"
INSTALL_PROGRAM="${INSTALL} -m755"
INSTALL_DATA="${INSTALL} -m644"

DOINST=doinst
DOUNINST=douninst
INSTCMD=$DOINST
if [[ $# > 0 && ${1} == -u ]]; then
	INSTCMD=$DOUNINST
fi

#ECHO=echo

function handlefile {
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' ${1}
			$ECHO ${INSTALL_DATA} ${2} ${3}
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' ${1}
			$ECHO ${RM} ${3}/$(basename ${2})
			;;
	esac
}

function udevrules {
	handlefile ${FUNCNAME} ${MYDIR}/$(arch)/udev/99-kodi.rules ${UDEVDIR}
}

function polkitrules {
	# This kodi-polkit.rules files references account "kodi" by name!
	handlefile ${FUNCNAME} ${MYDIR}/common/polkit/kodi-polkit.rules ${POLKDIR}
}

function kodiuser {
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			if $(id -u $KODI_USERNAME >/dev/null 2>/dev/null); then
				printf 'User %s exists already. Doing nothing!\n'
			else
				$ECHO sudo useradd \
					--home-dir $KODI_USERHOME \
					--comment 'Kodi System User' \
					--user-group \
					--system \
					--groups audio,video,dialout,input,cdrom,render \
					--create-home \
					$KODI_USERNAME
			fi
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			if $(id -u $KODI_USERNAME >/dev/null 2>/dev/null); then
				$ECHO sudo userdel \
					--force \
					--remove \
					$KODI_USERNAME
			else
				printf 'User %s does not exist. Doing nothing!\n' $KODI_USERNAME
			fi
			sleep 10 # to wait for shutdown of all processes of user $KODI_USERNAME
			if $(id -g $KODI_USERNAME >/dev/null 2>/dev/null); then
				$ECHO sudo groupdel \
					--force \
					$KODI_USERNAME
			else
				printf 'Group %s does not exist. Doing nothing!\n' $KODI_USERNAME
			fi
			;;
	esac
}

function systemd_service {
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			handlefile ${FUNCNAME}_definition ${MYDIR}/common/init/kodi.service ${INITDIR}
			$ECHO sudo systemctl daemon-reload
			$ECHO sudo systemctl enable kodi.service
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			$ECHO sudo systemctl stop kodi.service
			$ECHO sudo systemctl disable kodi.service
			handlefile ${FUNCNAME}_definition ${MYDIR}/common/init/kodi.service ${INITDIR}
			$ECHO sudo systemctl daemon-reload
			;;
	esac
}

function disable_graphical_login {
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			$ECHO sudo systemctl set-default multi-user.target
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			$ECHO sudo systemctl set-default graphical.target
			;;
	esac
}

install_tasks=( \
udevrules \
polkitrules \
kodiuser \
systemd_service \
disable_graphical_login \
)

printf 'Doing the work...\n'

idx=0
numtasks=${#install_tasks[*]}
while [[ $idx < $numtasks ]]; do
	case $INSTCMD in
		$DOINST)
			${install_tasks[$idx]}
			;;
		$DOUNINST)
			${install_tasks[(($numtasks-$idx-1))]}
			;;
	esac
	((idx++))
done

printf '...done\n'
