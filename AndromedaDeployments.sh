#!/bin/bash

# Funciones para mostrar mensajes
msg_info() {
    echo -e "\033[1;34mINFO: $1\033[0m"
}

msg_ok() {
    echo -e "\033[1;32mOK: $1\033[0m"
}

msg_error() {
    echo -e "\033[1;31mERROR: $1\033[0m"
}

msg_warning() {
    echo -e "\033[1;33mNOTA: $1\033[0m"
}

msg_cancel() {
    echo -e "\033[0;31mCANCELADO: $1\033[0m"
}

# Verificar si el script se está ejecutando como root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        msg_error "Este script debe ejecutarse como root"
        exit 1
    fi
}


# Verificar si Proxmox VE está instalado
pve_check() {
    if ! command -v pveversion &> /dev/null; then
        msg_error "Proxmox VE no está instalado"
        exit 1
    fi
}

# Verificar si dialog está instalado
dialog_check (){
    if ! command -v dialog &> /dev/null; then
        msg_error "Dialog no está instalado"
        exit 1
    fi
}

# Función para mostrar la bienvenida y explicación del proyecto
show_welcome() {
    dialog --title "Andromeda Deployments" --msgbox "Andromeda Deployments te ofrece una manera sencilla y automatizada de crear y configurar contenedores LXC y máquinas virtuales en Proxmox. A través de este proceso, podrás seleccionar el sistema operativo, instalar software específico, ajustar los recursos de hardware y definir credenciales personalizadas para tus instancias,de manera interactiva." 15 60

    clear
}

# Función para seleccionar el tipo de instancia
select_type() {
TYPE=$(dialog --clear --title "Seleccionar Tipo" \
    --menu "¿Deseas crear un Contenedor LXC o una Máquina Virtual?" 15 60 2 \
    "1" "Contenedor LXC" \
    "2" "Máquina Virtual" \
    2>&1 >/dev/tty)
if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
clear
}

# Función para seleccionar el sistema operativo
select_os_image_lxc() {
    OS_IMAGE=$(dialog --clear --title "Seleccionar Sistema Operativo" \
        --menu "Selecciona la imagen de sistema operativo que deseas usar:" 15 60 3 \
        "1" "Ubuntu 22.04" \
        "2" "Debian 12" \
        "3" "Fedora 38" \
        2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
    fi
    clear

    CACHE_DIRECTORY="/var/lib/vz/template/cache"

    case $OS_IMAGE in
        1)
        OS_IMAGE="Ubuntu"
        DISKIMAGE="$CACHE_DIRECTORY/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

        # Verificar si la imagen existe, si no, descargarla
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "La imagen de Ubuntu 22.04 no existe, descargando..."
            wget -O "$DISKIMAGE" "http://download.proxmox.com/images/system/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la imagen de Ubuntu."
                exit 1
            fi
            msg_ok "Imagen de Ubuntu 22.04 descargada exitosamente."
        fi
        ;;
        2)
        OS_IMAGE="Debian"
        DISKIMAGE="$CACHE_DIRECTORY/debian-12-standard_12.2-1_amd64.tar.zst"

        # Verificar si la imagen existe, si no, descargarla
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "La imagen de Debian 12 no existe, descargando..."
            wget -O "$DISKIMAGE" "http://download.proxmox.com/images/system/debian-12-standard_12.2-1_amd64.tar.zst"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la imagen de Debian."
                exit 1
            fi
            msg_ok "Imagen de Debian 12 descargada exitosamente."
        fi
        ;;
        3)
        OS_IMAGE="Fedora"
        DISKIMAGE="$CACHE_DIRECTORY/fedora-38-default_20230607_amd64.tar.xz"

        # Verificar si la imagen existe, si no, descargarla
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "La imagen de Fedora 38 no existe, descargando..."
            wget -O "$DISKIMAGE" "http://download.proxmox.com/images/system/fedora-38-default_20230607_amd64.tar.xz"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la imagen de Fedora."
                exit 1
            fi
            msg_ok "Imagen de Fedora 38 descargada exitosamente."
        fi
        ;;
        *)
        msg_error "Selección de imagen no válida"
        exit 1
        ;;
    esac
}

# Función para seleccionar el sistema operativo
select_os_image_vm() {
    OS_IMAGE=$(dialog --clear --title "Seleccionar Sistema Operativo" \
        --menu "Selecciona la imagen del sistema operativo que deseas usar:" 15 60 4 \
        "1" "Ubuntu 22.04 (Jammy)" \
        "2" "Fedora Cloud 41" \
        "3" "Debian 12" \
        "4" "Cargar tu propia ISO" \
        2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
    fi
    clear

    ISO_DIRECTORY="/var/lib/vz/template/iso"

    case $OS_IMAGE in
        1)
        OS_IMAGE="Ubuntu 22.04 (Jammy)"
        BASE_OS="Ubuntu"
        DISKIMAGE="$ISO_DIRECTORY/jammy-server-cloudimg-amd64.img"
        PKG_MANAGER="apt"
        LSB_RELEASE=$(lsb_release -cs)

        # Verificar si la imagen existe, si no, descargarla
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "La imagen de Ubuntu 22.04 no existe, descargando..."
            wget -O "$DISKIMAGE" "https://cloud-images.ubuntu.com/daily/server/jammy/current/jammy-server-cloudimg-amd64.img"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la imagen de Ubuntu."
                exit 1
            fi
            msg_ok "Imagen de Ubuntu 22.04 descargada exitosamente."
        fi
        ;;
        2)
        OS_IMAGE="Fedora Cloud 41"
        BASE_OS="Fedora"
        DISKIMAGE="$ISO_DIRECTORY/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
        PKG_MANAGER="dnf"

        # Verificar si la imagen existe, si no, descargarla
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "La imagen de Fedora Cloud 41 no existe, descargando..."
            wget -O "$DISKIMAGE" "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la imagen de Fedora."
                exit 1
            fi
            msg_ok "Imagen de Fedora Cloud 41 descargada exitosamente."
        fi
        ;;
        3)
        OS_IMAGE="Debian 12"
        BASE_OS="Debian"
        DISKIMAGE="$ISO_DIRECTORY/debian-12-genericcloud-amd64.qcow2"
        PKG_MANAGER="apt"
        LSB_RELEASE="bookworm"

        # Verificar si la imagen existe, si no, descargarla
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "La imagen de Debian 12 no existe, descargando..."
            wget -O "$DISKIMAGE" "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la imagen de Debian."
                exit 1
            fi
            msg_ok "Imagen de Debian 12 descargada exitosamente."
        fi
        ;;
        4)
        OS_IMAGE="Cargar tu propia ISO"
        # Pedir al usuario que ingrese la URL de la ISO, pero no descargar todavía
        ISO_URL=$(dialog --inputbox "Ingresa el enlace de descarga de tu ISO personalizada (ejemplo: https://enlace.iso):" 8 60 2>&1 >/dev/tty)
        if [ $? -ne 0 ]; then
            clear
            msg_cancel "Operación cancelada por el usuario."
            exit 1
        fi
        clear

        # Asignar la ruta de la imagen personalizada
        CUSTOM_ISO=$(basename "$ISO_URL")
        DISKIMAGE="$ISO_DIRECTORY/$CUSTOM_ISO"

        # Verificar si el archivo ya existe, si no, descargarlo
        if [ ! -f "$DISKIMAGE" ]; then
            msg_info "Descargando ISO personalizada desde $ISO_URL..."
            wget -O "$DISKIMAGE" "$ISO_URL"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la ISO personalizada."
                exit 1
            fi
            msg_ok "ISO personalizada descargada exitosamente en $DISKIMAGE."
        else
            msg_info "La ISO personalizada ya existe en $DISKIMAGE."
        fi
        ;;
        *)
        msg_error "Selección de imagen no válida"
        exit 1
        ;;
    esac
}






