ssmpf() {
  aws $1 ssm start-session \
    --target $2 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host=$3,portNumber=$4,localPortNumber=$5
}