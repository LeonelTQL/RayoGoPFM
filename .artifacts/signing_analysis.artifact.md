# Análisis de Error de Firma (SHA1 Mismatch)

El error ocurre porque estás intentando subir un App Bundle firmado con una clave diferente a la que Google Play espera.

## ¿Por qué sucede?
En tu archivo `android/app/build.gradle.kts`, el proceso de construcción busca un archivo llamado `key.properties`. Como ese archivo no existe en tu PC actual (Linux), Gradle está usando la **clave de depuración (debug key)** por defecto para firmar el App Bundle de "release".

- **Huella digital esperada (Play Console):** `44:30:9B:A2:25:CF:6F:EA:2E:2F:02:67:33:A8:C7:12:0D:EF:A0:A8` (Tu clave de producción original).
- **Huella digital detectada (Local):** `E3:B8:2C:83:AF:13:C5:5A:E0:1B:51:00:36:AB:5C:EC:F5:FD:ED:63` (La clave debug de tu Linux).

## Soluciones posibles

### Opción 1: Recuperar la clave original (Recomendado)
Si aún tienes acceso a la PC Windows o a un respaldo:
1. Busca el archivo del almacén de llaves (termina en `.jks` o `.keystore`).
2. Busca el archivo `android/key.properties`.
3. Cópialos a la misma ubicación en tu PC Linux.

### Opción 2: Solicitar un restablecimiento de la clave de carga
Si perdiste la clave original y tienes habilitada la "Firma de apps de Google Play":
1. Ve a la Google Play Console.
2. Selecciona tu app -> **Configuración** -> **Integridad de la app**.
3. En la pestaña **Firma de apps**, busca la opción para solicitar un restablecimiento de la clave de carga.
4. Google te pedirá generar una nueva clave (ver pasos abajo) y subir el certificado `.pem`.

---

## Cómo generar una nueva clave (si eliges la Opción 2)

Si decides empezar de cero con una nueva clave en Linux, ejecuta este comando en tu terminal:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Luego, crea el archivo `android/key.properties` con este contenido:

```properties
storePassword=tu_password
keyPassword=tu_password
keyAlias=upload
storeFile=/home/grimroot/upload-keystore.jks
```

> [!CAUTION]
> **No borres nunca este nuevo archivo `.jks`**. Si lo pierdes, no podrás actualizar la app sin volver a pedir un reset a Google.
