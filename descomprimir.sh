#!/bin/bash
# A sample Bash script, by Ryan
echo Hello World!
# comando para descomprimir los archivos
7z x '*.7z'
# enviar los archivos en terminacion .csv al archivo data y borrar 
mv '*.csv' ./data
# eliminar los archivos con terminacion .7z en el directorio actual
rm '*.7z'

