
# NOTES:
#   Base Image:  https://hub.docker.com/_/microsoft-powershell
#   Application: https://github.com/traefik/traefik/releases/
#
#   Use the PowerShell version of NanoServer to make installation easier/dynamic.
#   Put the app in a subdirectory to avoid security errors during installation.
#   Copy the NetAPI32.dll from Windows Server core so Traefik works (32bit? why? It used to work without this.)

ARG BASE_IMAGE
ARG NETAPI_TAG

FROM mcr.microsoft.com/windows/servercore:${NETAPI_TAG} as netapi_source

FROM ${BASE_IMAGE}

ARG APP_VERSION=v2.7.2

COPY --from=netapi_source ["/Windows/System32/netapi32.dll", "/Windows/System32"]

SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Write-Host "Application Version: $($env:APP_VERSION)"; \
    New-Item \
        -ItemType directory \
        -Path "/traefik"; \
    Invoke-WebRequest \
        -Uri "https://github.com/traefik/traefik/releases/download/$($env:APP_VERSION)/traefik_$($env:APP_VERSION)_windows_amd64.zip" \
        -OutFile "/traefik/traefik.zip"; \
    Expand-Archive \
        -Path "/traefik/traefik.zip" \
        -DestinationPath "/traefik/" \
        -Force; \
    Remove-Item \
        -Path "/traefik/traefik.zip" \
        -Force;

EXPOSE 80
ENTRYPOINT [ "/traefik/traefik.exe", "--configfile", "/traefik/conf/traefik.toml" ]

LABEL org.opencontainers.image.title="Traefik" \
      org.opencontainers.image.description="A modern reverse-proxy." \
      org.opencontainers.image.documentation="https://traefik.io/traefik/" \
      org.opencontainers.image.base.name="mcr.microsoft.com/powershell:nanoserver-1809" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.url="https://hub.docker.com/r/seabopo/traefik" \
      org.opencontainers.image.vendor="seabopo" \
      org.opencontainers.image.authors="seabopo @ Azure Devops / GitHub"
