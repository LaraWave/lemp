# LEMP Stack Configuration Template

This repository contains a Dockerized LEMP stack configuration template for deploying dynamic websites and web applications. The LEMP stack consists of Linux, Nginx, MySQL/MariaDB, and PHP, and is known for its high performance and scalability. The configuration template includes best practices for security, performance tuning, and customization, and can be easily adapted for various use cases and environments.

## Requirements

- Docker Engine
- Docker Compose

## Getting Started

1. Clone this repository to your local machine:
``` git clone https://github.com/larawave/lemp.git ```

2. Start the LEMP stack using Docker Compose:
``` docker-compose up -d ```

3. Verify that the containers are running:
``` docker-compose ps ```

4. Create a file ``` index.php ``` in the folder you have just mounted from the container to host.
``` 
<?php 
    phpinfo(); 
?> 
```

5. open the URL http://localhost in your web browser to see the PHP information page.

## Configuration

The configuration files for each component of the LEMP stack are located in the config directory. You can modify these files to customize the stack for your specific use case.

## Security
This configuration template includes best practices for securing the LEMP stack, such as disabling root login, using non-default ports, and enabling firewall rules. However, it is recommended that you review and modify the security settings to meet the specific requirements of your application and environment.

## Performance
This configuration template includes performance tuning settings for Nginx, PHP-FPM, and MySQL/MariaDB to optimize the stack for high traffic loads and complex data processing tasks. However, it is recommended that you review and modify the performance settings to meet the specific requirements of your application and environment.

## Troubleshooting
If you experience any issues with the LEMP stack, you can check the logs of each container using the docker-compose logs command. You can also refer to the documentation of each component for specific troubleshooting steps.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
