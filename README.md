# Echo Service - Flask Mock Endpoint Creator

## Table of Contents
- [Overview](#overview)
- [Design Choices](#design-choices)
- [Architecture](#architecture)
- [Terraform Architecture](#terraform-architecture)
- [Setup and Installation](#setup-and-installation)
- [Usage](#usage)
- [Testing](#testing)
- [Future Enhancements](#future-enhancements)

## Overview
The Echo Service is a Flask application designed to allow clients to create mock endpoints with pre-defined responses. It offers flexibility in creating, modifying, and deleting these mock endpoints.

## Design Choices
- **Framework** :  I have used the Flask framework due to its simplicity and because it's a lightweight framework.
- **Aws Architecture** : For deploying Flask application on AWS , we choose ECS with AWS Fargate.
- **Data Classes**: To ensure type safety and better documentation, Python data classes were used to define the data models.
- **Error Handling**: Custom error handlers were implemented to provide detailed and user-friendly error messages.
- **Logging**: Standard Python logging was implemented for easy troubleshooting and understanding the system flow.
- **Infrastructure-as-Code (IaC)**: The application is designed to be deployed on AWS using Terraform. 
- **Containerization** : Docker ensures that the application runs uniformly across different environments by packaging the app and its dependencies together

### AWS Architecture Choices
- I had three main options for deploying my flask application on Aws:
- 1)AWS Lambda with API Gateway - If you want to minimize maintenance and your traffic is sporadic, AWS Lambda is compelling for its simplicity
- 2)ECS with AWS Fargate  - If you need fine-grained control, predictable scaling and want predictable costs, ECS with Fargate is a strong contender
- 3)AWS Elastic Beanstalk - For generalized solutions or when starting out, Elastic Beanstalk is a balanced choice 


## Architecture
- The application follows the MVC pattern with a slight deviation given Flask's architectural preferences.
- **Model**: Defined using Python data classes in `models.py`.
- **View**: All endpoint functions are defined in `views.py`.
- **Controller**: While Flask merges views and controllers, additional business logic can be added in separate controllers/services if needed.
- Error handling is modularized in `errors.py`.
- The application is designed to be stateless, allowing it to scale horizontally if deployed in a cloud environment.


## Terraform Architecture
Using Infrastructure as Code (IaC) with Terraform provides a flexible and repeatable deployment process. This application is designed to be deployed on AWS, leveraging various services.

### AWS Resources

- **Virtual Private Cloud (VPC)**: Provides a secure and isolated environment for resources.
- **High Availability with Subnets**: By deploying the application across multiple subnets in different availability zones, we ensure that the application remains available even if one of the AWS data centers fails.
- **Internet Gateway**: To allow the Flask application to communicate with the external world, for example, to fetch updates or external APIs.
- **ECS with Fargate**: Used to run the Flask application in containers, without managing underlying infrastructure.
- **Elastic Load Balancer (ELB)**: Distributes incoming application traffic across multiple targets.
- **IAM Roles and Policies**: Gives permissions to AWS services to operate on your behalf.
- **Security Groups**: Acts as a virtual firewall, controlling incoming and outgoing traffic.
- **Auto-Scaling** : Automatically adjusts the number of ECS tasks based on defined metrics, ensuring application responsiveness during traffic surges and efficient resource usage during lulls.
- **CloudWatch Logging and Dashboard**: Monitors application performance and health, aggregating logs and metrics to offer insights and facilitate troubleshooting

### Deployment

1. Ensure AWS CLI is set up and credentials are configured.
2. Initialize Terraform: `terraform init`
3. Apply the configuration: `terraform apply`

### Cleanup

To prevent unnecessary costs, destroy the resources when done: `terraform destroy`

## Setup and Installation
1. Unzip  the given zip file.
2. Navigate to the project folder.
3. Install the required packages: `pip install -r requirements.txt`.
4. Run the application locally: `python main.py`.
5. For Docker setup:
   - Build the Docker image: `docker build -t echo-service .`.
   - Run the Docker container: `docker run -p 5000:5000 echo-service`.
6. Ensure that you build the Docker image and push it to a container registry (in our case its AWS Elastic Container Registry).
7. The var.docker_image_url in your Terraform code should then be set to the URL of this pushed image

## Usage
Detailed API documentation is provided in the `api_docs.md` file. The primary endpoints are:
- `POST /endpoints`: Create a new mock endpoint.
- `GET /endpoints`: List all the created mock endpoints.
- `PATCH /endpoints/:id`: Update an existing mock endpoint.
- `DELETE /endpoints/:id`: Delete an existing mock endpoint.
- The created mock endpoints can be accessed via their defined paths and HTTP methods.

## Testing
Tests are written using `pytest`. 
1. Navigate to the root project folder.
2. Run the tests: `pytest`.

## Future Enhancements
1. **Database Integration**: Integrate a database to persistently store the mock endpoints.
2. **Authentication & Authorization**: Integrate a complete Auth system.
3. **Multi-Stage-Dockerfile**: Multi-stage builds are used in Docker to minimize the final image size, typically by separating the build environment from the run environment. This is especially useful when building binaries from source code, but can also help in Python applications by excluding build tools and other unnecessary files. For a Flask application, the benefit of multi-stage builds can be minimal since Python is an interpreted language and doesn't generate separate binaries, but it still can be useful in specific contexts.Implement rate limiting to prevent abuse of the service.
4. **Queue Service (RabbitMQ)**: Implement a messaging system like RabbitMQ to handle asynchronous tasks, ensuring the application remains responsive even under high loads.
5. **Caching Mechanism**: Integrate caching solutions like Redis or Memcached to boost performance and reduce database load.
6. **Background Workers**: Use tools like Celery with RabbitMQ as the message broker to process background jobs, improving response times and offloading non-immediate processing tasks.