#!/bin/bash

PREFIX=/usr
INITDIR=${PREFIX}/lib/systemd/system
INITDIR_UBUNTU=${PREFIX}/lib/systemd/system
USERDIR=${PREFIX}/lib/sysusers.d
TMPFDIR=${PREFIX}/lib/tmpfiles.d
UDEVDIR=${PREFIX}/lib/udev/rules.d
POLKDIR=${PREFIX}/share/polkit/rules.d
MANDIR=${PREFIX}/share/man/man1
ENVDIR=/etc/conf.d

MYDIR=$(dirname $0)

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

ECHO=echo

function udevrules {
	MYFILE=${MYDIR}/$(arch)/udev/99-kodi.rules
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			$ECHO ${INSTALL_DATA} ${MYFILE}
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			$ECHO ${RM} ${MYFILE}
			;;
	esac
}

function polkitrules {
	MYFILE=${MYDIR}/common/polkit/polkit.rules
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			$ECHO ${INSTALL_DATA} ${MYFILE}
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			$ECHO ${RM} ${MYFILE}
			;;
	esac
}

function systemd_sysusers {
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			;;
	esac
}

function systemd_tmpfiles {
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			;;
	esac
}

function systemd_service {
	# Note to self: Environment nicht vergessen!
	case $INSTCMD in
		$DOINST)
			printf 'Installing %s\n' $FUNCNAME
			;;
		$DOUNINST)
			printf 'Uninstalling %s\n' $FUNCNAME
			;;
	esac
}

install_tasks=( \
udevrules \
polkitrules \
systemd_sysusers \
systemd_tmpfiles \
systemd_service \
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