# Función para seleccionar software en LXC
select_software_lxc() {
    if [[ "$OS_IMAGE" == "Fedora" ]]; then
        SOFTWARE=$(dialog --clear --title "Seleccionar Paquete de Software para LXC" \
            --menu "Selecciona el paquete de software que deseas instalar en el contenedor LXC:" 15 60 3 \
            "1" "MariaDB" \
            "2" "PostgreSQL" \
            "3" "LEMP" \
            2>&1 >/dev/tty)
    else
        SOFTWARE=$(dialog --clear --title "Seleccionar Paquete de Software para LXC" \
            --menu "Selecciona el paquete de software que deseas instalar en el contenedor LXC:" 15 60 4 \
            "1" "MariaDB" \
            "2" "PostgreSQL" \
            "3" "LEMP" \
            "4" "LAMP" \
            2>&1 >/dev/tty)
    fi
    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
    clear

    case $SOFTWARE in
        1)
        SOFTWARE="MariaDB"
        ;;
        2)
        SOFTWARE="PostgreSQL"
        ;;
        3)
        SOFTWARE="LEMP"
        ;;
        4)
        SOFTWARE="LAMP"
        ;;
        *)
        msg_error "Selección no válida de software para LXC"
        exit 1
        ;;
    esac
}


# Función para seleccionar software en VM
select_software_vm() {
    SOFTWARE=$(dialog --clear --title "Seleccionar Paquete de Software para VM" \
        --menu "Selecciona el paquete de software que deseas instalar en la máquina virtual (VM):" 15 60 6 \
        "1" "MariaDB" \
        "2" "PostgreSQL" \
        "3" "Docker" \
        "4" "MongoDB en Docker" \
        "5" "LAMP" \
        "6" "LEMP" \
        2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
    clear

    case $SOFTWARE in
        1)
        SOFTWARE="MariaDB"
        ;;
        2)
        SOFTWARE="PostgreSQL"
        ;;
        3)
        SOFTWARE="Docker"
        ;;
        4)
        SOFTWARE="MongoDB_Docker"
        ;;
        5)
        SOFTWARE="LAMP"
        ;;
        6)
        SOFTWARE="LEMP"
        ;;
    *)
    msg_error "Selección no válida de software para vm"
    exit 1
    ;;
    esac
}


# Función para seleccionar hardware
select_hardware() {
    HARDWARE=$(dialog --clear --title "Seleccionar Configuración de Hardware" \
        --menu "Selecciona la configuración de hardware que deseas:" 15 60 3 \
        "1" "Minimalista: 1 core, 2 GB de RAM" \
        "2" "Media: 3 cores, 4 GB de RAM" \
        "3" "Avanzada: 4 cores, 8 GB de RAM" \
        2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
    clear

    case $HARDWARE in
        1)
        CORES=1
        MEMORY=2048
        ;;
        2)
        CORES=3
        MEMORY=4096
        ;;
        3)
        CORES=4
        MEMORY=8192
        ;;
        *)
        msg_error "Selección no válida"
        exit 1
        ;;
    esac
}

# Función para seleccionar la capacidad del disco
select_disk_size_LXC() {
    DISK_OPTION=$(dialog --clear --title "Seleccionar Capacidad de Disco" \
        --menu "El valor predeterminado de disco es 15 GB. Si deseas ampliarlo, selecciona una opción:" 15 60 3 \
        "1" "Usar valor por defecto: 15 GB" \
        "2" "Ampliar capacidad de disco" \
        2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
    clear

    case $DISK_OPTION in
        1)
        DISK_SIZE=15
        ;;
        2)
        DISK_SIZE=$(dialog --inputbox "Ingresa la capacidad de disco que deseas (debe ser mayor que 15 GB y hasta 80 GB):" 10 40 2>&1 >/dev/tty)
        
        # Validar que el valor sea un número entero mayor que 15 y menor o igual que 80
        if ! [[ "$DISK_SIZE" =~ ^[0-9]+$ ]] || [ "$DISK_SIZE" -le 15 ] || [ "$DISK_SIZE" -gt 80 ]; then
            clear
            msg_error "El valor ingresado no es válido. Se usará el valor predeterminado de 15 GB."
            DISK_SIZE=15
        fi
        ;;
        *)
        msg_error "Selección no válida de almacenamiento para lxc"
        exit 1
        ;;
esac
}

