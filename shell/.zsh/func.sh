apigw() {
  aws $1 apigateway get-method --rest-api-id $2 --resource-id $3 --http-method $4
}
ssmpf() {
  aws $1 ssm start-session \
    --target $2 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host=$3,portNumber=$4,localPortNumber=$5
}