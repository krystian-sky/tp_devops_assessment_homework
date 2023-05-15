#Readme:

`mkdir tp_devops_assessment_homework`
`cd tp_devops_assessment_homework &&  git clone https://github.com/travelperk/devops-assessment.git`

I have created public github_repo https://github.com/krystian-sky/tp_devops_assessment_homework
`git clone https://github.com/krystian-sky/tp_devops_assessment_homework.git`

```
❯ python3 setup.py install FLASK_APP=hello flask run
invalid command name 'FLASK_APP=hello'

❯ export FLASK_APP=hello
❯ flask run
 * Serving Flask app 'hello'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:5000

 ❯ curl http://127.0.0.1:5000
Hello, World%    

Press CTRL+C to quit
127.0.0.1 - - [12/May/2023 20:46:05] "GET / HTTP/1.1" 200 -
```

####Working Dockerfile

```
# Use the official Python base image
FROM python:3.9.6-slim

# Set the working directory in the container
WORKDIR /app

# Copy the project files to the working directory
COPY . /app

# Install the project dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port that the Flask app will listen on
EXPOSE 5000

# Set the environment variable for Flask app
ENV FLASK_APP=hello

# Create a non-root user
RUN groupadd -r myuser && useradd -r -g myuser myuser

# Switch to the non-root user
USER myuser

# Set the entry point for the container
CMD ["flask", "run", "--host=0.0.0.0"]
```


`❯ docker run -p 5000:5000 flask-app`
 ```
 * Serving Flask app 'hello'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://172.17.0.2:5000
Press CTRL+C to quit
172.17.0.1 - - [13/May/2023 11:43:31] "GET / HTTP/1.1" 200 -
172.17.0.1 - - [13/May/2023 11:43:33] "GET / HTTP/1.1" 200 -
```


#### I have create access key and secret access key, to provide terraform access to aws
* Access key:
AKIAUNRVXJQKLZPIZ7HP

* Secret access key
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



I have wrote a working terraform code
```
# Define provider 
provider "aws" {
  region     = "eu-north-1"
  access_key = "AKIAUNRVXJQKLZPIZ7HP"
  secret_key = "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"
}

# Create VPC for the Fargate Cluster
resource "aws_vpc" "fargate_vpc" {
  cidr_block = "10.0.0.0/16"
}


# Create Internet Gateway
resource "aws_internet_gateway" "fargate_igw" {
  vpc_id = aws_vpc.fargate_vpc.id
}

# Create Public Subnet
resource "aws_subnet" "fargate_public_subnet" {
  vpc_id                  = aws_vpc.fargate_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
}

# Create Security Group for Fargate Cluster
resource "aws_security_group" "fargate_sg" {
  name        = "fargate-cluster-sg"
  description = "Security group for the Fargate cluster"

  vpc_id = aws_vpc.fargate_vpc.id

  ingress{
    cidr_blocks = ["0.0.0.0/0"]
    description = "From the internet"
    from_port   = 0
    protocol    = "tcp"
    to_port     = 65535
  }

  egress{
    cidr_blocks = ["0.0.0.0/0"]
    description = "To the internet"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}


# Create the Fargate Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
    name = "krystian-nowaczyk-fargate-cluster" 
}

# Output of the cluster ARN
output "cluster_arn" {
  value = aws_ecs_cluster.fargate_cluster.arn
}
```

* I have created local credentials 
`aws configure`

I have created ECR repository

```
❯ terraform apply
aws_vpc.fargate_vpc: Refreshing state... [id=vpc-02aa082df1d627826]
aws_ecr_repository.fargate_ecr_repository: Refreshing state... [id=krystian-nowaczyk]
aws_ecs_cluster.fargate_cluster: Refreshing state... [id=arn:aws:ecs:eu-north-1:303981612052:cluster/krystian-nowaczyk-fargate-cluster]
aws_internet_gateway.fargate_igw: Refreshing state... [id=igw-000f269687bea13de]
aws_subnet.fargate_public_subnet: Refreshing state... [id=subnet-04f2e0fb06f76002a]
aws_security_group.fargate_sg: Refreshing state... [id=sg-0a58db82c49512261]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

cluster_arn = "arn:aws:ecs:eu-north-1:303981612052:cluster/krystian-nowaczyk-fargate-cluster"
ecr_krystian_nowaczyk_repo_arn = "arn:aws:ecr:eu-north-1:303981612052:repository/krystian-nowaczyk"

```


Using local profile I managed to login to my ecr repo
`aws ecr get-login-password --region eu-north-1 | docker login --username krynow --password-stdin 303981612052.dkr.ecr.eu-north-1.amazonaws.com`



My Push commands
Build your Docker image using the following command. For information on building a Docker file from scratch, see the instructions here . You can skip this step if your image has already been built:

`docker build -t krystian-nowaczyk .`
After the build is completed, tag your image so you can push the image to this repository:

`docker tag krystian-nowaczyk:latest 303981612052.dkr.ecr.eu-north-1.amazonaws.com/krystian-nowaczyk:latest`
Run the following command to push this image to your newly created AWS repository:

`docker push 303981612052.dkr.ecr.eu-north-1.amazonaws.com/krystian-nowaczyk:latest`



#### I got stuck in terraform when I was trying to write the code for ELB. But the rest is working.
I have destoyed my enviroment, but I was unable to destroy ECR repo since it still contains my images

#### First version of Github Actions Workflow
```
name: Continuous Integration

on:
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.x

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: pytest

      - name: Run code linting
        run: pylint src

  deploy:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-north-1

      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster krystian-nowaczyk-fargate-cluster --service krystian-nowaczyk-service --force-new-deployment% 
```

### I tried to do as much as I can in 4h