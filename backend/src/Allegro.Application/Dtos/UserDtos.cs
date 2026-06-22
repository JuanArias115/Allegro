namespace Allegro.Application.Dtos;

/// <summary>Usuario administrado (proyección propia, NUNCA el objeto del SDK de Firebase).</summary>
public record AdminUserDto(
    string Uid,
    string? Name,
    string? Email,
    string Provider,
    string? Role,
    bool Disabled,
    DateTime? CreatedAtUtc,
    DateTime? LastLoginAtUtc);

/// <summary>Página de usuarios (paginación basada en token de Firebase).</summary>
public record UserPageDto(
    IReadOnlyList<AdminUserDto> Items,
    string? NextPageToken);

public record CreateUserDto(string Name, string Email, string Role);

/// <summary>Resultado de crear un usuario: incluye el enlace de activación (mostrar una sola vez).</summary>
public record CreateUserResultDto(AdminUserDto User, string ActivationLink);

public record UpdateUserDto(string? Name, string? Role);

public record ChangeUserStatusDto(bool Disabled);

public record ActivationLinkDto(string ActivationLink);
