# Angular - testcafe.io playground

## How to run

Assuming you have the AWS infrastructure running.

```
npm i
npm run start

npm run 2e2
```

## How to set up AWS

This assumes you own the domain "oglimmer.de", that you've added a *.oglimmer.de certificate to AWS in eu-central-1 and that you host the oglimmer.de zone within digital ocean.

Set the env variable DO_API_TOKEN with your digital ocean API TOKEN.

Use terraform

```
terraform init
terraform apply -auto-approve -var do_api_token=$DO_API_TOKEN
```
Use the output variable `book-rest-api-endpoint` in src/app/book-list/books.service.ts
