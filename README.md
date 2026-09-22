# Cloud-Native Microservices Architecture (Go & AWS)

**Tech Stack:** Go (Gin-Gonic), AWS (ECS Fargate, SQS, DynamoDB, RDS),
Terraform, Docker, GitHub Actions

## Overview

This repository contains the architecture, infrastructure-as-code (IaC), and
deployment pipelines for an event-driven, 8-service microservices application.
Developed as a project for my MSc in Advanced Computer Science (Grade: A), this
project demonstrates a modern, automated, and secure cloud-native deployment
lifecycle.

## Core Architecture & Infrastructure

Rather than deploying monolithic applications manually, this system was designed
for high availability, isolated scalability, and zero-downtime deployments:

* **Backend Microservices:** concurrent services written in **Go** using the Gin
  framework, communicating synchronously via **AWS Service Connect** and
  asynchronously via **AWS SQS** event queues.

* **Database Layer:** A polyglot persistence strategy utilising **PostgreSQL
  (RDS)** for structured transactional data and **DynamoDB** (with TTL
  constraints) for high-throughput, unstructured logging.

* **Network Security:** A dual-subnet VPC architecture provisioned via
  **Terraform** (`cidrsubnet` dynamic allocation), ensuring microservices remain
  entirely isolated in private subnets with NAT Gateway egress.

* **Container Orchestration:** Fully serverless deployment using **AWS ECS
  Fargate** and **ECR** for immutable container images.

## Advanced CI/CD & DevOps Automation

The deployment pipeline is fully automated via **GitHub Actions**, prioritising
security and uptime:

* **Secretless CI/CD:** Utilised **OIDC (OpenID Connect)** to securely assume
  AWS IAM roles without storing long-lived AWS credentials in GitHub Secrets.

* **Optimised Build Matrix:** Implemented matrix strategies to build and deploy
  8 microservices in parallel, reducing deployment time by 70%.

* **Zero-Downtime Deployment:** Engineered a **Blue-Green deployment strategy**
  utilising dynamic Terraform state slot-switching. 

* **Safe Migrations:** Managed database state across Blue-Green boundaries
  utilising the **Expand-Contract** schema migration pattern to ensure backward
  compatibility and zero data inconsistency during live switchovers.

* **Automated Quality Gates:** The pipeline enforces unit tests (`pytest`), UI
  testing (`Playwright`), and headless load testing (`Locust`) before any idle
  slot is promoted to production.

