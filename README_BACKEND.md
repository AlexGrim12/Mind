# Mind Backend Blueprint

Este documento define como construir el backend para Mind con base en el comportamiento actual de las views iOS y watchOS.

## 1. Objetivo

Crear un backend seguro, auditable y escalable para:

- sincronizar datos clinicos y de bienestar entre dispositivos,
- habilitar portal de psicologo con consentimiento granular,
- preservar privacidad local-first (texto crudo del diario no se comparte),
- soportar flujos de riesgo (alertas, plan de seguridad, cuestionarios severos).

## 2. Alcance Analizado (sin modificar views)

Views iOS analizadas:

- Mind/Views/Onboarding/OnboardingView.swift
- Mind/Views/Home/HomeView.swift
- Mind/Views/MoodCheckin/MoodCheckinView.swift
- Mind/Views/Journal/JournalView.swift
- Mind/Views/Trends/TrendsView.swift
- Mind/Views/Questionnaire/QuestionnaireView.swift
- Mind/Views/SafetyPlan/SafetyPlanView.swift
- Mind/Views/Appointments/AppointmentsView.swift
- Mind/Views/SessionPrep/SessionPrepView.swift
- Mind/Views/Clinician/ClinicianView.swift
- Mind/Views/ClinicianDashboard/ClinicianDashboardView.swift
- Mind/Views/Sleep/SleepView.swift
- Mind/Views/Wellness/WellnessView.swift

Views watchOS analizadas:

- MindWatch Watch App/WatchHomeView.swift
- MindWatch Watch App/WatchMoodCheckinView.swift
- MindWatch Watch App/WatchBreathingView.swift
- MindWatch Watch App/WatchBiometricsView.swift
- MindWatch Watch App/ContentView.swift

Modelos y servicios considerados:

- Mind/Models/MoodEntry.swift
- Mind/Models/JournalEntry.swift
- Mind/Models/Appointment.swift
- Mind/Models/SafetyPlan.swift
- Mind/Services/WatchConnectivityService.swift
- Mind/Services/HealthKitService.swift
- Mind/Services/LLMService.swift
- MindWatch Watch App/WatchStore.swift
- MindWatch Watch App/WatchHealthService.swift

## 3. Principios de Diseno

- Privacy-first: el texto crudo del diario permanece local.
- Consentimiento granular: mood, cuestionarios, temas, biometrias, sueno.
- RBAC estricto: paciente y psicologo con permisos separados.
- Local-first + sync eventual: la app debe funcionar offline.
- Idempotencia en escrituras: evitar duplicados (especialmente Watch).
- Trazabilidad completa: auditoria de accesos y cambios de consentimiento.

## 4. Entidades Backend Minimas

### 4.1 Core

- User
  - id, role (patient|clinician|admin), name, email, timezone, status.

- ClinicianRelationship
  - id, patientId, clinicianId, status (active|pending|revoked), linkedAt, revokedAt.

- ConsentBundle
  - id, patientId,
  - sharesMood,
  - sharesQuestionnaires,
  - sharesTopics,
  - sharesBiometrics,
  - sharesSleep,
  - termsVersion,
  - updatedAt.

### 4.2 Salud Mental

- MoodEntry
  - id, patientId, date, score (0-10), energy (0-1), context, company, activity, source.

- JournalShare
  - id, patientId, date, prompt, sharedTopics[], isSharedWithClinician.
  - Nota: `body` y `aiSummary` se pueden mantener local-only por politica.

- QuestionnaireResponse
  - id, patientId, type (PHQ-9|GAD-7), answers[], score, severity, createdAt.

- SafetyPlan
  - id, patientId, warningSignals[], copingStrategies[], distractingContacts[], supportContacts[], professionals[], crisisLines[], reasonsToLive[], version, updatedAt.

### 4.3 Citas y Seguimiento

- Appointment
  - id, patientId, clinicianId, date, duration (express|full), isRemote, videoUrl, notes, status.

- SessionRating
  - id, appointmentId, relationship, goals, approach, overall, average, createdAt.

### 4.4 Bienestar

- BiometricSnapshot
  - id, patientId, date,
  - heartRate, hrv, oxygenSaturation, respiratoryRate,
  - bodyTemperature, wristTemperature,
  - steps, activeCalories, basalCalories, exerciseMinutes, standMinutes, distanceMeters, flightsClimbed,
  - vo2Max, noiseEnvironment, noiseHeadphones, mindfulMinutes.

- SleepSummary
  - id, patientId, date, totalHours, quality, bedtime, wakeTime, stages.

