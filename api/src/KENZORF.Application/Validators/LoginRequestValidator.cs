using FluentValidation;
using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Validators;

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("auth.email.required")
            .EmailAddress().WithMessage("auth.email.invalid");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("auth.password.required");
    }
}
