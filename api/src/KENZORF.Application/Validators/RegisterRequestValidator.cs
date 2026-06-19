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

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("auth.password.required")
            .MinimumLength(8).WithMessage("auth.password.tooShort")
            .MaximumLength(128).WithMessage("auth.password.tooLong");

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
