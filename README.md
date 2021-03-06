# TP Arquitectura del Software - Parte 2

En este caso, nuestro servicio será una app hecha en Node que consumirá otro servicio (supuestamente externo, no bajo nuestro control), hecho en Python. Nuestra aplicación tiene un endpoint que hace un passthrough al servicio externo.

Creando una sola instancia de la app en Node, deben encontrar el límite de ese endpoint, y mostrar cuál es el cuello de botella (los recursos de nuestro servicio, el servicio externo, el ancho de banda, o alguna otra cosa). Luego, escalen horizontalmente la app de Node y busquen el nuevo límite.

Repetir la experiencia introduciendo cache con Redis.

Tanto para escalar horizontalmente como para agregar una instancia de Redis, cada grupo deberá modificar/agregar archivos de terraform como sea necesario. En cualquier caso, y considerar los [límites del free tier](https://aws.amazon.com/free/?awsf.Free%20Tier%20Types=*default) para elegir qué tipo de instancia usar y la cantidad.
- Para escalar en un autoscaling group, buscar lo que son los parámetros "max size", "min size" y "desired size" y ajustarlo a lo deseado.
- Para crear una instancia de Redis en ElastiCache (servicio de AWS para ello), mirar el [recurso aws_elasticache_replication_group de Terraform](https://www.terraform.io/docs/providers/aws/r/elasticache_replication_group.html).


## Setup
### AWS
- Con el [pack estudiantil de GitHub](https://education.github.com/pack), crear una cuenta estudiantil en [AWS](https://aws.amazon.com/).
- Entrar en IAM y crear un usuario "Terraform" con el grupo de permisos necesarios (AmazonEC2FullAccess, AmazonElastiCacheFullAccess).
    - Desde IAM, generar un par de credenciales (key/secret) para ese usuario.
- (sugerido) Para facilitar el deployment, la propuesta es que creen un bucket en S3 en donde suban un zip con el código del servicio (`app.js`, `config.js`, `package.json` y `package-lock.json`), y luego cada instancia se encargará de bajarlo, descomprimirlo y ejecutarlo. Para esto entonces:
    - Ir a S3 y crear un bucket. Por simplicidad, recomiendo que el bucket acepte lecturas de cualquiera, pero no escrituras. Pueden habilitar el versionado de los objetos en el bucket si quieren, pero no es importante.
    - Para que sea read-only, pueden marcarlo como "público" al bucket y luego agregar la siguiente configuración como "Bucket Policy"
        ```json
        {
            "Version": "2008-10-17",
            "Statement": [
                {
                    "Sid": "AllowPublicRead",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "*"
                    },
                    "Action": "s3:GetObject",
                    "Resource": "arn:aws:s3:::tp-arqui-node-app-src/*"
                }
            ]
        }
        ```
    > Si optan por otra estrategia de deployment, recuerden cambiar el script `node_user_data.sh` para que no busque el código en S3, y pueden actualizar los scripts que están bajo la carpeta `node/` para que hagan lo que les venga bien (en particular, el script `node/update` que actualiza el código en una instancia). Consideren que las instancias dentro de un Autoscaling Group se pueden crear en cualquier momento, y eso está bajo el control de AWS, no de terraform.

### Datadog
- Crear una cuenta con el [pack estudiantil de GitHub](https://education.github.com/pack) en [Datadog](https://www.datadoghq.com/)
- Ir a `Integrations > APIs` y obtener la API KEY.

### Terraform
- Instalar Terraform, descargable desde [terraform.io](https://www.terraform.io/)
- Crear dentro de este repository un archivo `terraform.tfvars` con los siguientes campos, reemplazando los valores por los obtenidos en las etapas anteriores de AWS y Datadog:
    ```properties
    access_key = "<AWS_ACCESS_KEY>"

    secret_key = "<AWS_SECRET>"

    datadog_key = "<DATADOG_API_KEY>"
    ```
    > _**ATENCIÓN: NUNCA COMMITEAR ESTE ARCHIVO CON LAS CLAVES AL REPOSITORIO. SI LLEGARAN A PUBLICARLO POR ERROR, DEBEN INMEDIATAMENTE ENTRAR A AWS, Y DESDE IAM INVALIDAR EL PAR KEY-SECRET QUE TENÍAN Y GENERAR UNO NUEVO. RECOMIENDO HACER LO MISMO CON LA API KEY DE DATADOG.**_
- Revisar el archivo `variables.tf` y actualizar los valores default de las variables que corresponda. Este archivo sí será commiteado, así que solo poner aquí valores default que puedan exponerse (para los demás, deben estar la variable definida aquí pero el valor debe estar en `terraform.tfvars`, que nunca hay que commitearlo).
- Ejecutar `terraform init`. Esto inicializa la configuración que requiere terraform, e instala los providers necesarios.

## Crear y borrar infraestructura
- Para crear la infraestructura, ejecutar `terraform apply`, inspeccionar el plan para ver que sea correcto, y luego aceptarlo/rechazarlo.
- Para borrarla, ejecutar `terraform destroy`, inspeccionar el plan, y aprobarlo/rechazarlo.

Terraform crea un archivo local llamado `terraform.tfstate` que tiene el resultado de la aplicación del plan. Usa ese archivo luego para detectar diferencias y definir un plan. Ojo que ese archivo no debe perderse, pero como [puede contener información sensible en texto plano](https://www.terraform.io/docs/state/sensitive-data.html) no es recomendable commitearlo sin tomar algunas precauciones. Además, si se destruye y regenera la infraestructura, cambiará mucho, con lo que es muy propenso a conflictos en git.
>La recomendación por lo tanto es que cada cual tenga su propia cuenta de AWS y de Datadog, y mantenga su propio `terraform.tfstate` en su computadora sin necesidad de compartirlo. [Acá](https://www.terraform.io/docs/state/remote.html) tienen más información e instrucciones sobre qué hacer si quieren operar todos los integrantes del grupo sobre una misma cuenta de AWS y compartir su tfstate.


## Cheatsheet de terraform
```sh
# Ver lista de comandos
terraform help

# Ver ayuda de un comando específico, como por ejemplo qué parámetros/opciones acepta
terraform <COMMAND> --help

# Ver la versión de terraform instalada
terraform version

# Inicializar terraform en el directorio. Esto instala los providers e inicializa archivos de terraform
terraform init

# Ver el plan de ejecución pero sin realizar ninguna acción sobre la infraestructura (no lo aplica)
terraform plan

# Aplicar los cambios de infraestructura. Requiere aprobación manual, a menos que se especifique la opción `-auto-approve`
terraform apply

# Destruir toda la infraestructura. Requiere aprobación manual, a menos que se especifique la opción `-force`
terraform destroy

# Verifica que la sintaxis y la semántica de los archivos sea válida
terraform validate

# Lista los providers instalados. Para este tp, deben ser al menos "aws" y "template"
terraform providers
```
