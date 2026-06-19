using FluentValidation;
using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Validators;

public sealed class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("auth.refreshToken.required");
    }
}