# Función para seleccionar la capacidad del disco
select_disk_size_VM() {
    DISK_OPTION=$(dialog --clear --title "Seleccionar Capacidad de Disco" \
        --menu "El valor predeterminado de disco es 15 GB. Si deseas ampliarlo, selecciona una opción:" 15 60 3 \
        "1" "Usar valor por defecto: 15 GB" \
        "2" "Ampliar capacidad de disco" \
        2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
    fi

    clear

    case $DISK_OPTION in
        1)
        DISK_SIZE=15G
        ;;
        2)
        DISK_SIZE=$(dialog --inputbox "Ingresa la capacidad de disco que deseas (ej: 20G o 20):" 10 40 2>&1 >/dev/tty)

        # Validar que la entrada no esté vacía
        if [ -z "$DISK_SIZE" ]; then
            clear
            msg_error "No se ingresó ninguna capacidad. Se usará el valor predeterminado de 15 GB."
            DISK_SIZE=15G
        fi

        # Validar que el valor ingresado sea un número dentro del rango permitido con o sin 'G'
        if [[ "$DISK_SIZE" =~ ^[0-9]+G$ ]]; then
            
            SIZE_NUMBER=${DISK_SIZE%G}  
            if [ "$SIZE_NUMBER" -le 15 ] || [ "$SIZE_NUMBER" -gt 80 ]; then
                clear
                msg_error "El valor ingresado está fuera del rango permitido. Se usará el valor predeterminado de 15 GB."
                DISK_SIZE=15G
            fi
        elif [[ "$DISK_SIZE" =~ ^[0-9]+$ ]]; then
           
            if [ "$DISK_SIZE" -le 15 ] || [ "$DISK_SIZE" -gt 80 ]; then
                clear
                msg_error "El valor ingresado está fuera del rango permitido. Se usará el valor predeterminado de 15 GB."
                DISK_SIZE=15G
            else
                DISK_SIZE="${DISK_SIZE}G"
            fi
        else
            clear
            msg_error "El valor ingresado no es válido. Se usará el valor predeterminado de 15 GB."
            DISK_SIZE=15G
        fi
        ;;
        *)
        msg_error "Selección no válida de almacenamiento para VM"
        exit 1
        ;;
    esac
}


# Función para ingresar usuario y contraseña
input_credentials() {
    USERNAME=$(dialog --inputbox "Ingrese el nombre de usuario para la máquina:" 8 40 2>&1 >/dev/tty)
    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi

    # Verificar que el nombre de usuario no esté vacío
    while [ -z "$USERNAME" ]; do
        USERNAME=$(dialog --inputbox "El nombre de usuario no puede estar vacío. Inténtelo de nuevo." 8 40 2>&1 >/dev/tty)
        if [ $? -ne 0 ]; then
            clear
            msg_cancel "Operación cancelada por el usuario."
            exit 1 
        fi
    done

    clear

    # Pedir contraseña
    PASSWORD=$(dialog --passwordbox "Ingrese la contraseña para el usuario $USERNAME:" 8 40 2>&1 >/dev/tty)
    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi

    # Verificar que la contraseña no esté vacía
    while [ -z "$PASSWORD" ]; do
        PASSWORD=$(dialog --passwordbox "La contraseña no puede estar vacía. Inténtelo de nuevo. $USERNAME:" 8 40 2>&1 >/dev/tty)
        if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
    done

    clear
}

# Configurar los valores predeterminados
default_settings() {
    VMID=$(pvesh get /cluster/nextid)
    TEMPLATE_NAME="vm$VMID"
    HOST_DISK="local-lvm"
}







# Función para modificar los mirrors de Debian a los de ftp.cl.debian.org
update_debian_mirrors() {
    local vmid=$1
    msg_info "Reconfigurando mirrors de Debian en LXC ID $vmid a ftp.cl.debian.org y deb.debian.org para seguridad"

    # Actualizar los mirrors de Debian a los de Chile para repositorios principales y deb.debian.org para seguridad
    pct exec $vmid -- bash -c "
        sed -i.bak 's|http://deb.debian.org/debian|http://ftp.cl.debian.org/debian|g' /etc/apt/sources.list &&
        sed -i 's|http://security.debian.org|http://deb.debian.org/debian-security|g' /etc/apt/sources.list &&
        apt-get update
    "

    # Verificar si la operación fue exitosa
    if [ $? -eq 0 ]; then
        msg_ok "Mirrors actualizados correctamente en LXC ID $vmid."
    else
        msg_error "Error al actualizar mirrors en LXC ID $vmid."
        exit 1
    fi
}




# Función para crear el contenedor LXC
create_container() {
    local vmid=$1
    local diskimage=$2
    local host_disk=$3
    local disk_size=$4
    local cores=$5
    local memory=$6

    msg_info "Creando Contenedor LXC ID $vmid con $cores cores, $memory MB de RAM y $disk_size GB de disco"
    pct create $vmid $diskimage --storage $host_disk --rootfs $host_disk:$disk_size --cores $cores --memory $memory --net0 name=eth0,bridge=vmbr0,ip=dhcp

    if [ $? -ne 0 ]; then
        clear
        msg_cancel "Operación cancelada por el usuario."
        exit 1
        
    fi
    msg_ok "Contenedor LXC ID $vmid creado con éxito"
}

# Crear la VM con las configuraciones especificadas
create_vm() {
  local vmid=$1
  local name=$2
  local diskimage=$3
  local host_disk=$4
  local disk_size=$5
  local cores=$6
  local memory=$7

  msg_info "Creando Máquina Virtual ID $vmid con $cores cores, $memory MB de RAM y $disk_size de disco"
  qm create $vmid --name $name --memory $memory --cores $cores --net0 virtio,bridge=vmbr0
  if [ $? -ne 0 ]; then
    msg_error "Error al crear la VM"
    exit 1
  fi
  msg_ok "Creada Máquina Virtual ID $vmid"

  msg_info "Importando imagen de disco a la VM $vmid"
  qm importdisk $vmid $diskimage $host_disk --format qcow2
  if [ $? -ne 0 ]; then
    msg_error "Error al importar la imagen de disco"
    exit 1
  fi
  msg_ok "Imagen de disco importada a la VM $vmid"

  msg_info "Configurando disco y hardware para la VM $vmid"
  qm set $vmid --scsihw virtio-scsi-pci --scsi0 $host_disk:vm-$vmid-disk-0
  qm set $vmid --boot c --bootdisk scsi0
  qm set $vmid --ide2 $host_disk:cloudinit
  qm set $vmid --serial0 socket --vga serial0
  qm set $vmid --agent enabled=1
  if [ $? -ne 0 ]; then
    msg_error "Error al configurar disco y hardware"
    exit 1
  fi
  msg_ok "Disco y hardware configurados para la VM $vmid"

  msg_info "Redimensionando disco a $disk_size para VM $vmid"
  qm resize $vmid scsi0 $disk_size
  if [ $? -ne 0 ]; then
    msg_error "Error al redimensionar el disco"
    exit 1
  fi
  msg_ok "Disco redimensionado a $disk_size para VM $vmid"
}






