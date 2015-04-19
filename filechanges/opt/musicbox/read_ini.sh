#
# Copyright (c) 2009    Kevin Porter / Advanced Web Construction Ltd
#                       (http://coding.tinternet.info, http://webutils.co.uk)
# Copyright (c) 2010-2015     Ruediger Meier <sweet_f_a@gmx.de>
#                             (https://github.com/rudimeier/)
#
# License: BSD-3-Clause, see LICENSE file
#
# Simple INI file parser.
#
# See README for usage.
#
#




function read_ini()
{
	# Be strict with the prefix, since it's going to be run through eval
	function check_prefix()
	{
		if ! [[ "${VARNAME_PREFIX}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] ;then
			echo "read_ini: invalid prefix '${VARNAME_PREFIX}'" >&2
			return 1
		fi
	}
	
	function check_ini_file()
	{
		if [ ! -r "$INI_FILE" ] ;then
			echo "read_ini: '${INI_FILE}' doesn't exist or not" \
				"readable" >&2
			return 1
		fi
	}
	
	# enable some optional shell behavior (shopt)
	function pollute_bash()
	{
		if ! shopt -q extglob ;then
			SWITCH_SHOPT="${SWITCH_SHOPT} extglob"
		fi
		if ! shopt -q nocasematch ;then
			SWITCH_SHOPT="${SWITCH_SHOPT} nocasematch"
		fi
		shopt -q -s ${SWITCH_SHOPT}
	}
	
	# unset all local functions and restore shopt settings before returning
	# from read_ini()
	function cleanup_bash()
	{
		shopt -q -u ${SWITCH_SHOPT}
		unset -f check_prefix check_ini_file pollute_bash cleanup_bash
	}
	
	local INI_FILE=""
	local INI_SECTION=""

	# {{{ START Deal with command line args

	# Set defaults
	local BOOLEANS=1
	local NV=0
	local VARNAME_PREFIX=INI
	local CLEAN_ENV=0
	local INDENT_LEVEL=0
	local CURRENT_INDENT_LEVEL=0
	local LONGEST_LINE=0

	# Regular expression so skip blank lines and commented out lines
	local RE_SKIP='^(\s*$)|^\s*(#|;)'

	# Regular expression to fine leading spaces
	RE_SPACES='^(\ +)'

	# Regular expression for tracking down section markers
	RE_SEC='\[([^]]+)\]'

	# Regular expression for value lines
	RE=''
    RE_REG='^(.*?)\s*(=|:)\s*(.+)$'

    # Regular expression to use if optional values are allowed
	RE_OPT='^(.*?)\s*(=|:)\s*(.*)$|(.*?)\s*$'
	#RE_OPT='^(.*?)\s*(?:(=|:)\s*(.*))?$'

	# {{{ START Options

	# Available options:
	#	--boolean		 Whether to recognise special boolean values: ie for 'yes', 'true'
	#					 and 'on' return 1; for 'no', 'false' and 'off' return 0. Quoted
	#					 values will be left as strings
	#					 Default: on
	#
	#	--allow_no_value Whether keys without values are allowed in the ini file: ie. 'key' or 'key='
	#					 Default: off
	#
	#	--prefix=STRING	 String to begin all returned variables with (followed by '__').
	#					 Default: INI
	#
	#	First non-option arg is filename, second is section name

	while [ $# -gt 0 ]
	do

		case $1 in

			--clean | -c )
				CLEAN_ENV=1
			;;

			--booleans | -b )
				shift
				BOOLEANS=$1
			;;

			--allow_no_value | -nv )
				NV=1
			;;

			--prefix | -p )
				shift
				VARNAME_PREFIX=$1
			;;

			* )
				if [ -z "$INI_FILE" ]
				then
					INI_FILE=$1
				else
					if [ -z "$INI_SECTION" ]
					then
						INI_SECTION=$1
					fi
				fi
			;;

		esac

		shift
	done

	if [ -z "$INI_FILE" ] && [ "${CLEAN_ENV}" = 0 ] ;then
		echo -e "Usage: read_ini [-c] [-b 0| -b 1] [-nv] [-p PREFIX] FILE"\
			"[SECTION]\n  or   read_ini -c [-p PREFIX]" >&2
		cleanup_bash
		return 1
	fi

	if ! check_prefix ;then
		cleanup_bash
		return 1
	fi

	local INI_ALL_VARNAME="${VARNAME_PREFIX}__ALL_VARS"
	local INI_ALL_SECTION="${VARNAME_PREFIX}__ALL_SECTIONS"
	local INI_NUMSECTIONS_VARNAME="${VARNAME_PREFIX}__NUMSECTIONS"
	if [ "${CLEAN_ENV}" = 1 ] ;then
		# TODO How to clear the whole array without unset it
		for i in "${!INI[@]}" ;do
			unset ${VARNAME_PREFIX}['$i']
		done
		eval unset "\$${INI_ALL_VARNAME}"
	fi

	# TODO How to declare -A ${VARNAME_PREFIX} non local? Or we have to
	# check for a global declared one
	unset ${INI_ALL_VARNAME}
	unset ${INI_ALL_SECTION}
	unset ${INI_NUMSECTIONS_VARNAME}

	if [ -z "$INI_FILE" ] ;then
		cleanup_bash
		return 0
	fi
	
	if ! check_ini_file ;then
		cleanup_bash
		return 1
	fi

	# Sanitise BOOLEANS - interpret "0" as 0, anything else as 1
	if [ "$BOOLEANS" != "0" ]
	then
		BOOLEANS=1
	fi

	if [ "$NV" == "0" ]
	then
	    RE=$RE_REG
	else
	    RE=$RE_OPT
	fi

    # Get longest line in the file - used to reset indentation level
	LONGEST_LINE=$(wc -L < "$INI_FILE")

	# }}} END Options

	# }}} END Deal with command line args

	local LINE_NUM=0
	local SECTIONS_NUM=0
	local SECTION=""

	# we need some optional shell behavior (shopt) but want to restore
	# current settings before returning
	local SWITCH_SHOPT=""
	pollute_bash
	
	while IFS= read -r line || [ -n "$line" ]
	do
