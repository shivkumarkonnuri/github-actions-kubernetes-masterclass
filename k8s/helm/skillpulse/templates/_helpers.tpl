{{/*
_helpers.tpl — reusable snippets for the skillpulse Helm chart
*/}}

{{/* Chart name */}}
{{- define "skillpulse.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Full release name */}}
{{- define "skillpulse.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels applied to every resource */}}
{{- define "skillpulse.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/name: {{ include "skillpulse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels — must be stable across upgrades */}}
{{- define "skillpulse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "skillpulse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
