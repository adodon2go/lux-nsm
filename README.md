# lux-nsm

Run below script for quick development setup (if inside Luxoft network define env variable LUXOFT_ENV=true):
> sh environment.sh

Installing NSM in Minikube:
>cd minikube
>sh nsm_install.sh
>sh nsm_install_examples.sh

Cleaning-up NSM in Minikube:
>sh nsm_cleanup_examples.sh
>sh nsm_cleanup.sh
>#Deleteing Minikube cluster
>minikube delete

Installing NSM in Kind:
>cd kind
>sh nsm_install.sh
>sh nsm_install_examples.sh

Cleaning-up NSM in Kind:
>sh nsm_cleanup_examples.sh
>#Clean-up NSM release inside Kind
>sh nsm_cleanup.sh
>#Deleting Kind cluster:
>sh kind_cleanup.sh