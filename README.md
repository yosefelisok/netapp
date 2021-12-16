The server will be deployed in AWS cloud. Terraform and AWS CLI were used as tools for the deployment.
1. A user was created in AWS GUI and access and secret keys were used for the script. For other things just CLI was used.
A relevant VPC with subnets is installed in the 1 stage of the script.
AWS instance type t3.xlarge was used  as corresponding to 4 CPUs and 16GB RAM conditions. SSH connection to the
server is allowed just for istance with IP 10.0.0.3. EBS volume 150 Gb is configured to be mounted to the instance.
2. Container digitalocean/flask-helloworld is installed and is working on port 5000 by default. 
Nginx container was installed and configured to work on port 80. Furthermore port forwarding from 80 to 5000 port was set up according
to the task.
Postgres DB container was installed and a persistent volume for the DB data was created according prescriptions of the manual.


 