# Configurar Cloud-Init
configure_cloud_init() {
    local vmid=$1
    local user=$2
    local password=$3
    local hostname="vm$vmid"
    local cloud_init_dir="/var/lib/vz/snippets"
    local passwd_hash=$(openssl passwd -1 "$password")

    msg_info "Configurando Cloud-Init para VMID $vmid"

    # Crear directorio de configuración si no existe
    mkdir -p "$cloud_init_dir"

    # Crear contenido dinámico para el script de instalación
    case $SOFTWARE in
        "MariaDB")
            if [ "$PKG_MANAGER" == "apt" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo apt-get update
sudo apt-get install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
EOF
)
            elif [ "$PKG_MANAGER" == "dnf" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo dnf update -y
sudo systemctl disable systemd-binfmt.service
sudo dnf install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
EOF
)
            fi
            ;;
        "PostgreSQL")
            if [ "$PKG_MANAGER" == "apt" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql
EOF
)
            elif [ "$PKG_MANAGER" == "dnf" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo systemctl restart systemd-binfmt.service

sudo dnf update -y
sudo dnf install -y dnf-plugins-core
sudo dnf install -y postgresql-server postgresql-contrib
sudo /usr/bin/postgresql-setup --initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql
EOF
)
            fi
            ;;
        "Docker")
            if [ "$PKG_MANAGER" == "apt" ]; then
                # Configurar el repositorio de Docker según el sistema operativo definido en $OS_IMAGE
                if [ "$BASE_OS" == "Debian" ]; then
                    REPO_URL="https://download.docker.com/linux/debian"
                    DISTRO="bookworm"
                elif [ "$BASE_OS" == "Ubuntu" ]; then
                    REPO_URL="https://download.docker.com/linux/ubuntu"
                    DISTRO=$(lsb_release -cs)
                fi

                if [ -z "$REPO_URL" ]; then
                    msg_error "Este script solo soporta Debian y Ubuntu."
                    exit 1
                fi

                SOFTWARE_SCRIPT=$(cat <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL $REPO_URL/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $REPO_URL $DISTRO stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
EOF
)
            elif [ "$PKG_MANAGER" == "dnf" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash

sudo systemctl restart systemd-binfmt.service
sudo dnf update -y
sudo dnf install -y dnf-plugins-core
sudo tee /etc/yum.repos.d/docker.repo <<REPO_EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
REPO_EOF
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
EOF
)
            fi
            ;;
        "MongoDB_Docker")
            if [ "$PKG_MANAGER" == "apt" ]; then
                if [ "$BASE_OS" == "Debian" ]; then
                    REPO_URL="https://download.docker.com/linux/debian"
                    DISTRO="bookworm"
                elif [ "$BASE_OS" == "Ubuntu" ]; then
                    REPO_URL="https://download.docker.com/linux/ubuntu"
                    DISTRO=$(lsb_release -cs)
                fi

                if [ -z "$REPO_URL" ]; then
                    msg_error "Este script solo soporta Debian y Ubuntu."
                    exit 1
                fi

                SOFTWARE_SCRIPT=$(cat <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL $REPO_URL/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $REPO_URL $DISTRO stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo docker pull mongo:4.4
sudo docker run -d -p 27017:27017 --name mongodb -v ~/mongodb/data:/data/db mongo:4.4
EOF
)
            elif [ "$PKG_MANAGER" == "dnf" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo systemctl restart systemd-binfmt.service

sudo dnf update -y
sudo dnf install -y dnf-plugins-core
sudo tee /etc/yum.repos.d/docker.repo <<REPO_EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
REPO_EOF
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo docker pull mongo:4.4
sudo docker run -d -p 27017:27017 --name mongodb -v ~/mongodb/data:/data/db mongo:4.4
EOF
)
            fi
            ;;
        "LAMP")
            if [ "$PKG_MANAGER" == "apt" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2 mariadb-server mariadb-client php libapache2-mod-php php-mysql
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl restart apache2
EOF
)
            elif [ "$PKG_MANAGER" == "dnf" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo dnf update -y
sudo dnf install -y httpd mariadb-server php php-mysqlnd
sudo systemctl enable httpd mariadb
sudo systemctl start httpd mariadb
EOF
)
            fi
            ;;
        "LEMP")
            if [ "$PKG_MANAGER" == "apt" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx mariadb-server php-fpm php-mysql
sudo systemctl enable nginx mariadb
sudo systemctl start nginx mariadb
EOF
)
            elif [ "$PKG_MANAGER" == "dnf" ]; then
                SOFTWARE_SCRIPT=$(cat <<'EOF'
#!/bin/bash
sudo dnf update -y
sudo dnf install -y nginx mariadb-server php-fpm php-mysqlnd
sudo systemctl enable nginx mariadb
sudo systemctl start nginx mariadb
EOF
)
            fi
            ;;
    esac

    # Crear archivo user-data
    local user_data="${cloud_init_dir}/user-data-${vmid}.yaml"
    cat > "$user_data" <<EOF
#cloud-config
hostname: $hostname
manage_etc_hosts: true
users:
  - name: $user
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false
    passwd: $passwd_hash
write_files:
  - path: /home/$user/install.sh
    permissions: '0755'
    content: |
$(echo "$SOFTWARE_SCRIPT" | sed 's/^/      /')
  - path: /etc/netplan/01-netcfg.yaml
    permissions: '0600'
    content: |
      network:
        version: 2
        ethernets:
          enp0s18:
            dhcp4: true
  - path: /home/$user/generate_ssh_keys.sh
    permissions: '0700'
    content: |
      #!/bin/bash
      mkdir -p /home/$user/.ssh
      ssh-keygen -t rsa -b 2048 -f /home/$user/.ssh/id_rsa -q -N ""
      chown -R $user:$user /home/$user/.ssh
      echo "SSH keys generated successfully!"
