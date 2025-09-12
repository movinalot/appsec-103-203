Content-Type: multipart/mixed; boundary="===============VM=="
MIME-Version: 1.0

--===============VM==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
    set admintimeout 480
    set hostname "${fgt_vm_name}"
end
config router static
    edit 1
        set gateway 10.1.1.1
        set device "port1"
    next
end
config system probe-response
    set http-probe-value OK
    set mode http-probe
end
config system interface
    edit port1
        set mode static
        set ip 10.1.1.6 255.255.255.0
        set allowaccess ping https ssh http
        set type physical
        set alias "Public"
    next
    edit port2
        set mode static
        set ip 10.1.2.254 255.255.255.0
        set allowaccess ping https ssh http
        set type physical
        set alias "Proxy"
    next
end
config firewall vip
    edit "Juiceshop"
        set extip 10.1.1.100
        set mappedip "10.1.2.100"
        set extintf "any"
    next
    edit "DVWA"
        set extip 10.1.1.101
        set mappedip "10.1.2.101"
        set extintf "any"
    next
end
config firewall service custom
    edit "AAG-HTTPS-9443"
        set color 2
        set tcp-portrange 9443
    next
end
config firewall policy
    edit 1
        set name "Juiceshop"
        set srcintf "port1" "port2"
        set dstintf "port2" "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "Juiceshop"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set nat enable
    next
    edit 2
        set name "DVWA"
        set srcintf "port1" "port2"
        set dstintf "port2" "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "DVWA"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set nat enable
    next
    edit 3
        set name "AAG-9443"
        set srcintf "port1" "port2"
        set dstintf "port2" "port1"
        set action accept
        set srcaddr "all"
        set dstaddr "Juiceshop"
        set schedule "always"
        set service "AAG-HTTPS-9443"
        set logtraffic all
        set nat enable
    next
end
%{ if fgt_ssh_public_key != "" }
config system admin
    edit "${fgt_username}"
        set ssh-public-key1 "${trimspace(file(fgt_ssh_public_key))}"
    next
end
%{ endif }

%{ if fgt_license_fortiflex != "" }
--===============VM==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

LICENSE-TOKEN:${fgt_license_fortiflex}

%{ endif } %{ if fgt_license_file != "" }
--===============VM==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fgt_license_file}"

${file(fgt_license_file)}

%{ endif }
--===============VM==--