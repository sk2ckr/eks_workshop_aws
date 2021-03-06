# eks_workshop_aws

강좌URL: https://catalog.us-east-1.prod.workshops.aws/workshops/9c0aa9ab-90a9-44a6-abe1-8dff360ae428/ko-KR/

[설치 환경 구성]
1. IDE(AWS Cloud9 인스턴스)에 IAM Role 부여  
IAM > 역할 > 역할 만들기 [버튼] > 엔터티 유형: AWS 서비스 선택, 사용 사례: EC2 선택 [다음] > 권한 정책 AdministratorAccess 검색하여 선택 [다음] > 역할이름: 07531-eksworkspace-admin 입력, 태그 입력 [역할생성]  
EC2 > 인스턴스 > Cloud9 인스턴스 선택 > 우측 상단 [작업]-[보안]-[IAM 역할수정] > IAM 역할 선택 [저장]  

2. IDE에서 IAM 설정 업데이트  
Cloud9 재접속 > 우측 상단 [기어 아이콘] > 사이드 바의 [AWS SETTINGS] > Credentials 항목에서 AWS managed temporary credentials 설정을 비활성화  
- 기존 자격 증명 파일 제거 및 해당 IAM Role 사용 여부 확인  
$ rm -vf ${HOME}/.aws/credentials  
$ aws sts get-caller-identity --query Arn | grep 07531-eksworkspace-admin  

3. AWS CLI 업데이트  
$ sudo pip install --upgrade awscli  

4. kubectl 설치  
$ sudo curl -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl  
$ sudo chmod +x /usr/local/bin/kubectl  
$ kubectl version --client=true --short=true  
출력확인: Client Version: v1.21.2-13+d2965f0db10712  

5. 기타 툴 설치  
$ sudo yum install -y jq  
$ sudo yum install -y bash-completion  

6. eksctl 설치  
$ curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp  
$ sudo mv -v /tmp/eksctl /usr/local/bin  
$ eksctl version  

7. Cloud9 추가 세팅  
- 현재 리전을 기본값으로 설정  
$ export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')  
$ echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile  
$ aws configure set default.region ${AWS_REGION}  
$ aws configure get default.region  
- 현재 계정ID를 환경 변수로 등록  
$ export ACCOUNT_ID=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId')  
$ echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile  
- Cloud9 VM Disk 용량 증설  
$ wget https://gist.githubusercontent.com/joozero/b48ee68e2174a4f1ead93aaf2b582090/raw/2dda79390a10328df66e5f6162846017c682bef5/resize.sh  
$ sh resize.sh  
$ df -h  

8. Terraform 소프트웨어 다운로드 및 설치  
- 브라우저에서 https://www.terraform.io/downloads 에 접속하여 Linux / Amazon Linux 탭 선택하여 Command 수행  
$ sudo yum install -y yum-utils  
$ sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo  
$ sudo yum -y install terraform  

9. 소스 마이그레이션  
- 테라폼 소스 적용 전 variable.tf 수정 및 확인  
- 스크립트 권한 변경  
$ chmod +x ${HOME}/environment/eks_workshop_aws/terraform/hash.sh  
$ chmod +x ${HOME}/environment/eks_workshop_aws/terraform/push.sh  

[github]  
- 소스 수정 후 아래 command  
$ git add *  
$ git commit -m "commit"  
$ git push origin main  
name : sk2ckr  
password : access token 붙여넣기(기한 만료 시 github에서 access token regenerate)  

- github access token regenerate  
Settings > Developer settings > Personal access tokens > [token] 선택 > [Regenerate Token]  

- terraform 관련 불필요 파일(terraform-provider-aws_v4.9.0_x5 등) 업로드 시도 시 아래 command 수행  
$ git filter-branch -f --index-filter 'git rm --cached -r --ignore-unmatch terraform/.terraform/'  

[Post Script]  
- 콘솔 크레덴셜 추가  
$ rolearn=$(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn')  
$ eksctl create iamidentitymapping --cluster eks-demo --arn ${rolearn} --group system:masters --username admin  
$ aws eks --region ap-northeast-2 update-kubeconfig --name eks-demo