using FluentValidation;
using KENZORF.Application.DTOs.Addresses;

namespace KENZORF.Application.Validators;

public sealed class AddressRequestValidator : AbstractValidator<AddressRequest>
{
    public AddressRequestValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("addresses.fullName.required")
            .MaximumLength(150).WithMessage("addresses.fullName.tooLong");

        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("addresses.phoneNumber.required")
            .MaximumLength(30).WithMessage("addresses.phoneNumber.tooLong");

        RuleFor(x => x.Line1)
            .NotEmpty().WithMessage("addresses.line1.required")
            .MaximumLength(250).WithMessage("addresses.line1.tooLong");

        RuleFor(x => x.City)
            .NotEmpty().WithMessage("addresses.city.required")
            .MaximumLength(120).WithMessage("addresses.city.tooLong");

        RuleFor(x => x.Country)
            .NotEmpty().WithMessage("addresses.country.required")
            .MaximumLength(120).WithMessage("addresses.country.tooLong");

        RuleFor(x => x.Label)
            .MaximumLength(60).WithMessage("addresses.label.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.Label));
    }
}
