#!/bin/sh
#
# List available public recipient keys, encrypt the file
# for the specified recipient by his/her public key and sign it
# with your own key.
#
# * Put this file into your home binary dir: ~/bin/
# * Make it executable: chmod +x
#
#
# Required Software:
# -------------------------
#   * gpg
#	* zenity
#	* pinentry-gtk-2
#
#
# Thunar Integration
# ------------------------
#
#   Command:      ~/bin/thunar-gpg-encrypt.sh -f %f
#   File Pattern: *
#   Appear On:    Select everything
#
#
# Usage:
# -------------------------
#   thunar-gpg-encrypt.sh -f <filename>
#
#     required:
#      -f    input filename
#
# Note:
# -------------------------
#
# Feel free to adjust/improve and commit back to:
#  https://github.com/cytopia/thunar-custom-actions
#


usage() {
	echo "$0 -f <filename>"
	echo
	echo " required:"
	echo "   -f    input filename"
	echo
}


while getopts ":f:" i; do
	case "${i}" in
		f)
			f=${OPTARG}
			;;
		*)
			echo "Error - unrecognized option $1" 1>&2;
			usage
			;;
	esac
done
shift $((OPTIND-1))

# Check if file is specified
if [ -z "${f}" ]; then
	echo "Error - no file specified" 1>&2;
	usage
	exit 1
fi

# Check if gpg exists
if ! command -v gpg >/dev/null 2>&1 ; then
	echo "Error - 'gpg' not found." 1>&2
	exit 1
fi

# Check if pinentry-gtk-2 exists
if ! command -v pinentry-gtk-2 >/dev/null 2>&1 ; then
	echo "Error - 'pinentry-gtk-2' not found." 1>&2
	exit 1
fi

# Check if zenity exists
if ! command -v zenity >/dev/null 2>&1 ; then
	echo "Error - 'zenity' not found." 1>&2
	exit 1
fi


chooseRecipient () {

	pubkeys="$(gpg --list-public-keys \
	  | /bin/grep -A 1 "^pub" \
    | sed -n -e "s:^pub *\([A-Za-z0-9]\+\)/\([A-F0-9]\+\) .*$:\1 \2:p" -e "s:^uid *\(.*\)$:\"\1\":p")" #\
	  #| tr '\n' ' ')"


	CMD="zenity --list \
	       --width=550 --height=250 \
	       --title=\"GPG Encrypt File for...\" \
	       --print-column=1 \
	       --text=\"Choose Recipient\" \
	       --column=\"Key\" --column=\"Bit\" --column=\"Recipient\" ${pubkeys}"

	eval "${CMD}"
}


chooseSecret () {

	seckeys="$(gpg --list-secret-keys \
	  | grep -A 1 "^sec" \
	  | sed -n -e "s:^sec *\([A-Za-z0-9]\+\)/\([A-F0-9]\+\) .*$:\1 \2:p" -e "s:^uid *\(.*\)$:\"\1\":p" \
	  | tr '\n' ' ')"


	CMD="zenity --list \
	       --width=550 --height=250 \
	       --title=\"Choose private key...\" \
	       --print-column=1 \
	       --text=\"Choose your private key\" \
	       --column=\"Key\" --column=\"Bit\" --column=\"Secret Key\" ${seckeys}"

	eval "${CMD}"
}

readPassword () {
    echo "GETPIN" | pinentry-gtk-2 2> /dev/null | grep "D" | awk '{print $2}'
}


#r="$(chooseRecipient)"
r="mark@connaire-mor"
if [ -z "${r}" ]; then
	zenity --error --text="No Recipient specified."
	exit 1
fi
# fix zenity bug on double click
# https://bugzilla.gnome.org/show_bug.cgi?id=698683
r="$(echo "${r}" | awk '{split($0,a,"|"); print a[1]}')"



#u="$(chooseSecret)"
u="mark@connaire-mor"
if [ -z "${u}" ]; then
	zenity --error --text="No Secret key specified."
	exit 1
fi
# fix zenity bug on double click
# https://bugzilla.gnome.org/show_bug.cgi?id=698683
u="$(echo "${u}" | awk '{split($0,a,"|"); print a[1]}')"



p="$(readPassword)"
if [ -z "${p}" ]; then
	zenity --error --text="No Password specified."
	exit 1
fi


error="$(gpg -e -s --yes --batch --local-user "${u}" --recipient "${r}" --passphrase "${p}" "${f}" 2>&1)"
errno=$?

if [ "$errno" -gt "0" ]; then
	zenity --error --text="${error}\nreturn code: ${errno}"
	exit 1
else
	zenity --info --text="Encrypted."
	exit $?
fi
