# Andromeda-Deployments

**Descripción**  
Andromeda-Deployments es un script diseñado para automatizar el despliegue de entornos virtualizados en Proxmox VE 8.2.2, con un enfoque en la educación. Facilita la creación y configuración de contenedores LXC y máquinas virtuales de manera eficiente.

## ⚙️ Funcionalidades Principales

- **Soporte para LXC y VMs:**  
  Los usuarios pueden elegir entre desplegar contenedores LXC o máquinas virtuales.

- **Selección de Sistemas Operativos:**  
  Imágenes preconfiguradas para Ubuntu 22.04, Debian 12, Fedora 38, o carga de una ISO personalizada.

- **Opciones de Personalización:**  
  Configuración de recursos como CPU, RAM y disco. Se ofrece la instalación de software como LAMP, LEMP, MariaDB o PostgreSQL.

- **Automatización con Cloud-Init:**  
  Las máquinas virtuales se configuran automáticamente con Cloud-Init, que incluye la creación de usuarios, red y scripts de instalación.

- **Validación de Servicios:**  
  Verificación automática de que los servicios instalados (bases de datos, servidores web) estén funcionando correctamente tras el despliegue.

## 🚨 Requisitos

- Proxmox VE 8.2.2
- Acceso root en el servidor
- Conexión a internet para la descarga de imágenes o ISOs

## 🛠️ Uso

1. Ejecutar el script con permisos de root.
2. Seguir las indicaciones en el menú interactivo (`dialog`) para seleccionar el tipo de entorno (LXC o VM), sistema operativo, recursos de hardware y software.
3. El sistema descargará las imágenes, configurará el entorno y desplegará los servicios seleccionados.

## 🔔 Mensajes Informativos

El script provee retroalimentación continua mediante:

- `msg_ok`: ✅ Indica que una acción fue completada con éxito.
- `msg_info`: ℹ️ Muestra información sobre el progreso de las operaciones.
- `msg_error`: ❌ Alerta de errores que requieren intervención del usuario.

Estos mensajes ayudan al usuario a entender el estado de la ejecución en todo momento.

## 📄 Licencia

## 🤓 Tips para Proxmox VE.

> ⚠️ **Tip 1**: Para acceder a una VM, puedes dar clic derecho en tu máquina virtual, lo que desplegará un menú con varias opciones útiles.
![Por ejemplo:](https://i.imgur.com/J3x3K3D.png)

Este proyecto se distribuye bajo la licencia MIT.
