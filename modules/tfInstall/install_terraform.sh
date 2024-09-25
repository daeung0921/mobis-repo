#!/bin/bash

# 변수 정의
TERRAFORM_VERSION="1.6.0"  # 필요한 Terraform 버전으로 변경
TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}"

# Terraform 다운로드
wget ${TERRAFORM_URL} -O /tmp/${TERRAFORM_ZIP}

# 압축 해제
sudo unzip /tmp/${TERRAFORM_ZIP} -d /usr/local/bin/

# 다운로드한 파일 정리
rm /tmp/${TERRAFORM_ZIP}

# 설치 확인
terraform version
