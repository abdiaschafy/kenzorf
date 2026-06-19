# syntax=docker/dockerfile:1

# --- Build stage ---
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Restauration (cache des couches sur les .csproj).
COPY KENZORF.sln ./
COPY src/KENZORF.Domain/KENZORF.Domain.csproj src/KENZORF.Domain/
COPY src/KENZORF.Application/KENZORF.Application.csproj src/KENZORF.Application/
COPY src/KENZORF.Infrastructure/KENZORF.Infrastructure.csproj src/KENZORF.Infrastructure/
COPY src/KENZORF.Api/KENZORF.Api.csproj src/KENZORF.Api/
RUN dotnet restore KENZORF.sln

# Compilation + publication.
COPY . .
RUN dotnet publish src/KENZORF.Api/KENZORF.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

# --- Runtime stage ---
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

COPY --from=build /app/publish ./

# Dossier des uploads (images produits) servi via UseStaticFiles.
RUN mkdir -p /app/wwwroot/uploads

EXPOSE 8080
ENTRYPOINT ["dotnet", "KENZORF.Api.dll"]
