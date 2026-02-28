# Guía de Administración: Licencias en Red de Autodesk

Como ahora tú llevarás el control, aquí tienes los conceptos clave para administrar el servidor sin complicaciones.

## 1. ¿Cómo se consumen las licencias?
Las licencias de red son **"Flotantes" (Concurrentes)**.
*   **Ejemplo:** Si tienes 10 licencias y 50 empleados, solo 10 pueden abrir el programa al mismo tiempo.
*   **Liberación:** En cuanto un empleado cierra el programa, la licencia regresa al servidor en segundos y queda disponible para alguien más.
*   **Equipo vs Usuario:** La licencia se amarra al **equipo**. Si un usuario abre AutoCAD y Revit en la misma PC, normalmente solo consume 1 licencia de la "Suite" (depende de tu contrato).

## 2. ¿Son para siempre o por tiempo?
*   **Suscripciones (Actual):** Tienen fecha de vencimiento. Cuando renuevas, debes generar un **nuevo archivo .lic** en el portal de Autodesk y reemplazar el viejo en la carpeta `/licence`.
*   **Perpetuas (Antiguas):** No vencen, pero si dejas de pagar el mantenimiento ("Maintenance Plan"), te quedas en la versión que compraste.

## 3. ¿Cómo se configura la PC del empleado?
No necesitas ir silla por silla si tienes un buen sistema, pero la configuración básica es:
1.  Al abrir el programa por primera vez, elegir: **"Network License"** o **"Multi-user"**.
2.  Introducir el nombre del servidor o su IP.
3.  **Tip Pro:** Si el software no encuentra el servidor, puedes crear una "Variable de Entorno" en Windows llamada `ADSKFLEX_LICENSE_FILE` con el valor `@IP_DEL_SERVIDOR`.

## 4. El "Panel de Control" (Comandos esenciales)
En el servidor Docker que montamos, no hay ventanas, todo es por "comandos". Aquí los 3 más importantes (ejecútalos desde la terminal de tu PC):

*   **Ver quién está usando qué:**
    `docker exec -it autodesk-licenser ./lmutil lmstat -a`
    *(Te dirá: "User1 has 1 license of AutoCAD checked out from PC-01")*

*   **Ver cuándo vence la licencia:**
    Revisa las líneas que dicen `SIGN=` o `EXPIRES=` en el comando anterior.

*   **Reiniciar el servidor si algo falla:**
    `docker-compose restart`

## 5. Préstamo de Licencias (Borrowing)
Si un ingeniero se va de viaje a una obra **sin internet**:
*   Dentro de AutoCAD, puede ir a *Help > About > Manage License > Borrow*.
*   La licencia se "extrae" del servidor y se queda en su laptop por hasta 6 meses (tú configuras el límite).
*   Durante ese tiempo, el servidor tiene 1 licencia menos disponible para los demás.

> [!TIP]
> **El mayor problema suele ser el Firewall.** Asegúrate de que los puertos **27000** y **2080** estén abiertos en el equipo donde corre Docker para que las otras PCs puedan "verlo".
