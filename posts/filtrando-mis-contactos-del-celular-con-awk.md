<!--
.. title: Filtrando mis contactos del celular con AWK
.. slug: filtrando-mis-contactos-del-celular-con-awk
.. date: 2021-06-26 19:38:49 UTC-03:00
.. tags: awk,unix,android
.. category: 
.. link: 
.. description: 
.. type: text
.. previewimage: /images/og-awk.png
-->

Hace unas semanas cambié mi celular con Android. Una de las cosas que tuve que
hacer fue importar los contactos del celu viejo al nuevo. Como no uso soluciones
de almacenamiento en la nube por cuestiones de privacidad, la importación la
hice de forma manual, usando ficheros [vCard (con extensión .vcf)][vcf].

[vcf]: https://es.wikipedia.org/wiki/VCard

En su momento, cuando todavía usaba Android con los servicios de Google, a la
aplicación de Gmail se le ocurrió crear un contacto para cada usuario con quien
haya intercambiado algún correo electrónico. Esto me creó un montón de contactos
que no aportan nada en mi celular. Contactos a quienes les escribí por única
vez, sin intención de hacerlo nuevamente. De quienes solamente conozco su
dirección de correo electrónico y no su celular. 

Como estaba cambiando el celu, me pareció que sería una buena ocasión para
borrar todos estos contactos innecesarios. Para esto necesitaría:

* Exportar todos mis contactos del celular viejo a un [fichero .vcf][vcf]
* Encontrar o armar una herramienta que borre todos aquellos contactos que no
  tengan número de teléfono
* Grabar la salida en un nuevo fichero .vcf, listo para ser importado en el
  celular nuevo

Para escribir una herramienta que filtre contactos tendría que ser capaz de
parsear un fichero .vcf. Normalmente hubiese usado Python para resolver el
problema. Podría haber utilizado una [librería externa][python-vcard] y confiar
en que no tenga bugs ni vulnerabilidades. O podría haber creado mi propia
librería para manejo de .vcf/vCard, propiamente testeada y documentada. Sin
embargo, ambas opciones parecían demasiado complicadas para un programa que
pretendo correr una única vez. Tiene que haber una solución más simple.

[python-vcard]: https://gitlab.com/victor-engmark/vcard

Un fichero vcf tiene el siguiente formato:

```
BEGIN:VCARD
VERSION:2.1
N:Nombre;Apellido;;;
FN:Nombre Visible
TEL;CELL:123-456-789
END:VCARD
BEGIN:VCARD
VERSION:2.1
N:Otro;Contacto;;;
FN:Otro contacto de Gmail
EMAIL;PREF:usuario@gmail.com
END:VCARD
```

Como se ve, los detalles de cada contacto se encuentran entre las líneas
`BEGIN:VCARD` y `END:VCARD`. El formato en sí no parece nada complicado, ya que
es texto plano delimitado por líneas.

Teniendo en cuenta de que quería parsear un fichero en un formato simple y
hacerlo una única vez, me decidí por usar [AWK][awk] en vez del tradicional
Python. El lenguaje AWK es bastante chico y por esto se puede aprender en pocas
horas. Con leer [su página en Wikipedia][awk] ya se puede entender bastante su
funcionamiento.

[awk]: https://es.wikipedia.org/wiki/AWK

Después de repasar un poco, me armé un programa de awk corto pero efectivo:

```awk
# lineas va a guardar las líneas del contacto a procesar en un array.
# n es la longitud del array, que se incrementa en cada iteración.
{
    lineas[n++] = $0; # Esto sería similar a un append en Python
}

/^TEL;/ {
    # el contacto siendo procesado tiene un teléfono, así que quiero que se muestre
    tiene_telefono = 1
}

/^END:VCARD/ { # llegué al final del contacto, tengo que decidir si mostrarlo o no

    # si tenía un teléfono, mostrar todas las líneas que tengo guardadas
    if (tiene_telefono)
        for (i=0; i<n; i++)
            print lineas[i]

    # en la próxima iteración voy a arrancar con nuevo contacto, así que
    # reinicio el estado del programa.
    tiene_telefono = 0
    n = 0 # Esto simula varias el array
}
```

Después ejecuté el programa corriendo `awk -f miprograma.awk
<contactos-sin-filtrar.vcf >contactos-filtrados.vcf`. Eso me generó un nuevo
.vcf con los contactos ya filtrados, listo para importar en mi celular.

Con solamente 13 líneas de código (sin contar comentarios ni líneas vacías),
logré armar un programa que solucionó mi problema a la perfección. No me
compliqué instalando librerías externas, creando jerarquías de clases
inentendibles, ni haciendo parsers complejos de algún formato.

Así parece que con un lenguaje con más de 40 años de antigüedad me sentí más
cómodo que con Python, mi lenguaje de preferencia. Esto se debe a que AWK es un
lenuaje especializado en manejo de ficheros de texto y programas de un solo uso.
Quizás el código no sea tan mantenible, pero no me importa si se que no lo voy a
volver a correr. Necesitaba una solución rapida, y AWK cumplió a la perfección.

Espero con este post haber explicado la esencia del lenguaje AWK. Me parece que
es una herramienta fundamental para cualquier persona que se dedique a programar
o administrar sistemas UNIX-style. El lenguaje se puede aprender en pocas horas,
y es capaz de mejorar muchísimo nuestra productividad.

Algunos recursos que me sirvieron para aprender AWK (están en inglés):

* [Why Learn AWK](https://blog.jpalardy.com/posts/why-learn-awk/)
* Guía rapida de AWK,
  [parte 1](https://jemma.dev/blog/awk-part-1) y
  [parte 2](https://jemma.dev/blog/awk-part-2)
* ["An AWK love story"](https://www.youtube.com/watch?v=IfhMUed9RSE), charla que
  explica la escencia del lenguaje

También existe [un libro][libro] sobre el lenguaje escrito por sus autores. No
lo puedo recomendar porque todavía lo leí, pero en caso de que los recursos
anteriores te dejen con ganas de más, este libro seguro es el siguiente paso.

[libro]: https://www.goodreads.com/book/show/703101.The_AWK_Programming_Language

Saludos!
