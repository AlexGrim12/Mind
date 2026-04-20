# Mind Backend Blueprint (Node.js/Express/MongoDB)

Este documento define la arquitectura y fases de desarrollo para el backend de **MIND-LINK**, soportando tanto la app del estudiante (iOS/watchOS) como el portal clínico dual para psicólogos.

## 1. Objetivo

Crear un backend en Node.js (Express) con MongoDB que sea seguro, auditable y escalable para:
- Autenticar estudiantes y psicólogos (Login Dual).
- Sincronizar datos clínicos y de bienestar (local-first en app, sync eventual).
- Habilitar un portal de psicólogo con consentimiento granular y dashboard de pacientes.
- Preservar privacidad (texto crudo del diario no se comparte, solo temas anonimizados).
- Procesar flujos de riesgo (alertas automáticas de crisis, cuestionarios severos).

## 2. Stack Tecnológico

- **Runtime:** Node.js
- **Framework:** Express.js
- **Base de Datos:** MongoDB (usando Mongoose ODM)
- **Autenticación:** JWT (JSON Web Tokens) con roles y refresh tokens.
- **Validación:** Zod o Joi.
- **Tareas Programadas:** node-cron o BullMQ/Redis (para resúmenes y alertas periódicas).

## 3. Principios de Diseño

- **Privacy-first:** El texto crudo del diario y resúmenes AI permanecen 100% on-device (Apple Intelligence/LLM local).
- **Consentimiento Granular:** Estudiantes deciden qué módulos compartir (ánimo, cuestionarios, temas, biometrías).
- **RBAC Estricto (Role-Based Access Control):** `patient` vs `clinician`. Un psicólogo solo ve a sus pacientes enlazados.
- **Identidad Unificada:** Login unificado usando Matrícula (estudiante) o Cédula (psicólogo).
- **Motor de Alertas Activo:** El backend debe evaluar tendencias de bajo ánimo o altos puntajes en PHQ-9/GAD-7 para marcar pacientes como `En Crisis` o `Atención`.

## 4. Modelos de Datos (Mongoose Schemas)

### 4.1 Identidad y Relación
- **User**
  - `identifier` (String, unique): Matrícula o Cédula.
  - `passwordHash` (String)
  - `role` (Enum: `patient`, `clinician`, `admin`)
  - `profile` (Object: name, email, timezone, status)
  - `createdAt`, `updatedAt`

- **ClinicianPatientLink** (El "Consentimiento")
  - `patientId` (ObjectId ref User)
  - `clinicianId` (ObjectId ref User)
  - `status` (Enum: `active`, `pending`, `revoked`)
  - `permissions`: { `sharesMood`, `sharesQuestionnaires`, `sharesTopics`, `sharesBiometrics` }
  - `linkedAt`, `revokedAt`

### 4.2 Salud Mental (Paciente)
- **MoodEntry**
  - `patientId` (ObjectId)
  - `date` (Date)
  - `score` (Number: 0-10)
  - `energy` (Number: 0-1)
  - `context`, `company`, `activity` (Strings)
  - `source` (String: `iPhone`, `Watch`)

- **JournalShare** (Solo se suben temas, no el cuerpo del diario)
  - `patientId` (ObjectId)
  - `date` (Date)
  - `sharedTopics` ([String])
  - `isSharedWithClinician` (Boolean)

- **QuestionnaireResponse**
  - `patientId` (ObjectId)
  - `type` (Enum: `PHQ-9`, `GAD-7`)
  - `answers` ([Number])
  - `score` (Number)
  - `severity` (Enum: `minimal`, `mild`, `moderate`, `severe`)
  - `createdAt`

### 4.3 Citas y Seguimiento
- **Appointment**
  - `patientId`, `clinicianId` (ObjectIds)
  - `date` (Date)
  - `durationMinutes` (Number)
  - `status` (Enum: `upcoming`, `completed`, `cancelled`)
  - `notes` (String)

## 5. Endpoints REST Recomendados (Express v1)

Base path: `/api/v1`

### 5.1 Autenticación (Pública)
- `POST /auth/login` - Acepta `identifier` (matrícula/cédula) y `password`. Retorna JWT y role.
- `POST /auth/register` (Opcional/Admin)
- `POST /auth/refresh`

### 5.2 Estudiante (Paciente)
*Requiere JWT Role: `patient`*
- `GET /patient/profile`
- `PUT /patient/consent` (Actualizar permisos para su psicólogo)
- `POST /patient/moods` - Subir 1 o más entradas de estado de ánimo (idempotente).
- `POST /patient/journal-shares` - Subir temas extraídos por IA local.
- `POST /patient/questionnaires` - Subir PHQ-9 o GAD-7.
- `GET /patient/appointments` - Citas próximas.

### 5.3 Portal Clínico (Psicólogo)
*Requiere JWT Role: `clinician`*
- `GET /clinician/dashboard/summary` - Devuelve conteos: Activos, Alertas, Sesiones hoy.
- `GET /clinician/patients` - Lista de pacientes (`name`, `matricula`, `status` [Estable, Atención, Crisis], `moodTrend` últimos 7 días).
- `GET /clinician/patients/:patientId/detail` - Perfil detallado (Tendencia 30 días, últimos PHQ-9/GAD-7, temas anonimizados recientes).
- `GET /clinician/appointments?date=YYYY-MM-DD` - Agenda del día para el calendario.

## 6. Lógica de Negocio y Eventos (Risk Engine)

El sistema debe reaccionar cuando un estudiante registra datos:
- **Detección de Crisis:** Si un `MoodEntry` tiene score <= 3 durante 3 días seguidos, o un `QuestionnaireResponse` (PHQ-9) da >= 15, el backend debe marcar al usuario con un flag temporal de `status: 'crisis'` o generar una alerta visible en `GET /clinician/dashboard/summary`.
- **Idempotencia:** Especialmente en `/patient/moods` subidos desde el Apple Watch, ignorar duplicados basados en `date` y `patientId`.

## 7. Plan de Implementación por Fases

### Fase 1: Identidad Dual y Estructura Base
- Setup Express + Mongoose + JWT.
- Modelos `User` y `ClinicianPatientLink`.
- Endpoints de Auth (`/login`, `/refresh`).
- Middleware de roles (`requirePatient`, `requireClinician`).

### Fase 2: Recolección de Datos del Estudiante
- Modelos `MoodEntry`, `QuestionnaireResponse`, `JournalShare`.
- Endpoints `/patient/...` para recibir datos de la app iOS/Watch.
- Lógica de cálculo de severidad básica.

### Fase 3: Portal Clínico
- Motor de cálculo de tendencias (`moodTrend`) en Mongoose Aggregations.
- Endpoints `/clinician/dashboard/summary` y `/clinician/patients`.
- Vista detallada del paciente con gráficos (agregando los temas anonimizados).

### Fase 4: Agenda y Alertas
- Modelo `Appointment`.
- Endpoints de calendario para el doctor.
- Tareas programadas o Mongoose Hooks para calcular alertas prioritarias en tiempo real.

## 8. Criterios de Hecho
- Postman Collection funcional.
- Cobertura de tests (Jest/Supertest) > 80% en Auth y Risk Engine.
- Integración probada con `LoginView` y `DoctorDashboardView` en el cliente Swift.