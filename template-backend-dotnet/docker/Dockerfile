FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY Directory.Build.props Directory.Packages.props global.json ./
COPY src/**/*.csproj ./
RUN for f in *.csproj; do mkdir -p "src/${f%.csproj}" && mv "$f" "src/${f%.csproj}/"; done
RUN dotnet restore src/{{PROJECT_NAME}}.API/{{PROJECT_NAME}}.API.csproj

COPY src/ src/
RUN dotnet publish src/{{PROJECT_NAME}}.API/{{PROJECT_NAME}}.API.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app .
EXPOSE 5000
ENTRYPOINT ["dotnet", "{{PROJECT_NAME}}.API.dll"]
