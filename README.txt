# Entrega-1-Infraestructura-de-balanceo-de-carga.-Computacion-en-la-nube
Estructura del Proyecto
    1. Archivo principal de Terraform (main.tf)
    2. Variables de Terraform (variables.tf)
    3. Outputs de Terraform (outputs.tf)
    4. Script bash para lanzar el proceso (deploy.sh)
    5. Archivo de configuración de Nginx para el balanceador (lb_nginx.conf)
    6. Script para configurar los workers (configure_worker.sh)
    Entrega
    ├── configure_worker.sh
    ├── deploy.sh
    ├── lb_nginx.conf
    ├── main.tf
    ├── outputs.tf
    ├── README.txt
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    ├── tfplan
    ├── variables.tf
    └── worker_template.html

    1 directory, 11 files

Archivo ssh
La contraseña del archivo ssh del host es: entregaC0mpu
** Importante **
Si no hay una clave ssh creada crearla haciendo:
    ssh-keygen -t rsa -b 4096
Luego indicar en el archivo de variables el nombre de usuario y ubicación del archivo. Las variables a cambiar son "ssh_public_key_path" y "ssh_username".

Bibliografia
He utilizado el siguiente chat en perplexity para el entregable:
https://www.perplexity.ai/search/el-objetivo-de-este-proyecto-e-f5Bmg3yjQB2mjuZICDEqEA

Para poder repasar los pasos de terraform:
https://www.youtube.com/watch?v=5qaTeexPzQ4&ab_channel=The_Sudo

Estructura de árbol del proyecto con tree:
