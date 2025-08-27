# Домашнє завдання до теми «Вивчення Helm»

Конфігурація Terraform з набором модулей для підготовки інфраструктури на AWS.

- **S3** бакет і **DynamoDB** таблиця для remote backend стану Terraform.
- Базова **VPC** з публічними та приватними підмережами і маршрутизацією.
- **ECR** репозиторій з авто-скануванням образів та політикою доступу.

### Структура проєкту

```
lesson-7/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf
|   |
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію
│   │
│   ├── k8s-baseline/        # Модуль для налаштування Kubernetis кластера
│   │   ├── storageclass.tf  # Створення gp3 StorageClass
|   |   ├── versiones.tf
|   |
│   ├── eks/                 # Модуль для Kubernetes кластера
│   │   ├── eks.tf           # Створення кластера
|   |   ├── nodes.tf         # Группа вокер-нодів та IAM-ролі для неї
|   |   ├── addons.tf        # Додатки для EKS
│   │   ├── variables.tf     # Змінні для EKS
│   │   └── outputs.tf       # Виведення інформації про кластер
│
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     # ConfigMap зі змінними середовища
```

### Налаштування середовища і запуск розгортання інфраструктури

**Передумови:**

- AWS CLI v2 або AWS Tools for PowerShell (одне з двох має бути встановлене)
- Облікові дані з правами на: S3, DynamoDB, VPC, Subnet, Internet Gateway, Route Table, ECR.

**Налаштування облікових даних (тимчасові STS-токени)**

Можна використати або PowerShell AWS Tools, або AWS CLI

**PowerShell (AWS Tools for PowerShell):**

```
# Отримати тимчасові креденшіали (2 години)
$creds = Get-STSSessionToken -AccessKey <AWS_ACCESS_KEY> -SecretKey <AWS_SECRET_KEY> -DurationInSeconds 7200

$env:AWS_ACCESS_KEY_ID     = $creds.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $creds.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $creds.SessionToken
# (опційно) регіон
$env:AWS_REGION = "us-east-2"
```

**Bootstrapping бекенда (важливо)**

Якщо **S3 бакет** та **DynamoDB** таблиця для бекенда ще не існують:

1. Тимчасово закоментуйте блок `terraform` у `backend.tf` (або не підключайте файл).

2. Створіть ресурси локальним стейтом:

```
terraform init
terraform apply
```

3. Розкоментуйте блок `terraform` у `backend.tf` і мігруйте стейт:

```
terraform init -migrate-state
```

4. Далі працюйте як зазвичай (`plan/apply`) — тепер стейт зберігатиметься у S3 з блокуванням у DynamoDB.

Якщо бекенд уже існує — просто виконайте стандартні команди нижче.

**Команди для запуску**

1. Ініціалізація

```
terraform init
```

2. Перевірка плану змін

```
terraform plan
```

3. Застосування змін

```
terraform apply
```

Підтвердіть виконання, коли Terraform покаже план.

4. Знищення ресурсів

```
terraform destroy
```

### Опис модулів

#### s3-backend

- **Що створює:**

  - **S3** бакет для `terraform.tfstate` з версіонуванням та `BucketOwnerEnforced` ownership controls.
  - **DynamoDB** таблицю для блокування стейту.

- **Навіщо:** централізоване зберігання стейту і блокування для роботи в команді.
- **Ключові ресурси:** `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_ownership_controls`, `aws_dynamodb_table`.
- **Виводи:** `s3_bucket_name`, `dynamodb_table_name`.

#### vpc

- **Що створює:**

  - **VPC** з увімкненими DNS.
  - Набір **public** і **private** підмереж у вказаних **AZs**.
  - **Internet Gateway** для публічних підмереж.
  - **Route table** для виходу в інтернет + асоціації з public-subnets.

- **Навіщо:** базова мережева інфраструктура для розгортання ресурсів.
- **Ключові ресурси:** `aws_vpc`, `aws_subnet` (public/private), `aws_internet_gateway`, `aws_route_table`, `aws_route`, `aws_route_table_association`.
- **Виводи:** `vpc_id`, `public_subnets`, `private_subnets`, `internet_gateway_id`.

#### ecr

- **Що створює:**

  - **ECR repository** з `scan_on_push` та шифруванням (`AES256` або `KMS`).
  - **Repository policy**, яка дозволяє `push/pull` всередині вашого акаунту (Principal = `arn:aws:iam::<account_id>:root`).

- **Навіщо:** централізоване та кероване зберігання Docker/OCI-образів у межах AWS.
- **Ключові ресурси:** `aws_iam_policy_document`, `aws_ecr_repository`, `aws_ecr_repository_policy`.
- **Виводи:** `repository_url`, `repository_arn`, `repository_name`.