runcmd:
  - netplan apply
  - [ bash, /home/$user/install.sh ]
  - [ bash, /home/$user/generate_ssh_keys.sh ]
EOF

    # Crear archivo meta-data
    local meta_data="${cloud_init_dir}/meta-data-${vmid}.yaml"
    cat > "$meta_data" <<EOF
instance-id: $hostname
local-hostname: $hostname
EOF

    # Asegurarse de que los archivos tengan los permisos correctos
    chmod 600 "$user_data" "$meta_data"

    # Asignar archivos Cloud-Init a la VM
    qm set "$vmid" --cicustom "user=local:snippets/user-data-${vmid}.yaml,meta=local:snippets/meta-data-${vmid}.yaml"
    if [ $? -ne 0 ]; then
        msg_error "Error al configurar Cloud-Init"
        exit 1
    fi

    msg_ok "Cloud-Init configurado para VMID $vmid con usuario $user y hostname $hostname."
    qm start $vmid
    wait_for_vm $vmid

}

# Función para esperar a que la VM esté en funcionamiento
wait_for_vm() {
    local vmid=$1
    local status

    msg_info "Esperando a que la VM ID $vmid esté en funcionamiento..."

    while true; do
        status=$(qm status $vmid | awk '{print $2}')
        if [ "$status" = "running" ]; then
            break
        elif [ "$status" = "stopped" ]; then
            msg_info "La VM $vmid está detenida. Intentando iniciarla..."
            qm start $vmid
        fi
        sleep 2  # Verificación cada 2 segundos
    done

    msg_ok "La VM ID $vmid está en funcionamiento."
    exit 1
}

# Función para verificar el estado del contenedor LXC
wait_for_container() {
    local vmid=$1
    local status

    msg_info "Esperando a que el contenedor LXC ID $vmid esté en funcionamiento..."

    while true; do
        status=$(pct status $vmid | awk '{print $2}')
        if [ "$status" = "running" ]; then
        break
        elif [ "$status" = "stopped" ];then
        msg_info "El contenedor $vmid está detenido. Intentando iniciarlo..."
        pct start $vmid
        fi
        sleep 2  # Verificación cada 2 segundos
    done

    msg_ok "El contenedor LXC ID $vmid está en funcionamiento."
}

# Función para crear el usuario y asignar la contraseña
create_user_in_container() {
    local vmid=$1
    local username=$2
    local password=$3

    msg_info "Creando el usuario $username en LXC ID $vmid ($OS_IMAGE)"

    # Instalar sudo y otros paquetes según el sistema operativo
    if [[ "$OS_IMAGE" == "Debian" || "$OS_IMAGE" == "Ubuntu" ]]; then
        pct exec $vmid -- bash -c "apt-get update && apt-get install -y sudo"
    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        pct exec $vmid -- bash -c "dnf install -y sudo"
    fi

    # Crear el usuario y asignar la contraseña
    if [[ "$OS_IMAGE" == "Debian" || "$OS_IMAGE" == "Ubuntu" ]]; then
        pct exec $vmid -- bash -c "adduser --disabled-password --gecos '' $username"
        pct exec $vmid -- bash -c "echo '$username:$password' | chpasswd"
    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        pct exec $vmid -- bash -c "useradd $username"
        pct exec $vmid -- bash -c "echo '$password' | passwd --stdin $username"
    fi

    # Añadir el usuario al grupo sudo
    pct exec $vmid -- bash -c "usermod -aG sudo $username"

    # Configurar sudo para que no pida contraseña para el usuario
    pct exec $vmid -- bash -c "echo '$username ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$username"
    pct exec $vmid -- bash -c "chmod 440 /etc/sudoers.d/$username"

    # Comandos adicionales específicos para Debian
    if [[ "$OS_IMAGE" == "Debian" ]]; then
        msg_info "Ejecutando comandos adicionales en Debian LXC ID $vmid"
        pct exec $vmid -- bash -c "cd /var/lib/dpkg/info/ && apt-get install --reinstall \$(grep -l 'setcap' * | sed -e 's/\\.[^.]*\$//g' | sort --unique)"
    fi

    msg_ok "Usuario $username creado correctamente en $OS_IMAGE LXC ID $vmid."
}



# Configurar locales en el contenedor LXC
configure_locales() {
    local vmid=$1

    if [[ "$OS_IMAGE" == "Ubuntu" ]]; then
        # Instalar locales si no están presentes
        pct exec $vmid -- bash -c "apt-get install -y locales locales-all"

        # Generar las locales necesarias
        pct exec $vmid -- bash -c "locale-gen en_US.UTF-8"

        # Configurar las locales para todo el sistema
        pct exec $vmid -- bash -c "update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"

        # Forzar que los cambios tengan efecto
        pct exec $vmid -- bash -c "echo 'LANG=en_US.UTF-8' > /etc/default/locale"
        pct exec $vmid -- bash -c "echo 'LC_ALL=en_US.UTF-8' >> /etc/default/locale"
        
        
    fi
    if [[ "$OS_IMAGE" == "Debian" ]]; then
    msg_info "Instalando y configurando locales en LXC ID $vmid (Debian)"
    
    # Realizar instalación y configuración de locales
    pct exec $vmid -- bash -c "
        apt-get install --reinstall -y locales locales-all &&
        echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen &&
        echo 'es_ES.UTF-8 UTF-8' >> /etc/locale.gen &&
        locale-gen &&
        echo 'LANG=en_US.UTF-8' > /etc/default/locale &&
        echo 'LC_ALL=en_US.UTF-8' >> /etc/default/locale &&
        DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive locales
    "

    # Verificar si la configuración fue exitosa
    if pct exec $vmid -- bash -c "locale" | grep -q "LANG=en_US.UTF-8"; then
        msg_ok "Locales configurados correctamente en LXC ID $vmid."
    else
        msg_error "Error al configurar los locales en LXC ID $vmid."
    fi
    fi

}




