using FluentValidation;
using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Validators;

public sealed class LogoutRequestValidator : AbstractValidator<LogoutRequest>
{
    public LogoutRequestValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("auth.refreshToken.required");
    }
}
