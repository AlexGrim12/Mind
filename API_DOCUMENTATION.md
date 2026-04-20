# 📘 Documentación de la API: MIND-LINK

Esta documentación detalla los endpoints disponibles en la versión `v1` del backend.

**Base URL:** `https://satirical-illusion-unquote.ngrok-free.dev/api/v1`

---

## 🔐 1. Autenticación (Pública)

### `POST /auth/register`
Registra un nuevo usuario (Paciente o Clínico).
- **Body:**
  ```json
  {
    "identifier": "MAT12345", // Matrícula o Cédula
    "password": "mi_password_seguro",
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "role": "patient" // o "clinician"
  }
  ```
- **Response (201):**
  ```json
  {
    "_id": "...",
    "identifier": "MAT12345",
    "role": "patient",
    "token": "JWT_TOKEN_HERE"
  }
  ```

### `POST /auth/login`
Inicia sesión y obtiene un token de acceso.
- **Body:**
  ```json
  {
    "identifier": "MAT12345",
    "password": "mi_password_seguro"
  }
  ```
- **Response (200):** Devuelve el perfil del usuario y el token JWT.

---

## 🏥 2. Endpoints del Paciente
*Requiere Header: `Authorization: Bearer <token>` y Rol: `patient`*

### `POST /patient/moods`
Sincroniza estados de ánimo. Acepta un objeto único o un arreglo para sincronización masiva.
- **Body:**
  ```json
  [
    {
      "date": "2024-04-20T10:00:00Z",
      "score": 8,
      "energy": 0.7,
      "context": "Escuela",
      "source": "Watch"
    }
  ]
  ```
- **Response (201):** Resumen de éxitos y fallos.

### `POST /patient/journal-shares`
Comparte temas extraídos del diario (IA Local).
- **Body:**
  ```json
  {
    "date": "2024-04-20T10:00:00Z",
    "sharedTopics": ["ansiedad", "exámenes", "sueño"]
  }
  ```

### `POST /patient/questionnaires`
Registra resultados de PHQ-9 o GAD-7.
- **Body:**
  ```json
  {
    "type": "PHQ-9",
    "answers": [1, 2, 0, 1, 3, 2, 1, 0, 1],
    "score": 11,
    "severity": "moderate"
  }
  ```

### `GET /patient/appointments`
Lista las próximas citas confirmadas del paciente.

---

## 🩺 3. Endpoints del Clínico
*Requiere Header: `Authorization: Bearer <token>` y Rol: `clinician`*

### `GET /clinician/dashboard/summary`
Resumen de métricas clave.
- **Response (200):**
  ```json
  {
    "activePatients": 15,
    "alerts": 2, // Pacientes en status 'attention' o 'crisis'
    "sessionsToday": 3
  }
  ```

### `GET /clinician/patients`
Lista de pacientes vinculados con su tendencia de ánimo de los últimos 7 días.

### `GET /clinician/patients/:id/detail`
Perfil profundo de un paciente específico (Historial de 30 días y últimos cuestionarios).

### `GET /clinician/appointments?date=YYYY-MM-DD`
Obtiene la agenda del clínico. El parámetro `date` es opcional.

### `POST /clinician/appointments`
Agenda una nueva cita para un paciente.
- **Body:**
  ```json
  {
    "patientId": "ID_DEL_PACIENTE",
    "date": "2024-04-22T15:00:00Z",
    "durationMinutes": 60,
    "notes": "Sesión de seguimiento"
  }
  ```

---

## 🛠️ Errores Comunes
- **401 Unauthorized:** Token faltante o inválido.
- **403 Forbidden:** El usuario no tiene el rol necesario (ej. un paciente intentando ver el dashboard clínico).
- **400 Bad Request:** Fallo en la validación de Zod (revisar el campo `errors` en la respuesta).
