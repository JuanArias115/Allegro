namespace Allegro.Api.Auth;

/// <summary>Roles soportados. La autorización SIEMPRE se valida en el backend.</summary>
public static class Roles
{
    public const string Admin = "admin";
    public const string Operator = "operator";
}

/// <summary>Nombres de las políticas de autorización.</summary>
public static class Policies
{
    /// <summary>Acceso a la aplicación. Según configuración exige el claim app_access.</summary>
    public const string AppAccess = "AppAccess";

    /// <summary>Solo administradores (gestión de usuarios, configuración, reportes).</summary>
    public const string Admin = "Admin";

    /// <summary>Operadores o administradores (operación diaria).</summary>
    public const string Operator = "Operator";
}

/// <summary>Nombres de claims usados en los tokens de Firebase / desarrollo.</summary>
public static class AppClaims
{
    public const string Role = "role";
    public const string AppAccess = "app_access";
}
