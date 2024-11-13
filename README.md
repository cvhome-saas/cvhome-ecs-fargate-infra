### cvhome-ecs-fargate-infra
deployment for AWS ECS FARGATE
* preferred for prod

#### Steps to deploy
- fill the required fields for backend in `public-backend.conf`
- fill your customization in `app.auto.tfvars` for example `domain` , `certificate` `docker registery`
- run `terraform init -backend-config=public-backend.conf`
- run `terraform deploy`

#### Access the application
1. access the application
    
    | service     | url                        |
    |-------------|----------------------------|
    | auth        | http://auth.${domain}      |
    | welcome     | http://www.${domain}       |
    | store-ui    | http://store-ui.${domain}  |

2. to access the test stores, add `CNAME` record in your favorite domain registry (`namecheap`,`godaddy.com`)
    
    | host            | value                        |
    |-----------------|------------------------------|
    | new-domain1.com | saas-pod-gateway-1.${domain} |
    | new-domain2.com | saas-pod-gateway-1.${domain} |
    | new-domain3.com | saas-pod-gateway-1.${domain} |
    | new-domain4.com | saas-pod-gateway-1.${domain} |
3. login as org admin using `org1-admin@mail.com:admin` or `org2-admin@mail.com:admin` in `http://auth.${domain}`
4. for every store 
5. navigate to edit store domains
6. add the new domain with your domain

