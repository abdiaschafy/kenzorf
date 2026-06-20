using FluentValidation;
using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Validators;

public sealed class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("auth.email.required")
            .EmailAddress().WithMessage("auth.email.invalid")
            .MaximumLength(256).WithMessage("auth.email.tooLong");

        // Aligné sur la politique Identity renforcée (≥ 8, majuscule, minuscule, chiffre, non-alphanumérique).
        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("auth.password.required")
            .MinimumLength(8).WithMessage("auth.password.tooShort")
            .MaximumLength(128).WithMessage("auth.password.tooLong")
            .Matches("[A-Z]").WithMessage("auth.password.requiresUppercase")
            .Matches("[a-z]").WithMessage("auth.password.requiresLowercase")
            .Matches("[0-9]").WithMessage("auth.password.requiresDigit")
            .Matches("[^a-zA-Z0-9]").WithMessage("auth.password.requiresNonAlphanumeric");

        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("auth.firstName.required")
            .MaximumLength(100).WithMessage("auth.firstName.tooLong");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("auth.lastName.required")
            .MaximumLength(100).WithMessage("auth.lastName.tooLong");

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(30).WithMessage("auth.phoneNumber.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));
    }
}
