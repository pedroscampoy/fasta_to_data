#!/bin/bash

# Exit immediately if a pipeline, which may consist of a single simple command, a list,
#or a compound command returns a non-zero status: If errors are not handled by user
#set -e
#set -x

#=============================================================
# HEADER
#=============================================================

#INSTITUTION:ISCIII
#CENTRE:
#AUTHOR: Pedro J. Sola (pedroscampoy@gmail.com)
VERSION=1.0
#CREATED: 25 Jan 2019
#
#DESCRIPTION:fasta_to_data script obtain a multifasta with similar sequences from nr ncbi database filtered by size
#
#
#
#
#
#wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
#tar -zxf taxdb.tar.gz
#
#export BLASTDB=$BLASTDB:/processing_Data/bioinformatics/research/20181119_UNSGM-REFBIO_RE_C/ANALYSIS/12-BLAST
#
#
#================================================================
# END_OF_HEADER
#================================================================

#SHORT USAGE RULES
#LONG USAGE FUNCTION
usage() {
	cat << EOF

fasta_to_data script obtain a multifasta with similar sequences from nr ncbi database filtered by size

usage : $0 <-i inputfile(.fasta)> <-b id cutoff> [-o <directory>] [-b <int(0-100)>] [-l <int(0-100)>]
		[-p <prefix>] [-d <delimiter>] [-D (l|r)] [-q <delimiter>] [-Q (l|r)] [-I] [-u] [-v] [-h]

	-i input file
	-b blast identity cutoff (0 - 100), default 90
	-l blast length percentage cutoff (0 - 100), default 50, use 90 for genes
	-o output directory (optional). By default the file is replaced in the same location
	-f file name
	-s smallest size
	-S largest size
	-v version
	-h display usage message

example: blast_to_complete.sh -i ecoli_prefix.blast
EOF
}

#================================================================
# OPTION_PROCESSING
#================================================================
#Make sure the script is executed with arguments
if [ $# = 0 ] ; then
 usage >&2
 exit 1
fi

# Error handling
error(){
  local parent_lineno="$1"
  local script="$2"
  local message="$3"
  local code="${4:-1}"

	RED='\033[0;31m'
	NC='\033[0m'

  if [[ -n "$message" ]] ; then
    echo -e "\n---------------------------------------\n"
    echo -e "${RED}ERROR${NC} in Script $script on or near line ${parent_lineno}; exiting with status ${code}"
    echo -e "MESSAGE:\n"
    echo -e "$message"
    echo -e "\n---------------------------------------\n"
  else
    echo -e "\n---------------------------------------\n"
    echo -e "${RED}ERROR${NC} in Script $script on or near line ${parent_lineno}; exiting with status ${code}"
    echo -e "\n---------------------------------------\n"
  fi

  exit "${code}"
}

# Check mandatory files function
check_mandatory_files() {
	missing_files=0
	for file in "$@"; do
		if [ ! -f $file ]; then
			echo "$(basename $file)" "not supplied, please, introduce a valid file" >&2
			let missing_files++
		fi
	done

	if [ $missing_files -gt 0 ]; then 
		echo "ERROR: $missing_files missing files, aborting execution" >&2
		exit 1
	fi
}


#This function check all dependencies listed and exits if any is missing
check_dependencies() {
	missing_dependencies=0
	for command in "$@"; do
		if ! [ -x "$(which $command 2> /dev/null)" ]; then
			echo "Error: Please install $command or make sure it is in your path" >&2
			let missing_dependencies++
		else
			echo "$command installed"
		fi
	done

	if [ $missing_dependencies -gt 0 ]; then 
		echo "$missing_dependencies missing dependencies, aborting execution" >&2
		exit 1
	fi
}

#DECLARE FLAGS AND VARIABLES
cwd="$(pwd)"
input_file="Input_file"
blast_id_cutoff=90
blast_len_percentage=15
small_length=1000
large_length=1000000
$threads=4

#PARSE VARIABLE ARGUMENTS WITH getops
#common example with letters, for long options check longopts2getopts.sh
options=":i:b:o:f:l:s:S:vh"
while getopts $options opt; do
	case $opt in
		i )
			input_file=$OPTARG
			;;
		b )
			if [ $OPTARG -lt 0 ] || [ $OPTARG -gt 100 ]; then
				echo "please, provide a percentage between 0 and 100"
				exit 1
			else
				blast_id_cutoff=$OPTARG
			fi
			;;
		o )
			output_dir=$OPTARG
			;;
		f )
			file_name=$OPTARG
			;;
		l )
			if [ $OPTARG -lt 0 ] || [ $OPTARG -gt 100 ]; then
				echo "please, provide a percentage between 0 and 100"
				exit 1
			else
				blast_len_percentage=$OPTARG
			fi
			;;
		s )
			small_length=$OPTARG
			;;
		S )
			large_length=$OPTARG
			;;
		T )
			$threads=$OPTARG
			;;
        h )
		  	usage
		  	exit 1
		  	;;
		v )
		  	echo $VERSION
		  	exit 1
		  	;;
		\?)
			echo "Invalid Option: -$OPTARG" 1>&2
			usage
			exit 1
			;;
		: )
      		echo "Option -$OPTARG requires an argument." >&2
      		exit 1
      		;;
      	* )
			echo "Unimplemented option: -$OPTARG" >&2;
			exit 1
			;;

	esac
done
shift $((OPTIND-1))

#================================================================
# MAIN_BODY
#================================================================
##CHECK DEPENDENCIES, MANDATORY FIELDS, FOLDERS AND ARGUMENTS

echo -e "\n#Executing" $0 "\n"

check_mandatory_files $input_file
check_dependencies blastn wget curl

blast_len_percentage_value=$(echo "($blast_len_percentage/100)" | bc -l)
#blast_len_percentage_decimal=$(echo $blast_len_percentage_value | sed 's/0\{1,\}$//')


if [ ! $output_dir ]; then
	output_dir=$(dirname $input_file)
	#echo "Default output directory is" $output_dir
	mkdir -p $output_dir
else
	#echo "Output directory is" $output_dir
	mkdir -p $output_dir
fi


if [ ! $file_name ]; then
	file_name=$(basename $input_file | cut -d. -f1)
fi


echo "$(date)"
echo "Searching similar sequences with BLAST on" $(basename $input_file)
#echo "Blast identity=" $blast_id_cutoff
#echo "Min len percentage=" $blast_len_percentage


blastn \
-db nr \
-query $input_file \
-max_target_seqs 1 \
-remote \
-out $file_name.blast \
-outfmt "6 qseqid sacc pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"

#ssciname sskingdom
#-num_descriptions
#-num_alignments


echo "$(date)"
echo "DONE searching similar sequences with BLAST"










#echo "$(date)"
#echo "DONE adapting blast to complete"
#echo -e "File can be found at" $output_dir/$file_name".complete" "/n"