- WellnessScoreDaily
  - id, patientId, date, total, componentScores, label, insight.

## 5. Flujos Funcionales que el Backend Debe Cubrir

### 5.1 Onboarding + Consentimientos

1. Usuario termina Onboarding.
2. Se guarda bundle inicial de consentimientos.
3. Se habilita uso normal de app.

### 5.2 Mood Check-in (iPhone + Watch)

1. Usuario envia score y contexto (iPhone) o score rapido (Watch).
2. Se persiste localmente.
3. Se sincroniza por API con idempotency key.

### 5.3 Diario + Temas Compartibles

1. Usuario escribe entrada en local.
2. LLM on-device genera resumen/temas.
3. Si `sharesTopics=true`, backend recibe solo temas anonimizados.

### 5.4 Cuestionarios Clinicos

1. Usuario completa PHQ-9/GAD-7.
2. Backend valida score y severidad.
3. Si score severo, dispara alerta de riesgo.

### 5.5 Plan de Seguridad

1. Usuario crea/edita SafetyPlan.
2. Backend versiona y audita.
3. Acceso de psicologo solo con consentimiento.

### 5.6 Citas + Session Prep + Session Rating

1. Backend gestiona citas upcoming/past.
2. Session prep consume resumen de tendencia.
3. Post-cita se guarda SRS (4 preguntas).

### 5.7 Portal del Psicologo

1. Lista de pacientes filtrable por riesgo.
2. Vista detalle con agregados compartidos.
3. Nunca exponer texto crudo del diario.

## 6. API REST Recomendada (v1)

Base path: `/api/v1`

### 6.1 Auth

- POST `/auth/register`
- POST `/auth/login`
- POST `/auth/refresh`
- POST `/auth/logout`

### 6.2 Onboarding y Consent

- POST `/onboarding`
- GET `/consent`
- PUT `/consent`
- GET `/consent/audit`
- POST `/consent/clinician-link`
- POST `/consent/clinician-revoke`

### 6.3 Mood

- POST `/moods`
- POST `/moods/batch`
- GET `/moods?from=&to=&cursor=`
- DELETE `/moods/{id}`

Payload minimo POST /moods:

```json
{
  "score": 7,
  "energy": 0.6,
  "context": "home",
  "company": "alone",
  "activity": "resting",
  "source": "iPhone",
  "capturedAt": "2026-04-20T18:30:00Z",
  "timezone": "America/Mexico_City"
}
```

Headers recomendados:

- `Authorization: Bearer <token>`
- `Idempotency-Key: <uuid>`

### 6.4 Journal Compartible

- POST `/journal/shares`
- GET `/journal/shares?from=&to=`
- DELETE `/journal/shares/{id}`

Payload minimo POST /journal/shares:

```json
{
  "prompt": "Como te afecto la escuela hoy?",
  "sharedTopics": ["presion academica", "sueno"],
  "isSharedWithClinician": true,
  "capturedAt": "2026-04-20T19:10:00Z"
}
```

### 6.5 Cuestionarios

- POST `/questionnaires`
- GET `/questionnaires?type=&from=&to=`
- GET `/questionnaires/latest?type=PHQ-9`

Payload minimo POST /questionnaires:

```json
{
  "type": "PHQ-9",
  "answers": [0, 1, 2, 1, 0, 2, 1, 0, 1],
  "score": 8,
  "capturedAt": "2026-04-20T19:30:00Z"
}
```

### 6.6 Safety Plan

- POST `/safety-plans`
- GET `/safety-plans/current`
- PUT `/safety-plans/current`
- GET `/safety-plans/current/access-log`

### 6.7 Appointments

- POST `/appointments`
- GET `/appointments?status=upcoming|past`
- GET `/appointments/{id}`
- PUT `/appointments/{id}`
- DELETE `/appointments/{id}`
- POST `/appointments/{id}/prepare`
- POST `/appointments/{id}/rating`

### 6.8 Biometrics, Sleep, Wellness

- POST `/biometrics/snapshots`
- POST `/biometrics/snapshots/batch`
- GET `/biometrics/snapshots?from=&to=`
- POST `/sleep/summaries`
- GET `/sleep/summaries?from=&to=`
- GET `/wellness/daily?date=`
- GET `/wellness/history?from=&to=&groupBy=day|week`

### 6.9 Clinician Portal

- GET `/clinician/dashboard`
- GET `/clinician/patients?risk=high|medium|low&cursor=`
- GET `/clinician/patients/{patientId}`
- POST `/clinician/patients/{patientId}/alert`
- POST `/clinician/patients/{patientId}/contact`

