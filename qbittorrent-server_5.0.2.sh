#!/bin/bash

# Criador : LUCIANO PEREIRA DE SOUZA
# Finalidade : Criar um servidor de torrents.
# Como instalar : bash qbittorrent-server.sh
# Como acesar : No navegador digite o IP do servidor e a porta
    # Exemplo : 192.168.0.10:8080
    # Login : admin
    # Senha : adminadmin

# Verifica se o usuário é o root.
usuario=$(whoami)
if [ $usuario != "root" ]; then
    echo -e "Usuário não é root\n    Tente sudo -i ou su - root."
    exit 1
fi

ping google.com -c4 > /dev/null 2>&1
[ $? -ne 0 ] && echo "Sem Internet ou DNS não configurado." && exit 2

echo -e "Instalando servidor de torrents...\n\n" ; sleep 2
# Instala o comando killall, caso não esteja instalado.
[ -f /usr/bin/killall ] || apt install psmisc -y > /dev/null 2>&1
[ -f /usr/bin/7z ] || apt install p7zip-full -y > /dev/null 2>&1


echo -e "Criando certificado..." && sleep 2
openssl req -x509 -nodes -newkey rsa:4096        \
        -keyout /etc/ssl/private/qbittorrent.key \
        -out /etc/ssl/private/qbittorrent.cert   \
        -subj "/CN=qBittorrent"
echo

set -x
servico="qbittorrent-nox.service"
caminho="/usr/bin/qbittorrent-nox"
arquivo_compactado=$(find / -type f -iregex ".*x86_64-qbittorrent-nox.7z" \
                     | xargs realpath)
arquivo="x86_64-qbittorrent-nox"

[ -d $caminho ] || mkdir -p $caminho

if [ -f $arquivo_compactado ]; then
    cp $arquivo_compactado $caminho
    7z x $caminho/$(basename $arquivo_compactado) -o$caminho > /dev/null 2>&1
    [ $? -ne 0 ] && echo "Erro ao descompactar!" && exit 3

    chmod +x $caminho/$(basename $arquivo_compactado .7z)
else
    echo "Arquivo $arquivo não existe!"
    exit 3
fi

set +x
# Criação do arquivo de serviço.
echo -e "\
[Unit]
Description=qbittorrent
After=network.target syslog.target
[Service]
Type=simple
ExecStart=$caminho/$arquivo
ExecStop=/usr/bin/killall $caminho/$arquivo
restart=on-failure
[Install]
WantedBy=multi-user.target\n" >> /lib/systemd/system/$servico


# Reinicia o daemon.
systemctl daemon-reload

# Habilita na inicialização do sistema.
systemctl enable $servico

# Inicia o serviço.
systemctl start $servico && sleep 3

# Para o serviço.
systemctl stop $servico


# Define a porta de acesso via web.
read -p "Defina a porta de serviço web : " porta

# Define a senha como adminadmin.
echo -e "\
[Preferences]
MailNotification\\\req_auth=true
Web\\\Port=$porta
WebUI\\\AuthSubnetWhitelist=@Invalid()
WebUI\\\HTTPS\\\CertificatePath=/etc/ssl/private/qbittorrent.cert
WebUI\\\HTTPS\\\Enabled=true
WebUI\\\HTTPS\\\KeyPath=/etc/ssl/private/qbittorrent.key
WebUI\\\Password_PBKDF2=\"@ByteArray(cjrkEmcVmY/rGCtkbKgKkA==:3EE66W4epajReEKx0/1O14miX2O0W+5x+1fs8DcDXyZPzZ7ZDqFKZFuJLxDoQYM9rf28MJQ/izfxr6nN7ArF8A==)\"
WebUI\\\Port=$porta\n" >> /.config/qBittorrent/qBittorrent.conf


# Inicia o serviço.
systemctl start $servico


# Mostra o status do serviço.
systemctl status $servico


#=== Como desinstalar ===#
# Pare o serviço -> systemctl start qbittorrent-nox.service
# Tire da inicialização -> systemctl disable qbittorrent-nox.service
# Remova o arquivo do daemon -> rm /lib/systemd/system/qbittorrent-nox.service
# Reinicia o daemon -> systemctl daemon-reload
