# Gateway-VPC-Endpoint
Reduce Cost and Increase Security with Amazon VPC Endpoints

## Gateway VPC Endpoint
Endpoints are virtual devices that are horizontally scaled, redundant, and highly available VPC components. VPC endpoints allow communication between instances in your VPC and services, without imposing availability risks or bandwidth constraints on your network traffic.

You can optimize the network path by avoiding traffic to internet gateways  and incurring cost associated with NAT gateways, NAT instances or maintaining firewalls. VPC endpoints also provide you with much finer control over how users and applications access AWS services.

I have used Gateway endpoint in this project to provide access to s3 to both instances in public and private subnet.

The Endpoint allows you to associate with the route tables in each of the subnets.

# Infrastructure
I have created the infrastructure from scratch using the following:

- VPC 
    - A private VPC with six subnets in 3 availability zones. Three public and three private subnets.

- Security Group
    - A security group which allows ssh traffic to instances in the public subnets from the internet

- Gateway VPC Endpoint
    - Allows you to provide access to Amazon Simple Storage Service (S3)

- S3 Bucket
    - The bucket which will be accessed by the instances within the vpc through the endpoint instead of traversing the internet. The s3 bucket has a policy to only accept traffic from the Endpoing therefore it won't allow from the console.
