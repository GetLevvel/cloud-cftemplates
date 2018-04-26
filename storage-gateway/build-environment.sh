
usage () {
	echo ""
	echo "Usage: $0 -s <MasterStackName> -k <KeyPairName> [-b <BucketName>] [-p <AWSProfile>]"
	echo "  -s: Master stack name, should be short - 2-3 characters"
	echo "  -k: EC2 Key Pair name to leverage for simulated host access"
	echo "  -b: S3 bucket name to use for working directory for CloudFormation"
	echo "  -p: Default profile will be used unless you specify a different profile"
	echo ""
}

AWSPROFILE=
BUCKET='levvel-cloud-build-environment'
MASTERSTACKNAME=
SIMHOSTKEYNAME=
SIMHOSTREGION='us-west-2'

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
		p)
			AWSPROFILE=$OPTARG
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

if [ ! "$MASTERSTACKNAME" ] || [ ! "$SIMHOSTKEYNAME" ]
then
	usage
	exit -1
fi

aws ${AWSPROFILE:+--profile $AWSPROFILE}cloudformation package --template-file  simulated-host-stack.json --s3-bucket $BUCKET --output-template-file simulated-host-stack-packaged.json
aws ${AWSPROFILE:+--profile $AWSPROFILE}s3 mv ./simulated-host-stack-packaged.json  s3://${BUCKET}/
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOSTREGION cloudformation create-stack --stack-name ${MASTERSTACKNAME}-SimulatedOnPremises --capabilities CAPABILITY_NAMED_IAM --template-url https://s3.amazonaws.com/${BUCKET}/simulated-host-stack-packaged.json --parameters ParameterKey=MasterStackName,ParameterValue=$STACKNAME ParameterKey=EC2Key,ParameterValue=$SIMHOSTKEYNAME
aws ${AWSPROFILE:+--profile $AWSPROFILE} --region $SIMHOSTREGION cloudformation wait stack-create-complete --stack-name ${MASTERSTACKNAME}-SimulatedOnPremises

echo done
