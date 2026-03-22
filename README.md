# Autodesk License Server Dockerized (ad-lic-hp)

> [!IMPORTANT]
> **PROYECTO ACTUALIZADO Y MIGRADO:** Este repositorio ha evolucionado hacia una implementación **altamente optimizada basada en Wine**, diseñada para despliegues modernos en la nube (VPS) y paneles como Easypanel.

---

## 🎯 Acceso a la Versión Definitiva: [`wine-ad-manager/`](./wine-ad-manager/)

Se recomienda utilizar la solución ubicada en la subcarpeta `wine-ad-manager`, la cual ha logrado los siguientes hitos técnicos:

### 🏆 Logros del Laboratorio
- **Eficiencia Extrema:** El servidor de licencias ahora consume solo **~250MB de RAM** (una reducción masiva frente a los 1.5GB iniciales de una VM o contenedor pesado).
- **Identidad Fija (HostID):** Sincronización automática de MAC Address vía `NET_ADMIN` para validación de licencias de Autodesk.
- **Red Headless:** Uso de monitor virtual Xvfb minimizado (**1x1 píxel**) para ahorro máximo de recursos del servidor.
- **Despliegue Multi-puerto:** Mapeo de puertos Master (27000) y Vendor (2080) expuestos al mundo exterior.
- **Dashboard Web:** Panel de monitoreo Flask integrado para ver licencias en uso en tiempo real.

---

## 📂 Archivo Histórico (Raíz)
Este repositorio mantiene en su raíz la configuración basada en **Rocky Linux 9 (AMD64)** para compatibilidad con instalaciones locales que utilicen binarios RPM nativos de Linux.

### Guías del Archivo:
- [Guía de Administración Antigua](guia_administracion.md)
- [Walkthrough de Despliegue Antiguo](walkthrough.md)

---
*Este proyecto demuestra cómo modernizar infraestructuras de licencias "Legacy" mediante técnicas avanzadas de Dockerización y emulación ligera.*
