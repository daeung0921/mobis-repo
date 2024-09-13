## k8s CDRO Repository 

- CDRO Helm Chart 구성 후 Repository 추가시 사용

## 구성

**modules/tfinstall** 
- terraform 을 linux 환경에 설치하기 위한 sh 파일 포함됨

**modules/terraform-k8s-cdro-repo** 
- cdro 에 추가 repo 를 설치하기 위한 모듈
 
**main.tf**
- terraform-k8s-cdro-repo 모듈을 사용하는 예시 파일

**provider.tf**
- kubernetes provider 를 통해 k8s 에 연결하기 위한 provider 정보를 포함하는 파일

# TODO

1. 보내드린 파일에서 TODO 를 검색하세요.
2. 모비스 환경에 맞게 변경하세요.
3. 배포 및 동작을 확인하세요.