apigw() {
  aws $1 apigateway get-method --rest-api-id $2 --resource-id $3 --http-method $4
}