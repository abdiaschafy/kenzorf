using FluentValidation;
using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Validators;

public sealed class AdminProductRequestValidator : AbstractValidator<AdminProductRequest>
{
    public AdminProductRequestValidator(IValidator<VariantRequest> variantValidator)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("products.name.required")
            .MaximumLength(200).WithMessage("products.name.tooLong");

        RuleFor(x => x.Description)
            .NotEmpty().WithMessage("products.description.required");

        RuleFor(x => x.ShortDescription)
            .MaximumLength(400).WithMessage("products.shortDescription.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.ShortDescription));

        RuleFor(x => x.CategoryId)
            .NotEmpty().WithMessage("products.categoryId.required");

        RuleFor(x => x.BasePrice)
            .GreaterThanOrEqualTo(0).WithMessage("products.basePrice.min");

        RuleFor(x => x.CompareAtPrice)
            .GreaterThan(x => x.BasePrice).WithMessage("products.compareAtPrice.mustExceedBase")
            .When(x => x.CompareAtPrice.HasValue);

        RuleFor(x => x.Slug)
            .MaximumLength(220).WithMessage("products.slug.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.Slug));

        RuleForEach(x => x.Variants).SetValidator(variantValidator);
    }
}
