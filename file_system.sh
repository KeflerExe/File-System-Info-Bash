#!/bin/bash

##### Constantes
TITLE="Información de los dispositivos montados de mayor peso para $HOSTNAME"
RIGHT_NOW=$(date +"%x %r%Z")
TIME_STAMP="Información actualizada el $RIGHT_NOW por $USER"
opcion_m_activacion=0
invertir_salida=
devicefiles_activacion=0
opcion_u_activacion=0
columna_opcion_m="Total_Usado_Dispositivos"
lista_usuario=
copia_opcion_u=0
ordena_numero_dispositivos=
ordena_numero_archivos=
dependencia_entre_condiciones=0
quita_el_encabezado=0

##### Estilos
TEXT_BOLD=$(tput bold)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_ULINE=$(tput sgr 0 1)

##### Funciones

### Función usage para proporcionar ayuda a el usuario en caso de que introduzca el usuario cuando introduzca el parámetro -h
usage() {
    echo "$TEXT_ULINE"Este programa proporciona información sobre los distintos sistemas de archivos del sistema"$TEXT_RESET"
    echo
    echo "Uso: ./PR1_SSOO.sh [-h] [-m] [-inv] [-devicefiles] [-u] [-sopen] [-sdevice] [-noheader]"
    echo "Siendo las opciones: "
    echo "-h: muestra este mensaje de ayuda con el fin de comprender el uso del programa."
    echo "-m: elimina la columa Total_Usado_Dispositivos."
    echo "-inv: ordena de forma inversa."
    echo "-devicefiles: muestra la tabla considerando solo los dispositivos representados como archivos y el número total de archivos."
    echo "-u: filtra los archivos abiertos por los usuarios que se encuentran en la lista de usuarios."
    echo "-sopen: la ordenación se hará por el número de archivos abiertos.(solo podrá ser usada con las opciones -devicefiles o -u y no podrá usarse simultáneamente con -sdevice)."
    echo "-sdevice: la ordenación se realizará por el número total de dispositivos.(no podrá usarse junto a -sopen)."
    echo "-noheader: elimina el encabezado de la tabla."
}

### Función principal que obtiene la información de los sistemas de archivo del sistema
tipo_sistema_archivos() {
    local lista_tipos=$(mount | tr -s " " ":" | cut -d ":" -f "5" | sort -u)
    local dispositivo_mayor=$(while read -r linea; do
        if df -t "$linea" 2> /dev/null > /dev/null; then
            if [ "$devicefiles_activacion" -eq 1 ] || [ "$copia_opcion_u" -eq 1 ]; then
                if [ -b "$(df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "1")" ]; then
                    df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "1,3,5,6" | sort -r -t " " -k2,2 | head -n 1 | numfmt --field=2 --from-unit=1024 | numfmt --field=2 --to=iec | tr "\n" " "
                    df -t $linea | tail -n +2 | wc -l | tr "\n" " "
                    if [ "$opcion_m_activacion" -eq 0 ]; then
                        df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "3"  | paste -sd+ | bc | numfmt --from-unit=1024 | numfmt --to=iec | tr "\n" " "
                    fi
                    local sist_ficheros=$(df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "1")
                    if stat -c %t,%T "$sist_ficheros" 2> /dev/null > /dev/null; then
                        stat -c %t,%T $sist_ficheros | tr "\n" " "  
                    fi
                    if [ "$copia_opcion_u" -eq 1 ]; then
                        lsof $sist_ficheros | tr -s " " | cut -d " " -f "3" | grep -c -w "$lista_usuario"
                    else
                        lsof $sist_ficheros | wc -l
                    fi
                fi
            else
                df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "1,3,5,6" | sort -r -t " " -k2,2 | head -n 1 | numfmt --field=2 --from-unit=1024 | numfmt --field=2 --to=iec | tr "\n" " "
                df -t $linea | tail -n +2 | wc -l | tr "\n" " "
                if [ "$opcion_m_activacion" -eq 0 ]; then
                    df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "3"  | paste -sd+ | bc | numfmt --from-unit=1024 | numfmt --to=iec | tr "\n" " "
                fi
                local sist_ficheros=$(df -t $linea | tail -n +2 | tr -s " " | cut -d " " -f "1")
                if stat -c %t,%T "$sist_ficheros" 2> /dev/null > /dev/null; then
                    stat -c %t,%T $sist_ficheros
                else
                    echo "*,*"       
                fi
            fi
        fi
    done <<< "$lista_tipos")
    echo
    if [ "$devicefiles_activacion" -eq 1 ] || [ "$copia_opcion_u" -eq 1 ]; then
        if [ "$quita_el_encabezado" -eq 1 ];then
            echo "$dispositivo_mayor" | sort $ordena_numero_dispositivos $ordena_numero_archivos $invertir_salida | column -t
        else
            { echo "$dispositivo_mayor" | sort $ordena_numero_dispositivos $ordena_numero_archivos $invertir_salida & echo $TEXT_BOLD"Tipos Usado Porcentaje% Montado_en Total_Dispositivos $columna_opcion_m Driver_e_identificador Total_archivos_abiertos"$TEXT_RESET; } | column -t
        fi
    else
        if [ "$quita_el_encabezado" -eq 1 ];then
            echo "$dispositivo_mayor" | sort $ordena_numero_dispositivos $invertir_salida | column -t
        else
            { echo "$dispositivo_mayor" | sort $ordena_numero_dispositivos $invertir_salida & echo $TEXT_BOLD"Tipos Usado Porcentaje% Montado_en Total_Dispositivos $columna_opcion_m Driver_e_identificador"$TEXT_RESET; } | column -t
        fi
    fi
}

