using Allegro.Application.Abstractions;

namespace Allegro.Api.Bootstrap;

/// <summary>
/// Comando de línea de comandos para asignar el rol admin al primer usuario
/// existente (por correo o UID). NO existe endpoint HTTP equivalente. Requiere
/// AUTH_MODE=firebase y credenciales de Firebase Admin. Es idempotente y solo
/// muestra información no sensible.
///
/// Uso:
///   dotnet run --project src/Allegro.Api -- bootstrap-admin --email correo@dominio.com
///   dotnet run --project src/Allegro.Api -- bootstrap-admin --uid &lt;firebase-uid&gt;
/// </summary>
public static class BootstrapAdminCommand
{
    public const string Name = "bootstrap-admin";

    public static async Task<int> RunAsync(IServiceProvider services, string[] args)
    {
        var (email, uid) = ParseArgs(args);
        if (email is null && uid is null)
        {
            Console.Error.WriteLine("Falta --email <correo> o --uid <uid>.");
            return 2;
        }

        using var scope = services.CreateScope();
        var firebase = scope.ServiceProvider.GetRequiredService<IFirebaseUserManagementService>();

        try
        {
            var user = uid is not null
                ? await firebase.GetByUidAsync(uid)
                : await firebase.GetByEmailAsync(email!);

            if (user is null)
            {
                Console.Error.WriteLine("No se encontró un usuario con esos datos. Debe existir antes de promoverlo.");
                return 3;
            }

            if (string.Equals(user.Role, "admin", StringComparison.OrdinalIgnoreCase))
            {
                Console.WriteLine($"Sin cambios: el usuario {Mask(user.Uid)} ya es admin.");
                return 0;
            }

            await firebase.SetRoleAsync(user.Uid, "admin");
            Console.WriteLine($"Listo: usuario {Mask(user.Uid)} promovido a admin (app_access=true).");
            return 0;
        }
        catch (Exception ex)
        {
            // Mensaje propio, sin volcar detalles del SDK.
            Console.Error.WriteLine($"No se pudo completar el bootstrap: {ex.Message}");
            return 1;
        }
    }

    private static (string? email, string? uid) ParseArgs(string[] args)
    {
        string? email = null, uid = null;
        for (var i = 0; i < args.Length - 1; i++)
        {
            if (args[i] == "--email") email = args[i + 1].Trim();
            else if (args[i] == "--uid") uid = args[i + 1].Trim();
        }
        return (string.IsNullOrWhiteSpace(email) ? null : email,
                string.IsNullOrWhiteSpace(uid) ? null : uid);
    }

    // Muestra solo un fragmento del UID (información no sensible).
    private static string Mask(string uid) =>
        uid.Length <= 6 ? uid : $"{uid[..6]}…";
}
