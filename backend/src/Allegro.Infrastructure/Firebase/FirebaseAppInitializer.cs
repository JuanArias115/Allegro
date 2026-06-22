using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

namespace Allegro.Infrastructure.Firebase;

/// <summary>
/// Inicializa el <see cref="FirebaseApp"/> por defecto una sola vez. Las
/// credenciales se obtienen vía Application Default Credentials (ADC) o la ruta
/// indicada en <c>GOOGLE_APPLICATION_CREDENTIALS</c>. NUNCA se incrustan en el código.
/// </summary>
public static class FirebaseAppInitializer
{
    private static readonly object Gate = new();

    public static void EnsureInitialized(string? projectId)
    {
        if (FirebaseApp.DefaultInstance is not null) return;

        lock (Gate)
        {
            if (FirebaseApp.DefaultInstance is not null) return;

            FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.GetApplicationDefault(),
                ProjectId = string.IsNullOrWhiteSpace(projectId) ? null : projectId,
            });
        }
    }
}
