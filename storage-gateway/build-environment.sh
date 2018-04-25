
usage () {
	echo ""
	echo "Usage: $0 -s <MasterStackName> -k <KeyPairName>"
	echo "  -s: Master stack name, should be short - 2-3 characters"
	echo "  -k: EC2 Key Pair name to leverage for simulated host access"
	echo "  -b: S3 bucket name to use for working directory for CloudFormation"
	echo ""
}

BUCKET=
MASTERSTACKNAME=
SIMHOSTKEYNAME=

while getopts b:s:k: o
do
	case $o in 
		b)
			BUCKET=$OPTARG
			;;
		s)
			MASTERSTACKNAME=$OPTARG
			;;
		k)
			SIMHOSTKEYNAME=$OPTARG
			;;
		\?)
			usage
			exit -1
			;;
		:)
			usage
			exit -1
			;;
		*)
			usage
			exit -1
			;;
	esac
done

if [ ! "$MASTERSTACKNAME" ] || [ ! "$SIMHOSTKEYNAME" ] || [ ! "$BUCKET" ] 
then
	usage
	exit -1
fi

aws cloudformation package --template-file  simulated-host-stack.json --s3-bucket $BUCKET --output-template-file simulated-host-stack-packaged.json
aws s3 cp ./simulated-host-stack-packaged.json  s3://${BUCKET}/

echo done
