Entrega-1-Infraestructura-de-balanceo-de-carga.-Computacion-en-la-nube

GitHub
    He creado un repositorio en GitHub del proyecto.
    https://github.com/vipeclaudia103/Entrega-1-Infraestructura-de-balanceo-de-carga.-Computacion-en-la-nube 
    Para que no se suban los archivos generados al iniciar terraform, he creado un archivo .gitignore con los archivos temporales.
Estructura del Proyecto
    Al realizar el proyecto lo más automatizadoposible se necesitan varios archivos, por eso los he dividido en carpetas. Para guardar la estructura del proyecto graficamente, he utilizado la libreria tree. Con el siguiente comando desde el directorio raíz, en mi caso Entregable:
        tree -a -I 'node_modules|.terraform|.git|terraform.*|tfplan|.terraform.*' --charset utf-8 > estructura_proyecto.txt
    
    Un breve esquema de la estructura y descripción de cada carpeta y archivo:
.
    ├── deploy.sh: Script principal de despliegue y destrucción.
    ├── estructura.txt: Guarda la estructura del proyecto.
    ├── README.txt: Documentación del proyecto (cambiado de .txt a .md para mejor formato en GitHub).
    ├── .gitignore: Para ignorar archivos locales y sensibles creador por terraform.
    ├── scripts: Contiene los scripts de configuración para el balanceador y los workers. Copiar en un archivo bash de la maquina cuando no funciona custom_data.
    │   ├── configure_worker.sh: Script en bash que configura los workers para el entorno de trabajo.
    │   └── configure_lb.sh:Script en bash que configura la mv del balanceador de carga (lb).
    └── terraform/: Contiene los archivos principales de Terraform.
        ├── main.tf: Archivo principal de configuración de Terraform donde se define la infraestructura.
        ├── outputs.tf: Archivo de Terraform que especifica las salidas (outputs) de la infraestructura configurada.
        ├── variables.tf: Archivo de Terraform que define las variables para personalizar la infraestructura.
        ├── conexion_ssh_lb.sh: Script bash para conectarse al balanceaddor por ssh.
        ├── conexion_ssh_worker.sh: Script bash para conectarse al balanceaddor por ssh luego al worker deseado.
        └── test_workers.sh: Script bash para ejecutar las pruebas de conexión por IP y por DNS

    Al final la configuración de los workers y el balanceador la hago a mano. Me conecto con los archivos conexion_ssh_lb y conexion_ssh_worker. Creo un archivo bash en la raín donde pego el contenido de configure_lb y configure_worker respectivamente. Doy permisos al nuevo archivo y lo ejecuto.
    Una vez ya se han cambiado todas las maquinas hay que hacer terraform refresh y volver a lanzar el archivo test_workers

    Con el archivo deploy tambien se puede destruir la infraestructura.
Explicación de los pasos seguidos
    1. Investigar y organizar proyecto.
    2. Crear main.tf con terraform y providers.
    3. Crear estructura de archivos.
    4. Crear sh que lance el proyecto o lo destruya.
    5. Comprobar nginx instalado conectando por ssh.
        a. En el balanceador de carga con el archivo conexion_ssh_lb.sh.
        a. En los workers con el archivo conexion_ssh_workers.sh.
Comprobar nginx instalado
    Verificar el estado del servicio Nginx:
    text
    sudo systemctl status nginx

    Esto mostrará si Nginx está activo y en ejecución.
    Comprobar la sintaxis de la configuración de Nginx:
    text
    sudo nginx -t
Clave ssh
    Pregunto la clave que se quiere utilizar al lanzar el deploy.
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
tree -a -I 'node_modules|.terraform|.git' --charset utf-8 > estructura_proyecto.txt
