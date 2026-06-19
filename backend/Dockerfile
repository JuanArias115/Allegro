# ----- build -----
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /src

# Restore (capa cacheable): copiamos solo los .csproj de la cadena de la API.
COPY src/Allegro.Domain/Allegro.Domain.csproj src/Allegro.Domain/
COPY src/Allegro.Application/Allegro.Application.csproj src/Allegro.Application/
COPY src/Allegro.Infrastructure/Allegro.Infrastructure.csproj src/Allegro.Infrastructure/
COPY src/Allegro.Api/Allegro.Api.csproj src/Allegro.Api/
RUN dotnet restore src/Allegro.Api/Allegro.Api.csproj

COPY src/ src/
RUN dotnet publish src/Allegro.Api/Allegro.Api.csproj -c Release -o /app --no-restore

# ----- runtime -----
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

# tzdata: zona horaria del negocio. icu-libs: formato/cultura no invariante.
RUN apk add --no-cache tzdata icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV ASPNETCORE_URLS=http://+:8080

COPY --from=build /app ./
EXPOSE 8080
ENTRYPOINT ["dotnet", "Allegro.Api.dll"]