#echo line = "$line"

		((LINE_NUM++))

		# Skip blank lines and comments
		if [[ "${line}" =~ $RE_SKIP ]]
		then
		    # Empty line marks end of value
		    INDENT_LEVEL="$LONGEST_LINE"
			continue
		fi

		# Check if multi-line value
        if [[ "${line}" =~ $RE_SPACES ]]
        then
            LEADING_SPACES="${BASH_REMATCH[1]}"
            CUR_INDENT_LEVEL=${#LEADING_SPACES}
        else
            CUR_INDENT_LEVEL=0
        fi

		# Section marker?
		if [[ "${line}" =~ $RE_SEC ]]
		then
			# Set SECTION var to name of section
			SECTION="${BASH_REMATCH[1]}"
			if ! [[ "${line}" =~ ^[[:print:]]+$  ]] ;then
				echo "Error: Invalid section:" >&2
				echo " ${LINE_NUM}: '$line'" >&2
				cleanup_bash
				return 1
			fi
			eval "${INI_ALL_SECTION}=\"\${${INI_ALL_SECTION}# } $SECTION\""
			((SECTIONS_NUM++))
			continue
		fi

		# Are we getting only a specific section? And are we currently in it?
		if [ ! -z "$INI_SECTION" ]
		then
			if [ "$SECTION" != "$INI_SECTION" ]
			then
				continue
			fi
		fi

		# Valid var/value line? (check for variable name and then '=' or ':')
        LINE_IS_VALID=1

		if [[ "${line}" =~ $RE ]]
		then
		    if [ $CUR_INDENT_LEVEL -gt $INDENT_LEVEL ]
		    then
                VAL="$VAL${line}"
		    else
		        VAR="${BASH_REMATCH[1]}"
			    VAL="${BASH_REMATCH[3]}"
			    INDENT_LEVEL=$CUR_INDENT_LEVEL
		    fi
		elif [ $CUR_INDENT_LEVEL -gt $INDENT_LEVEL ]
		then
		    line="${line##+([[:space:]])}"
            VAL="$VAL\\n${line}"
		else
	        LINE_IS_VALID=0
		fi

		if [ "$VAL" = "" ] && [ "$NV" = 0 ]
		then
		    LINE_IS_VALID=0
		fi

		if [ "$LINE_IS_VALID" = 0 ]
		then
		    echo "Error: Invalid line:" >&2
			echo " ${LINE_NUM}: '$line'" >&2
			cleanup_bash
			return 1
	    fi

		# delete spaces around the equal sign (using extglob)
		VAR="${VAR##+([[:space:]])}"
		VAR="${VAR%%+([[:space:]])}"

		VAL="${VAL##+([[:space:]])}"
		VAL="${VAL%%+([[:space:]])}"

		# Construct variable name:
		# ${VARNAME_PREFIX}__$SECTION__$VAR
		# Or if not in a section:
		# ${VARNAME_PREFIX}__$VAR
		# In both cases, full stops ('.') are replaced with underscores ('_')
		if [ -z "$SECTION" ]
		then
			VARNAME=${VAR//./_}
		else
			VARNAME=${SECTION}__${VAR//./_}
		fi
        eval "${INI_ALL_VARNAME}=\"\${${INI_ALL_VARNAME}# } ${VARNAME}\""

		if [[ "${VAL}" =~ (^\s*\")(.*)(\"\s*) ]]
		then
			# remove existing double quotes
			VAL="${BASH_REMATCH[2]}"
		elif [[ "${VAL}" =~ (^\s*\')(.*)(\'\s*) ]]
		then
			# remove existing single quotes
			VAL="${BASH_REMATCH[2]}"
		elif [ "$BOOLEANS" = 1 ]
		then
			# Value is not enclosed in quotes
			# Booleans processing is switched on, check for special boolean
			# values and convert

			# here we compare case insensitive because
			# "shopt nocasematch"
			case "$VAL" in
				yes | true | on )
					VAL=1
				;;
				no | false | off )
					VAL=0
				;;
			esac
		fi

#  		echo "pair: '${VARNAME}' = '${VAL}'"
		eval ${VARNAME_PREFIX}$'[${VARNAME}]=${VAL}'
# 		eval $'echo "array: \'${VARNAME}\' = \'${'${VARNAME_PREFIX}$'[${VARNAME}]}\'"'

	done  <"${INI_FILE}"
	
	# return also the number of parsed sections
	eval "$INI_NUMSECTIONS_VARNAME=$SECTIONS_NUM"

	cleanup_bash
}