#### eks

- **Що створює:**

  - **IAM роль кластера** `(aws_iam_role.eks)` з trust-політикою для `eks.amazonaws.com` і прив’язкою політики `AmazonEKSClusterPolicy`.
  - **IAM роль вузлів** `(aws_iam_role.nodes)` з trust-політикою для `ec2.amazonaws.com` і прив’язками політик:
  - **AmazonEKSWorkerNodePolicy**
  - **AmazonEKS_CNI_Policy**
  - **AmazonEC2ContainerRegistryReadOnly**
  - **EKS кластер** `(aws_eks_cluster.eks)` з `access_config.authentication_mode = "API"` і `bootstrap_cluster_creator_admin_permissions = true`, з мережевою конфігурацією на заданих сабнетах.
  - **Managed Node Group** `(aws_eks_node_group.general)` з типом інстансів, масштабуванням і мітками вузлів.

  **Add-ons:**
    - **Amazon EBS CSI Driver** (`aws-ebs-csi-driver`) — керує EBS-томами для PVC/PV.
    - **EKS Pod Identity Agent** (`eks-pod-identity-agent`) — видача AWS-креденшіалів подам без OIDC/IRSA.
    - **metrics-server** — збір метрик CPU/Memory для kubectl top та HPA.

**Навіщо:** керований Kubernetes-кластер на AWS з мінімально необхідними IAM-ролями/політиками та одним керованим пулом вузлів.
**Ключові ресурси:** `aws_iam_role`, `aws_iam_role_policy_attachment`, `aws_eks_cluster`, `aws_eks_node_group`.
**Виводи:** `repository_url`, `repository_arn`, `repository_name`

### Розгортання через Helm: PostgreSQL + Django + HPA

#### Передумови:

- **Кластер EKS створений Terraform (з add-ons: `aws-ebs-csi-driver`, `eks-pod-identity-agent`, `metrics-server`).**
- **Є дефолтний `StorageClass` gp3 (CSI).**
- **`kubectl` та `helm` налаштовані на ваш кластер.**
- **Образ Django запушено в ECR.**

#### 1. Створити namespace для бази

```
kubectl create ns database
kubectl get ns
```

#### 2. Розгорнути PostgreSQL (Bitnami Helm chart)

```
# На всяк випадок перезапустимо контролер після Pod Identity association
kubectl -n kube-system rollout restart deploy/ebs-csi-controller

# Додаємо репозиторій з чартами Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Встановлюємо/оновлюємо PostgreSQL як release db в namespace database
helm upgrade --install db bitnami/postgresql -n database \
  --set global.postgresql.auth.username=django_user \
  --set global.postgresql.auth.password=pass9764gd \
  --set global.postgresql.auth.database=django_db \
  --set primary.persistence.enabled=true \
  --set primary.persistence.size=4Gi
  --set primary.persistence.storageClass=gp3
```

Перевірка, що том виділено та Pod запустився:

```
kubectl get pvc -n database -o wide
kubectl get pods -n database
kubectl logs statefulset/db-postgresql -n database --tail=50
```

DNS ім’я сервісу в кластері: `db-postgresql.database.svc.cluster.local:5432`

#### 3. Розгорнути кастомний Helm-чарт django-app

У цьому чарті:
- Service типу LoadBalancer для зовнішнього доступу
- HPA (autoscaling/v2) 2..6 реплік за CPU > 70%
- ConfigMap з env (включно з параметрами підключення до Postgres)

```
# з кореня проєкту
helm upgrade --install django-app ./charts/django-app -n default -f ./charts/django-app/values.yaml

# очікуємо успішний rollout
kubectl rollout status deploy/django-app-django -n default

# подивитись логи застосунку
kubectl logs deploy/django-app-django -n default --tail=100
```

Якщо ви щойно запушили новий тег образу, передайте його через `--set image.tag=<tag>`.
Якщо лишили тег `latest`, примусьте пул: `--set image.pullPolicy=Always та kubectl rollout restart deploy/django-app-django`.

####  4. Отримати публічний hostname застосунку

`kubectl get svc django-app-django -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'`

Відкривайте у браузері:

`http://<ELB-hostname>/`

#### 5. Перевірка метрик (metrics-server) і HPA

Переконайтесь, що метрики присутні:

```
kubectl top nodes
kubectl top pods -n default
```

Перевіряємо HPA:

```
kubectl get hpa -n default
kubectl describe hpa django-app-django -n default
```
