# Boardgame – Terraform + GitHub Actions (Pritunl VPN ke through)

## Structure

```
.github/workflows/
  terraform.yml   # infra: fmt -> validate -> plan -> (approval) apply / destroy
  container.yml   # CI checks: scan, compile, test, sonar, docker build, trivy, push, slack
  deploy.yml      # CD: private EC2 par docker deploy + health check + slack
  staging.yml     # override: container.yml + deploy.yml ko staging values ke saath call karta hai
terraform/
  main.tf  variables.tf  outputs.tf  provider.tf  backend.tf  terraform.tfvars
  envs/staging.tfvars
  modules/ vpc | vpc_peering | security_groups | ec2 | acm | alb | route53
```

## Architecture (diagram ke hisaab se)

```
User -> Route53 -> ALB (public subnets) -> Target group -> EC2 (private subnets, :8080)
        NAT GW (public-subnet-01) <- private route table
default-vpc (Pritunl + runner) <== VPC peering ==> boardgame-vpc
```

## Pritunl VPN wala part

- `deploy.yml` `runs-on: [self-hosted, linux, pritunl]` par chalta hai: ek self-hosted runner
  **default-vpc me (Pritunl ke saath)** lagao, label `pritunl`. VPC peering se wo private EC2 par SSH karega
  (EC2 ka port 22 sirf default-vpc CIDR se khula hai, public SSH nahi).
- Terraform workflow ko bhi VPN ke andar chalana ho to repo variable
  `RUNNER_LABELS` = `["self-hosted","linux","pritunl"]` set karo. Khali chhodoge to GitHub-hosted runner use hoga
  (AWS API ke liye VPN ki zarurat nahi).
- CI (`container.yml`) GitHub-hosted `ubuntu-latest` par chalta hai (build/scan ke liye VPN nahi chahiye).
- Runner par chahiye: `docker`, `git`, `curl`, `unzip`, `awscli`.
- Self-hosted runner sirf **private repo** par use karo.
- Pritunl server ke SG me peering ka traffic allow karo, aur Pritunl me route add karo: `10.0.0.0/16`
  (staging ke liye `10.1.0.0/16`) taaki VPN clients bhi private EC2 tak pahunchein.

## One-time setup

1. SSH key: `ssh-keygen -t ed25519 -f boardgame_deploy` -> `.pub` ka content `terraform/terraform.tfvars` me
   `ssh_public_key` me, private key GitHub secret `EC2_SSH_PRIVATE_KEY` me.
2. `terraform/terraform.tfvars` me `ssh_public_key` badlo. Domain (`domain_name`, `hosted_zone_name`) **last me**:
   khali rahe to app ALB DNS par HTTP se chalti hai; dono daalte hi HTTPS (ACM) + Route53 ban jata hai.
   Route53 public hosted zone pehle se honi chahiye.
3. AWS OIDC role (`AWS_ROLE_ARN`) ki permissions plan ke alawa **apply** ke liye bhi chahiye:
   EC2, VPC, ELB, ACM, Route53, IAM (role/instance profile), S3 state bucket.
4. State bucket: `devashish-boardgame-terraform-state-2026` (backend.tf me already hai).

## GitHub secrets / variables

| Type | Name | Use |
|---|---|---|
| Secret | `AWS_ROLE_ARN` | OIDC role |
| Secret | `EC2_SSH_PRIVATE_KEY` | deploy SSH key (private) |
| Secret | `DOCKERHUB_TOKEN` | Docker Hub access token |
| Secret | `SONAR_TOKEN` | SonarQube/SonarCloud (pehle se) |
| Secret | `SLACK_WEBHOOK_URL` | Slack incoming webhook |
| Variable | `DOCKERHUB_USERNAME` | Docker Hub user |
| Variable | `DOMAIN_NAME` | (per Environment) deploy ke baad domain check |
| Variable | `RUNNER_LABELS` | (optional) terraform runner |
| Variable | `SONAR_QUALITY_GATE_WAIT` | (optional) `true` = SonarCloud Quality Gate fail hone par CI fail. Default `false` |

Environments: `production` (Required reviewers ON), `staging`.

## Chalane ka order

1. Actions -> **Terraform Infra** -> Run workflow (production, `plan`) -> plan dekho.
2. **Apply sirf manual**: Actions -> Terraform Infra -> Run workflow -> action `apply` (main merge par auto-apply nahi hota).
3. `main` par push -> **CI Checks**. Infra ban jane ke baad repo variable `AUTO_DEPLOY=true` set karo, phir CI pass hone par **Deploy** auto chalega (tab tak Deploy ko manually Run workflow karo).
4. `staging` branch par push -> `staging.yml`. Pehle Terraform Infra se environment `staging` apply karo.

## Notes

- Existing flat `.tf` files modules me convert hui hain; diagram ke hisaab se ab 1 NAT gateway + 1 private route table hai.
- Domain set hone par ALB HTTPS (443, ACM) chalata hai aur HTTP:80 redirect karta hai; domain ke bina port 80 par seedha app.
- NAT sirf AZ-01 me hai – AZ-01 down hua to AZ-02 ke private instance ka outbound band ho jayega.
- Ye Terraform `terraform validate`/`plan` se abhi test nahi hua; pehle PR par plan chalao.
