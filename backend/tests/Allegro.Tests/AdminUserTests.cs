using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Allegro.Domain;
using Allegro.Tests.Fakes;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class AdminUserTests
{
    private static (AdminUserService svc, FakeFirebaseUserManagementService fb, FakeAuditLogService audit) Build()
    {
        var fb = new FakeFirebaseUserManagementService();
        var audit = new FakeAuditLogService();
        var svc = new AdminUserService(fb, audit, new FakeCurrentUser());
        return (svc, fb, audit);
    }

    [Fact]
    public async Task Create_assigns_role_returns_link_and_audits()
    {
        var (svc, fb, audit) = Build();

        var result = await svc.CreateAsync(new CreateUserDto("Ana", "ana@demo.test", "operator"));

        result.User.Role.Should().Be("operator");
        result.ActivationLink.Should().NotBeNullOrWhiteSpace();
        fb.ResetLinksGenerated.Should().ContainSingle();
        audit.Entries.Should().ContainSingle(e => e.Action == AuditActions.UserCreated);
    }

    [Fact]
    public async Task Create_rejects_duplicate_email()
    {
        var (svc, fb, _) = Build();
        fb.Seed("Existente", "dup@demo.test", "operator");

        var act = async () => await svc.CreateAsync(new CreateUserDto("Otro", "dup@demo.test", "operator"));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*ya existe*");
    }

    [Fact]
    public async Task Create_rejects_invalid_role()
    {
        var (svc, _, _) = Build();

        var act = async () => await svc.CreateAsync(new CreateUserDto("Ana", "ana@demo.test", "superuser"));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*Rol inválido*");
    }

    [Fact]
    public async Task Cannot_demote_last_active_admin()
    {
        var (svc, fb, _) = Build();
        var admin = fb.Seed("Jefe", "jefe@demo.test", "admin");

        var act = async () => await svc.UpdateAsync(admin.Uid, new UpdateUserDto(null, "operator"));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*último administrador*");
    }

    [Fact]
    public async Task Can_demote_admin_when_another_admin_exists()
    {
        var (svc, fb, audit) = Build();
        var admin1 = fb.Seed("Jefe1", "j1@demo.test", "admin");
        fb.Seed("Jefe2", "j2@demo.test", "admin");

        var updated = await svc.UpdateAsync(admin1.Uid, new UpdateUserDto(null, "operator"));

        updated.Role.Should().Be("operator");
        audit.Entries.Should().Contain(e => e.Action == AuditActions.UserRoleChanged);
    }

    [Fact]
    public async Task Cannot_block_last_active_admin()
    {
        var (svc, fb, _) = Build();
        var admin = fb.Seed("Jefe", "jefe@demo.test", "admin");

        var act = async () => await svc.SetStatusAsync(admin.Uid, disabled: true);

        await act.Should().ThrowAsync<DomainException>().WithMessage("*último administrador*");
    }

    [Fact]
    public async Task Can_block_admin_when_another_admin_exists()
    {
        var (svc, fb, audit) = Build();
        var admin1 = fb.Seed("Jefe1", "j1@demo.test", "admin");
        fb.Seed("Jefe2", "j2@demo.test", "admin");

        var updated = await svc.SetStatusAsync(admin1.Uid, disabled: true);

        updated.Disabled.Should().BeTrue();
        audit.Entries.Should().Contain(e => e.Action == AuditActions.UserStatusChanged);
    }

    [Fact]
    public async Task Activation_link_does_not_leak_into_audit()
    {
        var (svc, fb, audit) = Build();
        var user = fb.Seed("Ana", "ana@demo.test", "operator");

        var result = await svc.GenerateActivationLinkAsync(user.Uid);

        result.ActivationLink.Should().NotBeNullOrWhiteSpace();
        audit.Entries.Should().ContainSingle(e => e.Action == AuditActions.UserActivationLink);
        audit.Entries.Should().NotContain(e => (e.Detail ?? "").Contains("http"));
    }

    [Fact]
    public async Task List_is_paginated()
    {
        var (svc, fb, _) = Build();
        for (var i = 0; i < 5; i++) fb.Seed($"U{i}", $"u{i}@demo.test", "operator");

        var page = await svc.ListAsync(null, null, pageSize: 2);

        page.Items.Should().HaveCount(2);
        page.NextPageToken.Should().NotBeNull();
    }

    [Fact]
    public async Task List_filters_by_query()
    {
        var (svc, fb, _) = Build();
        fb.Seed("Ana", "ana@demo.test", "operator");
        fb.Seed("Beto", "beto@demo.test", "operator");

        var page = await svc.ListAsync("beto", null, pageSize: 10);

        page.Items.Should().ContainSingle();
        page.Items[0].Email.Should().Be("beto@demo.test");
    }
}