# Función para iniciar MariaDB manualmente en Debian
start_mariadb_debian() {
    local vmid=$1
    local username=$USERNAME 

    # Instalar MariaDB y realizar configuraciones iniciales
    if [[ "$OS_IMAGE" == "Debian" || "$OS_IMAGE" == "Ubuntu" ]]; then
        msg_info "Instalando y configurando MariaDB en LXC ID $vmid para $OS_IMAGE"
        
        pct exec $vmid -- bash -c "
            apt-get update &&
            apt-get install -y mariadb-server &&
            getent group mysql &>/dev/null || groupadd mysql &&
            id -u mysql &>/dev/null || useradd -r -g mysql -s /bin/false mysql &&
            chown -R mysql:mysql /var/lib/mysql &&
            mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld &&
            echo -e '#!/bin/bash\nnohup mysqld_safe --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock > /dev/null 2>&1 &' > /home/$username/start_mariadb.sh &&
            chmod +x /home/$username/start_mariadb.sh
        "
    fi

    # Ejecutar el script de inicio para MariaDB
    msg_info "Ejecutando script para iniciar MariaDB en el directorio de $username en LXC ID $vmid"
    pct exec $vmid -- bash -c "sudo /home/$username/start_mariadb.sh"

    # Verificar si el proceso de MariaDB está corriendo
    sleep 2  # Pausa breve para permitir el inicio
    if pct exec $vmid -- bash -c "pgrep mysqld > /dev/null"; then
        msg_ok "MariaDB iniciado correctamente en LXC ID $vmid ($OS_IMAGE)"
    else
        msg_error "Error al iniciar MariaDB en LXC ID $vmid ($OS_IMAGE)"
        exit 1
    fi
}



# Función para iniciar MariaDB en Ubuntu
start_mariadb_ubuntu() {
    local vmid=$1
    msg_info "Iniciando MariaDB en LXC ID $vmid (Ubuntu) utilizando /etc/init.d/mariadb"

    # Iniciar MariaDB utilizando /etc/init.d en Ubuntu
    pct exec $vmid -- bash -c "/etc/init.d/mariadb start"

    # Verificar si el proceso de MariaDB está corriendo
    if pct exec $vmid -- bash -c "ps aux | grep mysql | grep -v grep"; then
        msg_ok "MariaDB iniciado correctamente en LXC ID $vmid (Ubuntu)"
    else
        msg_error "Error al iniciar MariaDB en LXC ID $vmid (Ubuntu)"
        exit 1
    fi
}

# Función para iniciar MariaDB en Fedora
start_mariadb_fedora() {
    local vmid=$1
    msg_info "Iniciando MariaDB en LXC ID $vmid (Fedora) utilizando systemctl"

    # Iniciar MariaDB utilizando systemctl en Fedora
    pct exec $vmid -- bash -c "systemctl start mariadb"

    sleep 2  # Esperar 2 segundos para asegurarse de que el servicio se haya iniciado correctamente
    # Verificar si el proceso de MariaDB está corriendo
    if pct exec $vmid -- bash -c "systemctl is-active mariadb"; then
        msg_ok "MariaDB iniciado correctamente en LXC ID $vmid (Fedora)"
    else
        msg_error "Error al iniciar MariaDB en LXC ID $vmid (Fedora)"
        exit 1
    fi
}


# Función para iniciar MariaDB dependiendo del sistema operativo
start_mariadb() {
    local vmid=$1

    if [[ "$OS_IMAGE" == "Debian" ]]; then
        start_mariadb_debian "$vmid"
    elif [[ "$OS_IMAGE" == "Ubuntu" ]]; then
        start_mariadb_ubuntu "$vmid"
    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        start_mariadb_fedora "$vmid"
    else
        msg_error "Sistema operativo no soportado para iniciar MariaDB"
        exit 1
    fi
}

# Función para instalar MariaDB según el sistema operativo
install_mariadb() {
    msg_info "Instalando MariaDB en LXC ID $VMID para $OS_IMAGE"

    if [[ "$OS_IMAGE" == "Ubuntu" ]]; then
        pct exec $VMID -- bash -c "apt-get install -y mariadb-server mariadb-client"
    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        pct exec $VMID -- bash -c "dnf install -y mariadb mariadb-server"
        pct exec $VMID -- bash -c "systemctl enable mariadb"
        pct exec $VMID -- bash -c "systemctl start mariadb"
    fi

    start_mariadb "$VMID"


}

# Instalación de PostgreSQL según el sistema operativo
install_postgresql() {
    msg_info "Instalando PostgreSQL en LXC ID $VMID para $OS_IMAGE"

    if [[ "$OS_IMAGE" == "Ubuntu" ]]; then
        pct exec $VMID -- bash -c "apt-get install -y postgresql postgresql-contrib"
    elif [[ "$OS_IMAGE" == "Debian" ]]; then
        pct exec $VMID -- bash -c "apt-get install -y postgresql postgresql-client"
    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        pct exec $VMID -- bash -c "dnf install -y postgresql-server"
        pct exec $VMID -- bash -c "postgresql-setup --initdb"

            # Iniciar y habilitar PostgreSQL como root para asegurar permisos
        pct exec $VMID -- bash -c "sudo systemctl start postgresql && sudo systemctl enable postgresql"
    fi
}

# Función para iniciar Apache en Debian o Ubuntu
start_apache_debian() {
    local vmid=$1
    local username=$USERNAME  

    # Instalar Apache en Debian o Ubuntu
    if [[ "$OS_IMAGE" == "Debian" || "$OS_IMAGE" == "Ubuntu" ]]; then
        msg_info "LOG Instalando Apache en LXC ID $vmid para $OS_IMAGE"
        pct exec $vmid -- bash -c "apt-get install -y apache2"
    fi

    # Crear un script para iniciar Apache en el directorio del usuario
    msg_info "Creando script para iniciar Apache en el directorio de $username en LXC ID $vmid"
    pct exec $vmid -- bash -c "echo '#!/bin/bash' | tee /home/$username/start_apache.sh"

    pct exec $vmid -- bash -c "echo 'nohup apache2ctl start > /dev/null 2>&1 &' | tee -a /home/$username/start_apache.sh"

    # Hacer el script ejecutable
    pct exec $vmid -- bash -c "chmod +x /home/$username/start_apache.sh"

    # Ejecutar el script para iniciar Apache
    msg_info "Ejecutando script para iniciar Apache en el directorio de $username en LXC ID $vmid"
    pct exec $vmid -- bash -c "/home/$username/start_apache.sh"
    pct exec $vmid -- bash -c "sudo apache2ctl restart"
    # Esperar brevemente antes de verificar
    sleep 5

    # Verificar si el proceso de Apache está corriendo
    if pct exec $vmid -- bash -c "pgrep apache2 > /dev/null"; then
        msg_ok "Apache iniciado correctamente en LXC ID $vmid ($OS_IMAGE)"
    else
        msg_error "Error al iniciar Apache en LXC ID $vmid ($OS_IMAGE)"
        exit 1
    fi
}

# Instalación de LAMP según el sistema operativo
install_lamp() {
    msg_info "Instalando LAMP en LXC ID $VMID para $OS_IMAGE"

    if [[ "$OS_IMAGE" == "Ubuntu" || "$OS_IMAGE" == "Debian" ]]; then
        install_mariadb
        start_apache_debian "$VMID"
        pct exec $VMID -- bash -c "apt-get install -y php libapache2-mod-php php-mysql"
        
    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        pct exec $VMID -- bash -c "dnf update -y && dnf install -y httpd mariadb-server php php-mysqlnd"
        pct exec $VMID -- bash -c "service httpd start"
        pct exec $VMID -- bash -c "service mariadb start"
    fi

    # Verificar si Apache y MariaDB están corriendo
    check_service_status "$VMID" "apache2" || check_service_status "$VMID" "httpd"
    check_service_status "$VMID" "mysql" || check_service_status "$VMID" "mariadb"
}

# Instalación de LEMP según el sistema operativo
install_lemp() {
    msg_info "Instalando LEMP en LXC ID $VMID para $OS_IMAGE"

    if [[ "$OS_IMAGE" == "Ubuntu" || "$OS_IMAGE" == "Debian" ]]; then
        install_mariadb    
        pct exec $VMID -- bash -c " apt-get install -y nginx mariadb-server php-fpm php-mysql"
        pct exec $VMID -- bash -c "/etc/init.d/nginx start"

    elif [[ "$OS_IMAGE" == "Fedora" ]]; then
        pct exec $VMID -- bash -c "dnf update -y && dnf install -y nginx mariadb-server"
        pct exec $VMID -- bash -c "sudo dnf install -y php-cli php-fpm php-mysqlnd"
        pct exec $VMID -- bash -c "systemctl start nginx"
        pct exec $VMID -- bash -c "systemctl start mariadb"


    fi

    # Verificar si Nginx y MariaDB están corriendo
    check_service_status "$VMID" "nginx"
     check_service_status "$VMID" "mariadb"
}

# Verificación del estado del servicio
check_service_status() {
    local vmid=$1
    local service=$2

    msg_info "Verificando el estado del servicio $service en LXC ID $vmid..."
    pct exec $vmid -- systemctl is-active $service > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        msg_ok "El servicio $service está en ejecución."
    else
        msg_error "El servicio $service no se pudo iniciar correctamente."
        exit 1
    fi
}

# Función para seleccionar la instalación correcta según el sistema operativo y el servicio
select_software_installation() {
    case $SOFTWARE in
        "MariaDB")
        install_mariadb
        ;;
        "PostgreSQL")
        install_postgresql
        ;;
        "LAMP")
        install_lamp
        ;;
        "LEMP")
        install_lemp
        
        

        ;;
    esac
}

# Función para crear una VM personalizada
create_vm_custom() {
    local vmid=$1
    local name=$2
    local diskimage=$3
    local host_disk=$4
    local disk_size=$5  # Asegúrate de pasar solo el número, sin la unidad G
    local cores=$6
    local memory=$7

    # Validar parámetros de entrada
    if [[ -z "$vmid" || -z "$name" || -z "$diskimage" || -z "$host_disk" || -z "$disk_size" || -z "$cores" || -z "$memory" ]]; then
        clear
        msg_error "Faltan parámetros obligatorios para la creación de la VM personalizada."
        exit 1
    fi

    # Comprobar si la ISO existe
    if [[ ! -f "$diskimage" ]]; then
        msg_error "La ISO especificada no existe: $diskimage"
        exit 1
    fi

    msg_info "Creando Máquina Virtual personalizada ID $vmid con $cores cores, $memory MB de RAM y $disk_size GB de disco"

    # Crear la VM con los recursos especificados
    qm create $vmid --name $name --memory $memory --cores $cores --net0 virtio,bridge=vmbr0
    if [ $? -ne 0 ]; then
        msg_error "Error al crear la VM personalizada"
        exit 1
    fi
    msg_ok "Máquina Virtual personalizada ID $vmid creada"

    # Asignar la ISO personalizada
    msg_info "Asignando ISO a la VM $vmid"
    qm set $vmid --ide2 $diskimage,media=cdrom
    if [ $? -ne 0 ]; then
        msg_error "Error al asignar la ISO a la VM personalizada"
        exit 1
    fi
    msg_ok "ISO asignada correctamente a la VM personalizada ID $vmid"

    # Crear el disco virtual y configurarlo correctamente
    msg_info "Configurando disco y hardware para VM personalizada ID $vmid"
    qm set $vmid --scsi0 $host_disk:$disk_size --scsihw virtio-scsi-pci
    if [ $? -ne 0 ]; then
        msg_error "Error al configurar el disco para VM $vmid"
        exit 1
    fi

    # Configurar el dispositivo de arranque desde la ISO
    qm set $vmid --boot order=ide2 --bootdisk scsi0
    if [ $? -ne 0 ]; then
        msg_error "Error al configurar el dispositivo de arranque"
        exit 1
    fi
    msg_ok "Disco y hardware configurados para la VM personalizada ID $vmid"

    # Redimensionar disco si es necesario (solo si el tamaño inicial es menor)
    msg_info "Redimensionando disco a $disk_size GB para VM $vmid"
    qm resize $vmid scsi0 ${disk_size}G
    if [ $? -ne 0 ]; then
        msg_error "Error al redimensionar el disco"
        exit 1
    fi
    msg_ok "Disco redimensionado correctamente a $disk_size GB para VM $vmid"

    # Iniciar la VM
    msg_info "Iniciando VM ID $vmid"
    qm start $vmid
    if [ $? -ne 0 ]; then
        msg_error "Error al iniciar la VM personalizada"
        exit 1
    fi
    msg_ok "VM personalizada ID $vmid iniciada correctamente"
}


# Función para descargar la ISO personalizada si es necesario
download_iso_if_needed() {
    if [ "$OS_IMAGE" = "Cargar tu propia ISO" ]; then
        # Comprobar si se ha proporcionado una URL de ISO personalizada
        if [ -z "$ISO_URL" ]; then
            msg_error "No se ha proporcionado una URL para la ISO personalizada."
            exit 1
        fi

        # Validar el enlace con curl con un timeout y manejo de errores
        msg_info "Validando el enlace de la ISO..."

        HTTP_STATUS=$(curl --max-time 10 --connect-timeout 5 --retry 3 -o /dev/null --silent --head --write-out "%{http_code}" -L "$ISO_URL")

        if [ "$HTTP_STATUS" -ne 200 ]; then
            msg_error "El enlace proporcionado no es válido o el archivo no está disponible (HTTP $HTTP_STATUS)."
            exit 1
        fi


        msg_ok "El enlace de la ISO es válido (HTTP $HTTP_STATUS)."

        # Definir el directorio donde se guardarán las ISOs
        ISO_DIRECTORY="/var/lib/vz/template/iso"

        # Intentar obtener el nombre del archivo desde la URL
        CUSTOM_ISO=$(basename "$ISO_URL")  # Usar una variable temporal

        # Verificar si el nombre es genérico o inválido
        if echo "$CUSTOM_ISO" | grep -qE '^p/?LinkID' || [ -z "$CUSTOM_ISO" ]; then
            msg_info "No se puede obtener un nombre adecuado de la URL, intentando con el servidor..."

            # Intentar obtener el nombre del archivo desde el encabezado HTTP usando wget con --content-disposition
            wget --content-disposition --spider "$ISO_URL" 2>&1 | tee wget-log

            # Extraer el nombre del archivo desde los encabezados si es posible
            CUSTOM_ISO=$(grep -o -E '\/([^\/]+\.iso)' wget-log | head -1 | sed 's/\// /' | awk '{print $2}')

            # Si no se pudo obtener el nombre, pedir al usuario que ingrese un nombre manualmente
            if [ -z "$CUSTOM_ISO" ]; then
                msg_warning "No se pudo obtener el nombre de la ISO desde los encabezados ni la URL."
                
                # Solicitar al usuario que ingrese un nombre personalizado para la ISO
                CUSTOM_ISO=$(dialog --inputbox "No se pudo determinar el nombre de la ISO. Ingresa un nombre para la ISO (debe incluir .iso):" 8 60 2>&1 >/dev/tty)

                if [ $? -ne 0 ]; then
                    clear
                    msg_cancel "Operación cancelada por el usuario."
                    exit 1
                fi
                
                if [ -z "$CUSTOM_ISO" ]; then
                    msg_error "No se ha proporcionado un nombre válido para la ISO personalizada."
                    exit 1
                fi

                # Verificar si el usuario incluyó la extensión .iso; si no, añadirla automáticamente
                if ! echo "$CUSTOM_ISO" | grep -qE '\.iso$'; then
                    CUSTOM_ISO="${CUSTOM_ISO}.iso"
                    msg_info "El nombre ingresado no contenía la extensión .iso. Se añadió automáticamente."
                fi
            fi
        fi

        # Ruta completa del archivo
        FULL_PATH="$ISO_DIRECTORY/$CUSTOM_ISO"

        # Verificar si el archivo ISO ya existe
        if [ -f "$FULL_PATH" ]; then
            msg_info "La ISO ya existe en $FULL_PATH. No se descargará nuevamente."
        else
            msg_info "Descargando ISO personalizada desde $ISO_URL..."
            wget -O "$FULL_PATH" "$ISO_URL"
            if [ $? -ne 0 ]; then
                msg_error "Error al descargar la ISO personalizada desde el enlace proporcionado."
                exit 1
            fi
            msg_ok "ISO personalizada descargada exitosamente en $FULL_PATH."
        fi

        # Asignar la ISO personalizada a DISKIMAGE solo después de descargarla
        DISKIMAGE="$FULL_PATH"

    fi
}


# Función para actualizar `apt` una sola vez
apt_update_once() {
    if [[ "$OS_IMAGE" == "Debian" || "$OS_IMAGE" == "Ubuntu" ]]; then
        msg_info "Ejecutando apt-get update una vez al inicio"
        pct exec "$VMID" -- bash -c "apt-get update -y"
    fi
}


# Flujo principal del script
main() {
check_root
pve_check
dialog_check
default_settings
show_welcome
select_type

if [ "$TYPE" == "1" ]; then
    select_os_image_lxc
    select_software_lxc
    select_hardware
    select_disk_size_LXC
    input_credentials
    create_container "$VMID" "$DISKIMAGE" "$HOST_DISK" "$DISK_SIZE" "$CORES" "$MEMORY"
    wait_for_container "$VMID"
    if [[ "$OS_IMAGE" == "Debian" ]]; then
        update_debian_mirrors "$VMID"
    fi   # Asegurarse de que el contenedor esté corriendo
    apt_update_once  
    configure_locales "$VMID"
    
    create_user_in_container "$VMID" "$USERNAME" "$PASSWORD"
    select_software_installation

else
    select_os_image_vm
    
    if [ "$OS_IMAGE" == "Cargar tu propia ISO" ]; then
        select_hardware
        select_disk_size_LXC
        # Descargar la ISO si es una personalizada
        download_iso_if_needed
        echo "DISKIMAGE final: $DISKIMAGE"  # Verificar el valor

        create_vm_custom "$VMID" "$TEMPLATE_NAME" "$DISKIMAGE" "$HOST_DISK" "$DISK_SIZE" "$CORES" "$MEMORY"
    else
        select_software_vm
        select_hardware

        select_disk_size_VM
        input_credentials
        create_vm "$VMID" "$TEMPLATE_NAME" "$DISKIMAGE" "$HOST_DISK" "$DISK_SIZE" "$CORES" "$MEMORY"
        configure_cloud_init "$VMID" "$USERNAME" "$PASSWORD"
        wait_for_vm "$VMID"
    fi
fi
}
main
