{{/*
Expand the name of the chart.
*/}}
{{- define "pvc-migration.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "pvc-migration.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pvc-migration.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for migration resources
*/}}
{{- define "pvc-migration.labels" -}}
helm.sh/chart: {{ include "pvc-migration.chart" . }}
app.kubernetes.io/name: {{ include "pvc-migration.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Job name for a migration (must be unique per migration).
Usage: include "pvc-migration.jobName" (list $ .migration)
*/}}
{{- define "pvc-migration.jobName" -}}
{{- $root := index . 0 -}}
{{- $migration := index . 1 -}}
{{- printf "%s-%s-%s" (include "pvc-migration.fullname" $root) $migration.sourcePvc $migration.destPvc | trunc 63 | trimSuffix "-" -}}
{{- end }}
