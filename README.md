# eks_workshop_aws

강좌URL: https://catalog.us-east-1.prod.workshops.aws/workshops/9c0aa9ab-90a9-44a6-abe1-8dff360ae428/ko-KR/

[설치 환경 구성]
1. IDE(AWS Cloud9 인스턴스)에 IAM Role 부여  
IAM > 역할 > 역할 만들기 [버튼] > 엔터티 유형: AWS 서비스 선택, 사용 사례: EC2 선택 [다음] > 권한 정책 AdministratorAccess 검색하여 선택 [다음] > 역할이름: 07531-eksworkspace-admin 입력, 태그 입력 [역할생성]  
EC2 > 인스턴스 > Cloud9 인스턴스 선택 > 우측 상단 [작업]-[보안]-[IAM 역할수정] > IAM 역할 선택 [저장]  

2. IDE에서 IAM 설정 업데이트  
Cloud9 재접속 > 우측 상단 [기어 아이콘] > 사이드 바의 [AWS SETTINGS] > Credentials 항목에서 AWS managed temporary credentials 설정을 비활성화  
기존 자격 증명 파일 제거 및 해당 IAM Role 사용 여부 확인  
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
현재 리전을 기본값으로 설정  
$ export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')  
$ echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile  
$ aws configure set default.region ${AWS_REGION}  
$ aws configure get default.region  
현재 계정ID를 환경 변수로 등록  
$ export ACCOUNT_ID=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId')  
$ echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile  
Cloud9 VM Disk 용량 증설  
$ wget https://gist.githubusercontent.com/joozero/b48ee68e2174a4f1ead93aaf2b582090/raw/2dda79390a10328df66e5f6162846017c682bef5/resize.sh  
$ sh resize.sh  
$ df -h  

8. Access Key 생성 및 PATH 등록  
IAM 서비스 > 사용자 > 보안자격증명 탭 > 액세스키 만들기 버튼 클릭 (아래 CMD 수행 위해 팝업창 유지)  
$ echo "export AWS_ACCESS_KEY_ID=[키 ID 입력]" >> ~/.bash_profile  
$ echo "export AWS_SECRET_ACCESS_KEY=[키 값 입력]" >> ~/.bash_profile  
$ echo "export AWS_DEFAULT_REGION=[리전 ID 입력]" >> /.bash_profile  
$ echo "export PATH=$PATH:/environment" >> ~/.bash_profile $ source ~/.bash_profile  

9. CodeCommit 자격증명 생성  
IAM 서비스 > 사용자 > 보안자격증명 탭 > AWS CodeCommit에 대한 HTTPS Git 자격 증명 항목 > 자격증명 생성 버튼 클릭  

10. Terraform 소프트웨어 다운로드 및 압축 해제  
브라우저에서 https://www.terraform.io/downloads.html 에 접속하여 Linux 64-bit 다운로드 링크 복사  
$ cd ~/environment $ wget https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip $ unzip terraform_0.13.3_linux_amd64.zip  

11. 인스턴스 접속을 위한 키 페어 생성  
$ cd ~/.ssh $ ssh-keygen 엔터 3번하여 key 생성 완료  

[Terraform 소스 적용]  
- 테라폼 소스 적용 전 variable.tf 수정 및 확인   
$ cd ~/environment/final_pjt  
$ terraform init  
$ terraform plan  
$ terraform apply --auto-approve  

[github]
- 소스 수정 후 아래 command  
$ git add *  
$ git commit -m "commit"  
$ git push origin main  
name : sk2ckr  
password : access token 붙여넣기(기한 만료 시 github에서 access token regenerate)  

- github access token regenerate  
Settings > Developer settings > Personal access tokens > [token] 선택 > [Regenerate Token]  