### Función que comprueba que no se usan condiciones con restricciones entre ellas 
comprueba_dependencias_entre_condiciones() {
    if [ -n "$ordena_numero_archivos" ]; then
        if [ "$devicefiles_activacion" -eq 0 ] && [ "$copia_opcion_u" -eq 0 ]; then
            dependencia_entre_condiciones=1
        fi
    fi
    if [ -n "$ordena_numero_dispositivos" ]; then
        if [ -n "$ordena_numero_archivos" ]; then
            dependencia_entre_condiciones=1
        fi
    fi
    if [ -n "$ordena_numero_archivos" ]; then
        if [ -n "$ordena_numero_dispositivos" ]; then
            dependencia_entre_condiciones=1
        fi
    fi
}

while [ "$1" != "" ]; do
   case $1 in
        -h | --help )
            usage
            exit
        ;;
        -m )
            opcion_m_activacion=1
            columna_opcion_m=
            opcion_u_activacion=0
        ;;
        -inv )
            invertir_salida="-r"
            opcion_u_activacion=0
        ;;
        -devicefiles )
            devicefiles_activacion=1
            opcion_u_activacion=0
        ;;
        -u )
            opcion_u_activacion=1
        ;;
        -sopen )
            ordena_numero_archivos="-k8 -n"
            opcion_u_activacion=0
        ;;
        -sdevice )
            ordena_numero_dispositivos="-k5 -n"
            opcion_u_activacion=0
        ;;
        -noheader )
            quita_el_encabezado=1
            opcion_u_activacion=0
        ;;
        * )
            if [ "$opcion_u_activacion" -ne 1 ]; then
                echo "Error"
            else
                lista_usuario="$lista_usuario\|$1"
                copia_opcion_u=1
            fi
   esac
   shift
done

##### Programa principal
cat << _EOF_
$TEXT_BOLD$TEXT_ULINE$TITLE$TEXT_RESET
$TEXT_GREEN$TIME_STAMP$TEXT_RESET
_EOF_

comprueba_dependencias_entre_condiciones
if [ "$dependencia_entre_condiciones" -eq 1 ]; then
    echo "Error crítico: existe un error a la hora de usar las opciones del programa. Consulte ./PR1_SSOO -h para más información."
    exit
fi
tipo_sistema_archivos