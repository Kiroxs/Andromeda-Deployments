# Andromeda-Deployments

## 📚 Tabla de Contenidos

- [📝 Descripción](#-descripción)
- [⚙️ Funcionalidades Principales](#️-funcionalidades-principales)
- [🚨 Requisitos](#-requisitos)
- [🛠️ Instalación](#️-instalación)
- [🚀 Uso](#-uso)
- [📋 Opciones Disponibles](#-opciones-disponibles)
  - [Tipos de Entorno](#tipos-de-entorno)
  - [Sistemas Operativos Soportados](#sistemas-operativos-soportados)
  - [Paquetes de Software Disponibles](#paquetes-de-software-disponibles)
  - [Configuraciones de Hardware](#configuraciones-de-hardware)
  - [Tamaños de Disco](#tamaños-de-disco)
- [🔔 Mensajes Informativos](#-mensajes-informativos)
- [🤓 Tips para Proxmox VE](#-tips-para-proxmox-ve)
- [🌐 Recursos Adicionales](#-recursos-adicionales)

---

## 📝 Descripción

Andromeda-Deployments es un script diseñado para automatizar el despliegue de entornos virtualizados en **Proxmox VE 8.2.2**, con un enfoque en la educación y la facilidad de uso. Facilita la creación y configuración de **contenedores LXC** y **máquinas virtuales** de manera eficiente, permitiendo a los usuarios centrarse en aprender y desarrollar sin preocuparse por las complejidades de la configuración inicial.

---

## ⚙️ Funcionalidades Principales

- **Soporte para LXC y VMs:** Los usuarios pueden elegir entre desplegar contenedores LXC o máquinas virtuales, adaptándose a diferentes necesidades y casos de uso.

- **Selección de Sistemas Operativos:** Imágenes preconfiguradas para Ubuntu 22.04, Debian 12, Fedora 38, o la opción de cargar una ISO personalizada para mayor flexibilidad.

- **Opciones de Personalización:** Configuración de recursos como CPU, RAM y disco. Se ofrece la instalación de software como LAMP, LEMP, MariaDB, PostgreSQL, Docker y MongoDB en Docker.

- **Automatización con Cloud-Init:** Las máquinas virtuales se configuran automáticamente con Cloud-Init, incluyendo la creación de usuarios, configuración de red y ejecución de scripts de instalación personalizados.

- **Validación de Servicios:** Verificación automática de que los servicios instalados (bases de datos, servidores web) estén funcionando correctamente tras el despliegue.

---

## 🚨 Requisitos

- **Proxmox VE 8.2.2** (o versión compatible)
- **Acceso root** en el servidor
- **Conexión a Internet** para la descarga de imágenes o ISOs
- **Dependencias**:
  - `dialog`
  - `wget`, `curl`, `pvesh`, `qm`, `pct` (comandos estándar en Proxmox VE)

---

## 🛠️ Instalación

1. **Clonar el repositorio**:

   ```bash
   git clone https://github.com/Kiroxs/Andromeda-Deployments.git
   ```
   
2. **Clonar el repositorio**:
   ```bash
   cd Andromeda-Deployments
   ```
   
3. **Dar permisos de ejecución al script**:
   ```bash
   chmod +x AndromedaDeployments.sh
   ```

4. **(Opcional) Instalar dependencias necesarias**:
   ```bash
   apt-get update && apt-get install -y dialog
   ```

## 🚀 Uso

1. **Ejecutar el script con permisos de root**:
   ```bash
   sudo ./AndromedaDeployments.sh
   ```

2. **Seguir las indicaciones en el menú interactivo (`dialog`) para seleccionar el tipo de entorno (LXC o VM), sistema operativo, recursos de hardware y software**.

## 📋 Opciones Disponibles

**Tipos de Entorno**:

- Contenedor LXC.

- Máquina Virtual (VM).

**Sistemas Operativos Soportados**:
Para LXC:
  - Ubuntu 22.04.
  - Debian 12.
  - Fedora 38.

Para VM:
  - Ubuntu 22.04.
  - Fedora Cloud 41.
  - Debian 12.
  - ISO Personalizada: Proporciona una URL para una ISO personalizada.
    
**Paquetes de Software Disponibles**:
  - MariaDB.
  - PostgreSQL.
  - Docker.
  - MongoDB en Docker.
  - LAMP (Linux, Apache, MariaDB/MySQL, PHP).
  - LEMP (Linux, Nginx, MariaDB/MySQL, PHP.

**Configuraciones de Hardware**:

-*Minimalista*: 1 núcleo, 2 GB de RAM.

-*Media*: 3 núcleos, 4 GB de RAM.

-*Avanzada*: 4 núcleos, 8 GB de RAM.

**Tamaños de Disco**:

-*Predeterminado*: 15 GB.

-*Personalizado*: Especifica entre 15 GB y 80 GB.

## 🔔 Mensajes Informativos

El script provee retroalimentación continua mediante:

- `msg_ok`: ✅ Indica que una acción fue completada con éxito.
- `msg_info`: ℹ️ Muestra información sobre el progreso de las operaciones.
- `msg_error`: ❌ Alerta de errores que requieren intervención del usuario.
- `msg_warning`: ⚠️ Muestra advertencias sobre posibles problemas que no requieren una intervención inmediata, pero que deben ser considerados.

Estos mensajes ayudan al usuario a entender el estado de la ejecución en todo momento.


## 🤓 Tips para Proxmox VE.

> 💡 **Tip 1**: Para acceder a una VM, puedes dar clic derecho en tu máquina virtual o contenedor LXC, lo que desplegará un menú con varias opciones útiles.
>
> **Por Ejemplo**:
>
>![menú](https://i.imgur.com/J3x3K3D.png)

>💡 **Tip 2**: Como se muestra en la imagen anterior, el menú incluye opciones para iniciar, apagar, parar y reiniciar máquinas virtuales o contenedores. Es recomendable
utilizar la opción de "parar" en lugar de "apagar" para evitar posibles conflictos con procesos en segundo plano y asegurar un cierre más controlado del entorno.

>💡 **Tip 3**: Para eliminar una máquina virtual o un contenedor LXC, primero debes asegurarte que el entorno no está encendido, luego seleccionas el entorno en el panel lateral (click izquierdo) y en el panel superior eliges la opción **Más** y dentro del menú de la misma opción seleccionas eliminar. Es importante purgar de las configuraciones de trabajo y destruir discos sin referencias que le pertenecen al Guest para evitar problemas asociados a configuraciones de entornos que ya no existen.
Este proyecto se distribuye bajo la licencia MIT.
>
> **Por Ejemplo**:
> 
>![eliminación1](https://i.imgur.com/CgduPLU.png)
>![eliminación2](https://i.imgur.com/H7zuhux.png)


## 🌐 Recursos Adicionales

- **Documentación de Proxmox VE**: [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- **Documentación de LXC**: [Linux Containers](https://linuxcontainers.org/lxc/documentation/)
- **Documentación de Cloud-Init**: [Cloud-Init](https://cloud-init.io/)