## 7. Eventos Async y Jobs

### 7.1 Eventos en cola (pub/sub)

- `mood.created`
- `questionnaire.submitted`
- `questionnaire.high_risk_detected`
- `safety_plan.updated`
- `consent.changed`
- `appointment.upcoming_24h`
- `session.rating.created`
- `biometric.anomaly_detected`

### 7.2 Jobs programados

- Resumen semanal paciente (mood + sueno + wellness).
- Resumen semanal psicologo (solo pacientes con consentimiento activo).
- Deteccion de riesgo cada 12h.
- Recordatorios de cita (24h y 2h antes).
- Limpieza/retencion de datos segun politica.

## 8. Seguridad, Privacidad y Compliance

Minimo obligatorio:

- JWT + refresh tokens.
- Cifrado TLS en transito y cifrado en reposo para datos sensibles.
- Auditoria inmutable de:
  - cambios de consentimientos,
  - accesos de psicologo,
  - lecturas de plan de seguridad.
- RBAC por rol y ownership checks por paciente.
- PII minimization: no guardar texto crudo del diario en backend.
- Idempotencia en POST de Watch y reintentos offline.

Recomendado:

- Secret manager para llaves de cifrado.
- Data retention policy con borrado verificable.
- Export de datos y delete account flow.

## 9. Arquitectura Recomendada

Opcion sugerida:

- API: NestJS + TypeScript
- ORM: Prisma
- DB: PostgreSQL
- Cache/colas: Redis + BullMQ
- Observabilidad: OpenTelemetry + Prometheus + Grafana
- API docs: OpenAPI/Swagger

Arquitectura logica:

- BFF/API layer
- Domain modules
  - auth
  - consent
  - moods
  - journal-share
  - questionnaires
  - safety-plan
  - appointments
  - biometrics
  - clinician
- Infra
  - postgres
  - redis
  - queue workers
  - audit log store

## 10. Estructura de Proyecto Backend (propuesta)

```txt
backend/
  src/
    app.module.ts
    main.ts
    common/
      auth/
      guards/
      interceptors/
      dto/
      errors/
    modules/
      auth/
      users/
      consent/
      moods/
      journal-share/
      questionnaires/
      safety-plan/
      appointments/
      biometrics/
      sleep/
      wellness/
      clinician/
      watch-sync/
      notifications/
      audit/
    jobs/
      weekly-summary.job.ts
      risk-escalation.job.ts
      appointment-reminder.job.ts
  prisma/
    schema.prisma
    migrations/
  test/
    e2e/
    integration/
  docker-compose.yml
  .env.example
  README.md
```

## 11. Plan de Implementacion por Fases

### Fase 1 (base)

- Auth, users, consent.
- Mood endpoints + sync idempotente.
- Questionnaire endpoints + severidad.
- OpenAPI + tests basicos.

### Fase 2 (clinico)

- Clinician relationship.
- Clinician dashboard APIs.
- Appointment CRUD + session rating.
- Auditoria de accesos.

### Fase 3 (salud avanzada)

- Biometric snapshots y sleep summaries.
- Wellness score diario/historico.
- Deteccion de anomalias + eventos.

### Fase 4 (operacion)

- Jobs semanales.
- Notificaciones y alertas.
- Hardening de seguridad y compliance.

## 12. Criterios de Hecho (Definition of Done)

- Todas las rutas v1 con OpenAPI publicada.
- Cobertura de tests de integracion >= 80% en modulos core.
- Idempotencia validada en POST /moods y /biometrics.
- RBAC validado en endpoints clinician.
- Auditoria visible para consent y safety plan.
- p95 de GET principales < 250ms con datos de prueba.

## 13. Notas de Integracion con la App Actual

- Mantener modo local-first de SwiftData.
- Sincronizar en background cuando haya conectividad.
- Respetar toggles de `AppStorage` como fuente de verdad de consentimiento local, pero reconciliar con backend en cada login.
- En caso de conflicto de consentimientos, aplicar politica:
  - server wins si cambio remoto es mas reciente,
  - cliente muestra aviso de reconciliacion.

## 14. Siguientes Pasos Inmediatos

1. Crear `backend/` con NestJS + Prisma.
2. Definir esquema Prisma para entidades core.
3. Implementar modulo `consent` y `moods` primero.
4. Generar OpenAPI y contrato compartido para iOS/watch.
5. Agregar worker de riesgo para cuestionarios severos.

---

Si quieres, en el siguiente paso te genero el `schema.prisma` inicial y la lista exacta de DTOs por endpoint para arrancar implementacion.
