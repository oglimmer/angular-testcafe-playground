# Angular - testcafe.io playground

## How to run

Assuming you have the AWS infrastructure running.

```
npm i
npm run start

npm run 2e2
```

## How to set up AWS

Use terraform

```
terraform init
terraform apply -auto-approve
```
Use the output variable `book-rest-api-endpoint` in src/app/book-list/books.service.ts
