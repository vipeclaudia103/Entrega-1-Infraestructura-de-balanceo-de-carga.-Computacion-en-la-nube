Entrega-1-Infraestructura-de-balanceo-de-carga.-Computacion-en-la-nube

GitHub
    He creado un repositorio en GitHub del proyecto.
    https://github.com/vipeclaudia103/Entrega-1-Infraestructura-de-balanceo-de-carga.-Computacion-en-la-nube 
    Para que no se suban los archivos generados al iniciar terraform, he creado un archivo .gitignore con los archivos temporales.
Estructura del Proyecto
    Al realizar el proyecto lo más automatizadoposible se necesitan varios archivos, por eso los he dividido en carpetas. Para guardar la estructura del proyecto graficamente, he utilizado la libreria tree. Con el siguiente comando desde el directorio raíz, en mi caso Entregable:
        tree -a -I 'node_modules|.git' --charset utf-8 > estructura.txt
    
    Un breve esquema de la estructura y descripción de cada carpeta y archivo:
        Entrega
    ├── deploy.sh: Script principal de despliegue.
    ├── estructura.txt: Guarda la estructura del proyecto.
    ├── README.md: Documentación del proyecto (cambiado de .txt a .md para mejor formato en GitHub).
    ├── .gitignore: Para ignorar archivos locales y sensibles creador por terraform.
    ├── scripts/: Contiene los scripts de configuración.
    │   ├── configure_worker.sh: Script en bash que configura los workers para el entorno de trabajo.
    │   └── setup_lb.sh:Script en bash que configura la mv del balanceador de carga (lb).
    ├── templates/: Contiene las plantillas para Nginx y los workers.
    │   ├── lb_nginx.conf: Archivo de configuración para Nginx que define las reglas de balanceo de carga.
    │   └── worker_template.html: Plantilla HTML utilizada para configurar y personalizar los workers.
    └── terraform/: Contiene los archivos principales de Terraform.
        ├── main.tf: Archivo principal de configuración de Terraform donde se define la infraestructura.
        ├── outputs.tf: Archivo de Terraform que especifica las salidas (outputs) de la infraestructura configurada.
        └── variables.tf: Archivo de Terraform que define las variables para personalizar la infraestructura.

Clave ssh
    La contraseña del archivo ssh del host es: entregaC0mpu
    ** Importante **
    Si no hay una clave ssh creada crearla haciendo:
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/clave
    Luego, darle permisos:
        chmod 600 ~/.ssh/clave
        chmod 644 ~/.ssh/clave.pub

    Luego indicar en el archivo de variables el nombre de usuario y ubicación del archivo. Las variables a cambiar son "ssh_public_key_path" y "ssh_username".

Bibliografia
He utilizado el siguiente chat en perplexity para el entregable:
https://www.perplexity.ai/search/el-objetivo-de-este-proyecto-e-f5Bmg3yjQB2mjuZICDEqEA

Para poder repasar los pasos de terraform:
https://www.youtube.com/watch?v=5qaTeexPzQ4&ab_channel=The_Sudo

Estructura de árbol del proyecto con tree:
